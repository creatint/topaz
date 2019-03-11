// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/dart_runner/dart_runner.h"

#include <errno.h>
#include <lib/async/default.h>
#include <lib/async-loop/loop.h>
#include <sys/stat.h>
#include <trace/event.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>
#include <thread>
#include <utility>

#include "lib/fxl/arraysize.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/tonic/dart_microtask_queue.h"
#include "third_party/tonic/dart_state.h"
#include "topaz/runtime/dart/utils/vmservice_object.h"
#include "topaz/runtime/dart_runner/dart_component_controller.h"
#include "topaz/runtime/dart_runner/service_isolate.h"

#if defined(AOT_RUNTIME)
extern "C" uint8_t _kDartVmSnapshotData[];
extern "C" uint8_t _kDartVmSnapshotInstructions[];
#endif

namespace dart_runner {
namespace {

const char* kDartVMArgs[] = {
    // clang-format off
    // TODO(FL-117): Re-enable causal async stack traces when this issue is
    // addressed.
    "--no_causal_async_stacks",

    "--systrace_timeline",
    "--timeline_streams=Compiler,Dart,Debugger,Embedder,GC,Isolate,VM",

#if defined(AOT_RUNTIME)
    "--precompilation",
#else
    "--enable_mirrors=false",

    // The interpreter is enabled unconditionally. If an app is built for
    // debugging (that is, with no bytecode), the VM will fall back on ASTs.
    "--enable_interpreter",

    // TODO(FL-208): Remove when field guards work.
    "--no_use_field_guards",
#endif

#if !defined(NDEBUG) && !defined(DART_PRODUCT)
    "--enable_asserts",
#endif  // !defined(NDEBUG)
    // clang-format on
};

Dart_Isolate IsolateCreateCallback(const char* uri, const char* main,
                                   const char* package_root,
                                   const char* package_config,
                                   Dart_IsolateFlags* flags,
                                   void* callback_data, char** error) {
  if (std::string(uri) == DART_VM_SERVICE_ISOLATE_NAME) {
#if defined(DART_PRODUCT)
    *error = strdup("The service isolate is not implemented in product mode");
    return NULL;
#else
    return CreateServiceIsolate(uri, flags, error);
#endif
  }

  *error = strdup("Isolate spawning is not implemented in dart_runner");
  return NULL;
}

void IsolateShutdownCallback(void* callback_data) {
  // The service isolate (and maybe later the kernel isolate) doesn't have an
  // async loop.
  auto dispatcher = async_get_default_dispatcher();
  auto loop = async_loop_from_dispatcher(dispatcher);
  if (loop) {
    tonic::DartMicrotaskQueue::GetForCurrentThread()->Destroy();
    async_loop_quit(loop);
  }
}

void IsolateCleanupCallback(void* callback_data) {
  delete static_cast<std::shared_ptr<tonic::DartState>*>(callback_data);
}

void RunApplication(
    DartRunner* runner, fuchsia::sys::Package package,
    fuchsia::sys::StartupInfo startup_info,
    std::shared_ptr<component::Services> runner_incoming_services,
    ::fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  int64_t start = Dart_TimelineGetMicros();
  DartComponentController app(std::move(package),
                              std::move(startup_info), runner_incoming_services,
                              std::move(controller));
  bool success = app.Setup();
  int64_t end = Dart_TimelineGetMicros();
  Dart_TimelineEvent("DartComponentController::Setup", start, end,
                     Dart_Timeline_Event_Duration, 0, NULL, NULL);
  if (success) {
    app.Run();
  }

  if (Dart_CurrentIsolate()) {
    Dart_ShutdownIsolate();
  }
}

bool EntropySource(uint8_t* buffer, intptr_t count) {
  zx_cprng_draw(buffer, count);
  return true;
}

}  // namespace

DartRunner::DartRunner()
    : context_(component::StartupContext::CreateFromStartupInfo()) {
  context_->outgoing().AddPublicService<fuchsia::sys::Runner>(
      [this](fidl::InterfaceRequest<fuchsia::sys::Runner> request) {
        bindings_.AddBinding(this, std::move(request));
      });

#if !defined(DART_PRODUCT)
  // The VM service isolate uses the process-wide namespace. It writes the
  // vm service protocol port under /tmp. The VMServiceObject exposes that
  // port number to The Hub.
  context_->outgoing().debug_dir()->AddEntry(
      fuchsia::dart::VMServiceObject::kPortDirName,
      fbl::AdoptRef(new fuchsia::dart::VMServiceObject()));

#endif  // !defined(DART_PRODUCT)

  dart::bin::BootstrapDartIo();

  char* error = Dart_SetVMFlags(arraysize(kDartVMArgs), kDartVMArgs);
  if (error) {
    FXL_LOG(FATAL) << "Dart_SetVMFlags failed: " << error;
  }

  Dart_InitializeParams params = {};
  params.version = DART_INITIALIZE_PARAMS_CURRENT_VERSION;
#if defined(AOT_RUNTIME)
  params.vm_snapshot_data = ::_kDartVmSnapshotData;
  params.vm_snapshot_instructions = ::_kDartVmSnapshotInstructions;
#else
  if (!MappedResource::LoadFromNamespace(
          nullptr, "pkg/data/vm_snapshot_data.bin", vm_snapshot_data_)) {
    FXL_LOG(FATAL) << "Failed to load vm snapshot data";
  }
  if (!MappedResource::LoadFromNamespace(
          nullptr, "pkg/data/vm_snapshot_instructions.bin",
          vm_snapshot_instructions_, true /* executable */)) {
    FXL_LOG(FATAL) << "Failed to load vm snapshot instructions";
  }
  params.vm_snapshot_data = vm_snapshot_data_.address();
  params.vm_snapshot_instructions = vm_snapshot_instructions_.address();
#endif
  params.create = IsolateCreateCallback;
  params.shutdown = IsolateShutdownCallback;
  params.cleanup = IsolateCleanupCallback;
  params.entropy_source = EntropySource;
#if !defined(DART_PRODUCT)
  params.get_service_assets = GetVMServiceAssetsArchiveCallback;
#endif
  error = Dart_Initialize(&params);
  if (error)
    FXL_LOG(FATAL) << "Dart_Initialize failed: " << error;
}

DartRunner::~DartRunner() {
  char* error = Dart_Cleanup();
  if (error)
    FXL_LOG(FATAL) << "Dart_Cleanup failed: " << error;
}

void DartRunner::StartComponent(
    fuchsia::sys::Package package, fuchsia::sys::StartupInfo startup_info,
    ::fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  TRACE_DURATION("dart", "StartComponent", "url", package.resolved_url);
  std::thread thread(RunApplication, this,
                     std::move(package), std::move(startup_info),
                     context_->incoming_services(), std::move(controller));
  thread.detach();
}

}  // namespace dart_runner
