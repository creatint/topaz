// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

bool includeFunction(String function) {
  return function.startsWith("dart:") ||
         function.startsWith("package:flutter/") ||
         function.startsWith("package:vector_math/");
}

main(List<String> args) async {
  if (args.length == 0) {
    print("Usage:\n"
          "  dart merge_traces.dart trace1.txt ... traceN.txt > merged_trace.txt");
    exitCode = 1;
    return;
  }

  var functionCounts = new Map<String, int>();
  for (var tracePath in args) {
    for (var function in await new File(tracePath).readAsLines()) {
      if (!includeFunction(function)) {
        continue;
      }
      var count = functionCounts[function];
      if (count == null) {
        count = 1;
      } else {
        count++;
      }
      functionCounts[function] = count;
    }
  }

  var functions = new List<String>();
  // TODO(flutter): Investigate consensus functions to avoid bloat.
  var minimumCount = 1;
  functionCounts.forEach((String function, int count) {
    if (count >= minimumCount) {
      functions.add(function);
    }
  });

  functions.sort();

  for (var function in functions) {
    print(function);
  }
}
