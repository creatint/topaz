// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia_inspect/src/inspect/internal/_inspect_impl.dart';
import 'package:fuchsia_inspect/src/vmo/util.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_holder.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_writer.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  VmoHolder vmo;
  Node root;

  setUp(() {
    var context = StartupContext.fromStartupInfo();
    vmo = FakeVmo(512);
    var writer = VmoWriter(vmo);
    Inspect inspect = InspectImpl(context, writer);
    root = inspect.root;
  });

  test('Child nodes have unique indices from their parents', () {
    var childNode = root.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode.index, isNot(root.index));
  });

  test('Child nodes created twice return the same object', () {
    var childNode = root.createChild('banana');
    var childNode2 = root.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode2, isNotNull);
    expect(childNode, equals(childNode2));
  });

  test('Nodes created after deletion return different objects', () {
    var childNode = root.createChild('banana')..delete();
    var childNode2 = root.createChild('banana');

    expect(childNode, isNotNull);
    expect(childNode2, isNotNull);
    expect(childNode, isNot(childNode2));
  });

  test('Child nodes have unique indices from their siblings', () {
    var child1 = root.createChild('thing1');
    var child2 = root.createChild('thing2');

    expect(child1.index, isNot(child2.index));
  });

  test('Deleting root node has no effect', () {
    root.delete();
    var child = root.createChild('sheep');
    expect(() => readNameIndex(vmo, child), returnsNormally);
  });

  group('Removed node tests:', () {
    test('can be removed (more than once)', () {
      var child = root.createChild('sheep')..delete();

      expect(() => readNameIndex(vmo, child), throwsA(anything),
          reason: 'cannot read VMO values from a removed node');
      expect(() => child.delete(), returnsNormally);
    });

    test('Creating a child on an already removed node is a no-op', () {
      var child = root.createChild('sheep')..delete();

      Node grandchild;
      expect(() => grandchild = child.createChild('404'), returnsNormally);
      expect(() => grandchild.createChild('404'), returnsNormally);
      expect(() => readNameIndex(vmo, grandchild), throwsA(anything),
          reason: 'cannot read VMO values from a removed node');
    });

    test('Creating an IntMetric on an already removed node is a no-op', () {
      var child = root.createChild('sheep')..delete();

      IntMetric metric;
      expect(() => metric = child.createIntMetric('404'), returnsNormally);
      expect(() => metric.setValue(404), returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed node');
    });

    test('Creating a DoubleMetric on an already removed node is a no-op', () {
      var child = root.createChild('sheep')..delete();

      DoubleMetric metric;
      expect(() => metric = child.createDoubleMetric('404'), returnsNormally);
      expect(() => metric.setValue(404), returnsNormally);
      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed node');
    });

    test('Creating a StringProperty on an already removed node is a no-op', () {
      var child = root.createChild('sheep')..delete();

      StringProperty property;
      expect(
          () => property = child.createStringProperty('404'), returnsNormally);
      expect(() => property.setValue('404'), returnsNormally);
      expect(() => readProperty(vmo, property.index), throwsA(anything),
          reason: 'cannot read VMO values from a removed property');
    });

    test('Creating a ByteDataProperty on an already removed node is a no-op',
        () {
      var child = root.createChild('sheep')..delete();

      ByteDataProperty property;
      expect(() => property = child.createByteDataProperty('404'),
          returnsNormally);
      expect(() => property.setValue(toByteData('fuchsia')), returnsNormally);
      expect(() => readProperty(vmo, property.index), throwsA(anything),
          reason: 'cannot read VMO values from a removed property');
    });

    test('child Node of removed Node is removed', () {
      var child = root.createChild('sheep');
      var grandchild = child.createChild('goats');
      child.delete();
      expect(() => readNameIndex(vmo, grandchild), throwsA(anything),
          reason: 'child Node of deleted Node should be deleted');
    });

    test('child IntMetric of removed Node is removed', () {
      var child = root.createChild('sheep');
      var intMetric = child.createIntMetric('llamas');
      child.delete();
      expect(() => readInt(vmo, intMetric), throwsA(anything),
          reason: 'child IntMetric of deleted Node should be deleted');
    });

    test('child DoubleMetric of removed Node is removed', () {
      var child = root.createChild('sheep');
      var doubleMetric = child.createDoubleMetric('emus');
      child.delete();
      expect(() => readDouble(vmo, doubleMetric), throwsA(anything),
          reason: 'child DoubleMetric of deleted Node should be deleted');
    });

    test('child StringProperty of removed Node is removed', () {
      var child = root.createChild('sheep');
      var stringProperty = child.createStringProperty('okapis');
      child.delete();
      expect(() => readProperty(vmo, stringProperty.index), throwsA(anything),
          reason: 'child StringProperty of deleted Node should be deleted');
    });

    test('child ByteDataProperty of removed Node is removed', () {
      var child = root.createChild('sheep');
      var byteDataProperty = child.createByteDataProperty('capybaras');
      child.delete();
      expect(() => readProperty(vmo, byteDataProperty.index), throwsA(anything),
          reason: 'child ByteDataProperty of deleted Node should be deleted');
    });
  });
}
