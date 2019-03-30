// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:fuchsia_inspect/src/node.dart';
import 'package:fuchsia_inspect/src/util.dart';
import 'package:fuchsia_inspect/src/vmo_holder.dart';
import 'package:fuchsia_inspect/src/vmo_writer.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  VmoHolder vmo;
  Node node;

  setUp(() {
    vmo = FakeVmo(512);
    var writer = VmoWriter(vmo);
    node = Node(writer.rootNode, writer);
  });

  test('String properties are written to the VMO when the value is set', () {
    var property = node.createStringProperty('color')..value = 'fuchsia';

    expect(readProperty(vmo, property.index).buffer.asUint8List(),
        toByteData('fuchsia').buffer.asUint8List());
  });

  test('String properties can be mutated', () {
    var property = node.createStringProperty('breakfast')..value = 'pancakes';

    expect(readProperty(vmo, property.index).buffer.asUint8List(),
        toByteData('pancakes').buffer.asUint8List());

    property.value = 'waffles';
    expect(readProperty(vmo, property.index).buffer.asUint8List(),
        toByteData('waffles').buffer.asUint8List());
  });
}
