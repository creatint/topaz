// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia_inspect/inspect.dart';
import 'package:test/test.dart';

void main() {
  test('configureInspect changes the VMO size each time', () {
    Inspect.configureInspect(vmoSizeBytes: 1024);
    expect(Inspect.vmoSize, 1024);
    Inspect.configureInspect(vmoSizeBytes: 2048);
    expect(Inspect.vmoSize, 2048);
  });

  test('configureInspect rejects negative or too-small VMO size', () {
    expect(
        () => Inspect.configureInspect(vmoSizeBytes: -1024), throwsA(anything));
    expect(() => Inspect.configureInspect(vmoSizeBytes: 0), throwsA(anything));
    expect(() => Inspect.configureInspect(vmoSizeBytes: 16), throwsA(anything));
    expect(Inspect.vmoSize, greaterThanOrEqualTo(64));
  });

  test('configureInspect does nothing if called with no parameters', () {
    Inspect.configureInspect(vmoSizeBytes: 2048);
    expect(Inspect.vmoSize, 2048);
    Inspect.configureInspect();
    expect(Inspect.vmoSize, 2048);
  });
}
