// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia_inspect/src/vmo_writer.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  test('Inspect root node is non-null by default', () {
    var vmo = FakeVmo(512);
    var writer = VmoWriter(vmo);
    var inspect = Inspect.internal(writer);
    expect(inspect.root, isNotNull);
  });
}
