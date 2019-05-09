// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia_inspect/src/inspect/internal/_inspect_impl.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_holder.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_writer.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  VmoHolder vmo;
  Node node;

  setUp(() {
    var context = StartupContext.fromStartupInfo();
    vmo = FakeVmo(512);
    var writer = VmoWriter(vmo);
    Inspect inspect = InspectImpl(context, writer);
    node = inspect.root;
  });

  test('Child nodes have unique indices from their parents', () {
    var childNode = node.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode.index, isNot(node.index));
  });

  test('Child nodes created twice return the same object', () {
    var childNode = node.createChild('banana');
    var childNode2 = node.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode2, isNotNull);
    expect(childNode, equals(childNode2));
  });

  test('Child nodes have unique indices from their siblings', () {
    var child1 = node.createChild('thing1');
    var child2 = node.createChild('thing2');

    expect(child1.index, isNot(child2.index));
  });
}
