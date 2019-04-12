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

  test('Child nodes have unique indices from their parents', () {
    var childNode = node.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode.index, isNot(node.index));
  });

  test('Child nodes have unique indices from their siblings', () {
    var child1 = node.createChild('thing1');
    var child2 = node.createChild('thing2');

    expect(child1.index, isNot(child2.index));
  });

  test('String properties are written to the VMO when the value is set', () {
    var property = node.createStringProperty('color')..value = 'fuchsia';

    expect(readProperty(vmo, property.index),
        equalsByteData(toByteData('fuchsia')));
  });

  test('String properties can be mutated', () {
    var property = node.createStringProperty('breakfast')..value = 'pancakes';

    expect(readProperty(vmo, property.index),
        equalsByteData(toByteData('pancakes')));

    property.value = 'waffles';
    expect(readProperty(vmo, property.index),
        equalsByteData(toByteData('waffles')));
  });
}
