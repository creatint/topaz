// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_
#define TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_

#include <fuchsia/sys/cpp/fidl.h>

#include "lib/component/cpp/connect.h"
#include "lib/component/cpp/startup_context.h"
#include "lib/fidl/cpp/binding.h"
#include "lib/fxl/macros.h"
#include "topaz/runtime/dart_runner/mapped_resource.h"

namespace dart_runner {

class DartRunner : public fuchsia::sys::Runner {
 public:
  explicit DartRunner();
  ~DartRunner() override;

 private:
  // |fuchsia::sys::Runner| implementation:
  void StartComponent(
      fuchsia::sys::Package package, fuchsia::sys::StartupInfo startup_info,
      ::fidl::InterfaceRequest<fuchsia::sys::ComponentController> controller)
      override;

  std::unique_ptr<component::StartupContext> context_;
  fidl::BindingSet<fuchsia::sys::Runner> bindings_;

#if !defined(AOT_RUNTIME)
  MappedResource vm_snapshot_data_;
  MappedResource vm_snapshot_instructions_;
#endif

  FXL_DISALLOW_COPY_AND_ASSIGN(DartRunner);
};

}  // namespace dart_runner

#endif  // TOPAZ_RUNTIME_DART_RUNNER_DART_RUNNER_H_
