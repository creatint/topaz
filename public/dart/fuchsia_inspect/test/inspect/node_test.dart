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
    expect(childNode, same(childNode2));
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

  group('Deleted node tests:', () {
    Node deletedNode;

    setUp(() {
      deletedNode = root.createChild('sheep')..delete();
    });

    test('can be deleted (more than once)', () {
      var child = deletedNode.createChild('sheep')..delete();
      expect(() => readNameIndex(vmo, deletedNode), throwsA(anything),
          reason: 'cannot read VMO values from a deleted node');
      expect(() => deletedNode.delete(), returnsNormally);
      expect(() => readNameIndex(vmo, child), throwsA(anything),
          reason: 'cannot read VMO values from a deleted node');
      expect(() => child.delete(), returnsNormally);
    });

    test('Creating a child on an already deleted node is a no-op', () {
      Node grandchild;
      expect(
          () => grandchild = deletedNode.createChild('404'), returnsNormally);
      expect(() => grandchild.createChild('404'), returnsNormally);
      expect(() => readNameIndex(vmo, grandchild), throwsA(anything),
          reason: 'cannot read VMO values from a deleted node');
    });

    test('Creating an IntMetric on an already deleted node is a no-op', () {
      IntMetric metric;
      expect(
          () => metric = deletedNode.createIntMetric('404'), returnsNormally);
      expect(() => metric.setValue(404), returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted node');
    });

    test('Creating a DoubleMetric on an already deleted node is a no-op', () {
      DoubleMetric metric;
      expect(() => metric = deletedNode.createDoubleMetric('404'),
          returnsNormally);
      expect(() => metric.setValue(404), returnsNormally);
      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted node');
    });

    test('Creating a StringProperty on an already deleted node is a no-op', () {
      StringProperty property;
      expect(() => property = deletedNode.createStringProperty('404'),
          returnsNormally);
      expect(() => property.setValue('404'), returnsNormally);
      expect(() => readProperty(vmo, property.index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('Creating a ByteDataProperty on an already deleted node is a no-op',
        () {
      ByteDataProperty property;
      expect(() => property = deletedNode.createByteDataProperty('404'),
          returnsNormally);
      expect(() => property.setValue(toByteData('fuchsia')), returnsNormally);
      expect(() => readProperty(vmo, property.index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });
  });

  group('Effects of deletion include: ', () {
    Node normalNode;

    setUp(() {
      normalNode = root.createChild('sheep');
    });

    test('child Node of deleted Node is deleted', () {
      var grandchild = normalNode.createChild('goats');
      normalNode.delete();
      expect(() => readNameIndex(vmo, grandchild), throwsA(anything),
          reason: 'child Node of deleted Node should be deleted');
    });

    test('child IntMetric of deleted Node is deleted', () {
      var intMetric = normalNode.createIntMetric('llamas');
      normalNode.delete();
      expect(() => readInt(vmo, intMetric), throwsA(anything),
          reason: 'child IntMetric of deleted Node should be deleted');
    });

    test('child DoubleMetric of deleted Node is deleted', () {
      var doubleMetric = normalNode.createDoubleMetric('emus');
      normalNode.delete();
      expect(() => readDouble(vmo, doubleMetric), throwsA(anything),
          reason: 'child DoubleMetric of deleted Node should be deleted');
    });

    test('child StringProperty of deleted Node is deleted', () {
      var stringProperty = normalNode.createStringProperty('okapis');
      normalNode.delete();
      expect(() => readProperty(vmo, stringProperty.index), throwsA(anything),
          reason: 'child StringProperty of deleted Node should be deleted');
    });

    test('child ByteDataProperty of deleted Node is deleted', () {
      var byteDataProperty = normalNode.createByteDataProperty('capybaras');
      normalNode.delete();
      expect(() => readProperty(vmo, byteDataProperty.index), throwsA(anything),
          reason: 'child ByteDataProperty of deleted Node should be deleted');
    });
  });

  group('VMO too small', () {
    Node tinyRoot;
    setUp(() {
      var tinyVmo = FakeVmo(64);
      var writer = VmoWriter(tinyVmo);
      var context = StartupContext.fromStartupInfo();
      Inspect inspect = InspectImpl(context, writer);
      tinyRoot = inspect.root;
    });

    test('If no space, creation gives a deleted Node', () {
      var missingNode = tinyRoot.createChild('missing');
      expect(() => missingNode.createChild('more missing'), returnsNormally);
      expect(() => readNameIndex(vmo, missingNode), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted IntMetric', () {
      var missingMetric = tinyRoot.createIntMetric('missing');
      expect(() => missingMetric.setValue(1), returnsNormally);
      expect(() => readInt(vmo, missingMetric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted DoubleMetric', () {
      var missingMetric = tinyRoot.createDoubleMetric('missing');
      expect(() => missingMetric.setValue(1.0), returnsNormally);
      expect(() => readDouble(vmo, missingMetric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted StringProperty', () {
      var missingProperty = tinyRoot.createStringProperty('missing');
      expect(() => missingProperty.setValue('something'), returnsNormally);
      expect(() => readProperty(vmo, missingProperty.index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted ByteDataProperty', () {
      var bytes = toByteData('this will not set');
      var missingProperty = tinyRoot.createByteDataProperty('missing');
      expect(() => missingProperty.setValue(bytes), returnsNormally);
      expect(() => readProperty(vmo, missingProperty.index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });
  });
}
