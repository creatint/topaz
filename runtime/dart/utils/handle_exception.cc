// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "handle_exception.h"

#include <string>

#include <fuchsia/crash/cpp/fidl.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/fxl/logging.h>
#include <lib/zx/vmo.h>
#include <sys/types.h>
#include <third_party/tonic/converter/dart_converter.h>
#include <zircon/errors.h>
#include <zircon/status.h>

namespace {
static bool FillBuffer(const std::string& data, fuchsia::mem::Buffer* buffer) {
  uint64_t num_bytes = data.size();
  zx::vmo vmo;

  if (zx::vmo::create(num_bytes, 0u, &vmo) < 0) {
    return false;
  }

  if (num_bytes > 0) {
    if (vmo.write(data.data(), 0, num_bytes) < 0) {
      return false;
    }
  }

  buffer->vmo = std::move(vmo);
  buffer->size = num_bytes;

  return true;
}
}  // namespace

namespace fuchsia {
namespace dart {

zx_status_t HandleIfException(std::shared_ptr<::sys::ServiceDirectory> services,
                              const std::string& component_url,
                              Dart_Handle result) {
  if (!Dart_IsError(result) || !Dart_ErrorHasException(result)) {
    return ZX_OK;
  }

  const std::string error =
      tonic::StdStringFromDart(Dart_ToString(Dart_ErrorGetException(result)));
  const std::string stack_trace =
      tonic::StdStringFromDart(Dart_ToString(Dart_ErrorGetStackTrace(result)));

  return HandleException(services, component_url, error, stack_trace);
}

zx_status_t HandleException(std::shared_ptr<::sys::ServiceDirectory> services,
                            const std::string& component_url,
                            const std::string& error,
                            const std::string& stack_trace) {
  fuchsia::mem::Buffer stack_trace_vmo;
  if (!FillBuffer(stack_trace, &stack_trace_vmo)) {
    FXL_LOG(ERROR) << "failed to convert Dart stack trace to VMO";
    return ZX_ERR_INTERNAL;
  }

  fuchsia::crash::AnalyzerSyncPtr analyzer;
  services->Connect(analyzer.NewRequest());
  FXL_DCHECK(analyzer);

  zx_status_t out_status;
  const zx_status_t status = analyzer->HandleManagedRuntimeException(
      fuchsia::crash::ManagedRuntimeLanguage::DART, component_url, error,
      std::move(stack_trace_vmo), &out_status);
  if (status != ZX_OK) {
    FXL_LOG(ERROR) << "failed to connect to crash analyzer: " << status << " ("
                   << zx_status_get_string(status) << ")";
    return ZX_ERR_INTERNAL;
  } else if (out_status != ZX_OK) {
    FXL_LOG(ERROR) << "failed to handle Dart exception: " << out_status << " ("
                   << zx_status_get_string(out_status) << ")";
    return ZX_ERR_INTERNAL;
  }
  return ZX_OK;
}

}  // namespace dart
}  // namespace fuchsia
