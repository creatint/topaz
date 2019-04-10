// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This target runs all benchmarks for the Topaz layer.

#include "garnet/testing/benchmarking/benchmarking.h"
#include "garnet/testing/benchmarking/is_vulkan_supported.h"
#include "src/lib/fxl/logging.h"
#include "topaz/tests/benchmarks/gfx_benchmarks.h"

int main(int argc, const char** argv) {
  auto maybe_benchmarks_runner =
      benchmarking::BenchmarksRunner::Create(argc, argv);
  if (!maybe_benchmarks_runner) {
    exit(1);
  }

  auto& benchmarks_runner = *maybe_benchmarks_runner;

  if (benchmarking::IsVulkanSupported()) {
    // DISABLED: See SCN-1223
    // AddGraphicsBenchmarks(&benchmarks_runner);
    FXL_LOG(INFO) << "Graphics performance tests disabled";
  } else {
    FXL_LOG(INFO) << "Vulkan not supported; graphics tests skipped.";
  }

  benchmarks_runner.Finish();
}
