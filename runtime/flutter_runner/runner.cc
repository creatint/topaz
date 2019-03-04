// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runner.h"

#include <zircon/status.h>
#include <zircon/types.h>

#include <sstream>
#include <utility>

#include "flutter/fml/make_copyable.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "fuchsia_font_manager.h"
#include "lib/fsl/vmo/file.h"
#include "lib/fsl/vmo/sized_vmo.h"
#include "third_party/flutter/runtime/dart_vm.h"
#include "third_party/icu/source/common/unicode/udata.h"
#include "third_party/skia/include/core/SkGraphics.h"
#include "topaz/runtime/dart/utils/vmservice_object.h"

namespace flutter {

namespace {

static constexpr char kIcuDataPath[] = "/pkg/data/icudtl.dat";

// Map the memory into the process and return a pointer to the memory.
// |size_out| is required and is set with the size of the mapped memory
// region.
uintptr_t GetICUData(const fsl::SizedVmo& icu_data, size_t* size_out) {
  if (!size_out)
    return 0u;
  uint64_t data_size = icu_data.size();
  if (data_size > std::numeric_limits<size_t>::max())
    return 0u;

  uintptr_t data = 0u;
  zx_status_t status = zx::vmar::root_self()->map(
      0, icu_data.vmo(), 0, static_cast<size_t>(data_size),
      ZX_VM_PERM_READ, &data);
  if (status == ZX_OK) {
    *size_out = static_cast<size_t>(data_size);
    return data;
  }

  return 0u;
}

// Return value indicates if initialization was successful.
bool InitializeICU() {
  const char* data_path = kIcuDataPath;

  fsl::SizedVmo icu_data;
  if (!fsl::VmoFromFilename(data_path, &icu_data)) {
    return false;
  }

  size_t data_size = 0;
  uintptr_t data = GetICUData(icu_data, &data_size);
  if (!data) {
    return false;
  }

  // Pass the data to ICU.
  UErrorCode err = U_ZERO_ERROR;
  udata_setCommonData(reinterpret_cast<const char*>(data), &err);
  return err == U_ZERO_ERROR;
}

}  // namespace

static void SetProcessName() {
  std::stringstream stream;
#if defined(DART_PRODUCT)
  stream << "io.flutter.product_runner.";
#else
  stream << "io.flutter.runner.";
#endif
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    stream << "aot";
  } else {
    stream << "jit";
  }
  const auto name = stream.str();
  zx::process::self()->set_property(ZX_PROP_NAME, name.c_str(), name.size());
}

static void SetThreadName(const std::string& thread_name) {
  zx::thread::self()->set_property(ZX_PROP_NAME, thread_name.c_str(),
                                   thread_name.size());
}

Runner::Runner(async::Loop* loop)
    : loop_(loop),
      host_context_(component::StartupContext::CreateFromStartupInfo()) {
#if !defined(DART_PRODUCT)
  // The VM service isolate uses the process-wide namespace. It writes the
  // vm service protocol port under /tmp. The VMServiceObject exposes that
  // port number to The Hub.
  host_context_->outgoing().debug_dir()->AddEntry(
      fuchsia::dart::VMServiceObject::kPortDirName,
      fbl::AdoptRef(new fuchsia::dart::VMServiceObject()));
#endif  // !defined(DART_PRODUCT)

  SkGraphics::Init();

  SetupICU();

  SetProcessName();

  SetThreadName("io.flutter.runner.main");

  host_context_->outgoing()
      .deprecated_services()
      ->AddService<fuchsia::sys::Runner>(
          std::bind(&Runner::RegisterApplication, this, std::placeholders::_1));
}

Runner::~Runner() {
  host_context_->outgoing()
      .deprecated_services()
      ->RemoveService<fuchsia::sys::Runner>();
}

void Runner::RegisterApplication(
    fidl::InterfaceRequest<fuchsia::sys::Runner> request) {
  active_applications_bindings_.AddBinding(this, std::move(request));
}

void Runner::StartComponent(
    fuchsia::sys::Package package, fuchsia::sys::StartupInfo startup_info,
    fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller) {
  TRACE_DURATION("flutter", "StartComponent", "url", package.resolved_url);
  // Notes on application termination: Application typically terminate on the
  // thread on which they were created. This usually means the thread was
  // specifically created to host the application. But we want to ensure that
  // access to the active applications collection is made on the same thread. So
  // we capture the runner in the termination callback. There is no risk of
  // there being multiple application runner instance in the process at the same
  // time. So it is safe to use the raw pointer.
  Application::TerminationCallback termination_callback =
      [task_runner = loop_->dispatcher(),                              //
       application_runner = this                                       //
  ](const Application* application) {
        async::PostTask(task_runner, [application_runner, application]() {
          application_runner->OnApplicationTerminate(application);
        });
      };

  auto loop_application_pair = Application::Create(
      std::move(termination_callback),     // termination callback
      std::move(package),                  // application pacakge
      std::move(startup_info),             // startup info
      host_context_->incoming_services(),  // runner incoming services
      std::move(controller)                // controller request
  );

  auto key = loop_application_pair.second.get();

  active_applications_[key] = std::move(loop_application_pair);
}

void Runner::OnApplicationTerminate(const Application* application) {
  auto app = active_applications_.find(application);
  if (app == active_applications_.end()) {
    FML_LOG(INFO)
        << "The remote end of the application runner tried to terminate an "
           "application that has already been terminated, possibly because we "
           "initiated the termination";
    return;
  }
  auto& active_application = app->second;

  // Grab the items out of the entry because we will have to rethread the
  // destruction.
  auto application_to_destroy = std::move(active_application.application);
  auto application_loop = std::move(active_application.loop);

  // Delegate the entry.
  active_applications_.erase(application);

  // Post the task to destroy the application and quit its message loop.
  async::PostTask(application_loop->dispatcher(), fml::MakeCopyable(
      [instance = std::move(application_to_destroy),
       loop = &application_loop]() mutable {
        instance.reset();
        (*loop)->Quit();
      }));

  // This works because just posted the quit task on the hosted thread.
  application_loop->JoinThreads();
}

void Runner::SetupICU() {
  if (!InitializeICU()) {
    FML_LOG(ERROR) << "Could not initialize ICU data.";
  }
}

}  // namespace flutter
