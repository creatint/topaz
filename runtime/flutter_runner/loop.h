// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_LOOP_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_LOOP_H_

#include <lib/async-loop/cpp/loop.h>

namespace flutter {

// Creates a loop which allows task observers to be attached to it.
async::Loop* MakeObservableLoop(bool attachToThread);

}  // namespace flutter

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_LOOP_H_
