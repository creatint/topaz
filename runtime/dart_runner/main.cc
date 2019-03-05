// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <lib/async-loop/cpp/loop.h>
#include <trace-provider/provider.h>
#include <trace/event.h>

#include "topaz/runtime/dart/utils/tempfs.h"
#include "topaz/runtime/dart_runner/dart_runner.h"

int main(int argc, const char** argv) {
  async::Loop loop(&kAsyncLoopConfigAttachToThread);
  fbl::unique_ptr<trace::TraceProvider> provider;
  {
    TRACE_DURATION("dart", "CreateTraceProvider");
    bool already_started;
    // Use CreateSynchronously to prevent loss of early events.
    trace::TraceProvider::CreateSynchronously(loop.dispatcher(), "dart_runner",
                                              &provider, &already_started);
  }
  fuchsia::dart::SetupRunnerTemp();
  dart_runner::DartRunner runner;
  loop.Run();
  return 0;
}
