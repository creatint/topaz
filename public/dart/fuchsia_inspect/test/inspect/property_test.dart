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
  Node node;

  setUp(() {
    var context = StartupContext.fromStartupInfo();
    vmo = FakeVmo(512);
    var writer = VmoWriter(vmo);
    Inspect inspect = InspectImpl(context, writer);
    node = inspect.root;
  });

  group('String properties', () {
    test('are written to the VMO when the value is set', () {
      var property = node.createStringProperty('color', value: 'fuchsia');

      expect(readProperty(vmo, property.index),
          equalsByteData(toByteData('fuchsia')));
    });

    test('can be mutated', () {
      var property = node.createStringProperty('breakfast')..value = 'pancakes';

      expect(readProperty(vmo, property.index),
          equalsByteData(toByteData('pancakes')));

      property.value = 'waffles';
      expect(readProperty(vmo, property.index),
          equalsByteData(toByteData('waffles')));
    });

    test('can be deleted', () {
      var property = node.createStringProperty('scallops');
      var index = property.index;

      property.delete();

      expect(() => readProperty(vmo, index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('setting a value on an already deleted property is a no-op', () {
      var property = node.createStringProperty('paella');
      var index = property.index;
      property.delete();

      expect(() => property.value = 'this will not set', returnsNormally);
      expect(() => readProperty(vmo, index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('removing an already deleted property is a no-op', () {
      var property = node.createStringProperty('nothing-here')..delete();

      expect(() => property.delete(), returnsNormally);
    });
  });

  group('ByteData properties', () {
    test('are written to the VMO when the value is set', () {
      var bytes = toByteData('fuchsia');
      var property = node.createByteDataProperty('color', value: bytes);

      expect(readProperty(vmo, property.index), equalsByteData(bytes));
    });

    test('can be mutated', () {
      var pancakes = toByteData('pancakes');
      var property = node.createByteDataProperty('breakfast', value: pancakes);

      expect(readProperty(vmo, property.index), equalsByteData(pancakes));

      var waffles = toByteData('waffles');
      property.value = waffles;
      expect(readProperty(vmo, property.index), equalsByteData(waffles));
    });

    test('can be deleted', () {
      var property = node.createByteDataProperty('scallops');
      var index = property.index;

      property.delete();

      expect(() => readProperty(vmo, index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('setting a value on an already deleted property is a no-op', () {
      var property = node.createByteDataProperty('paella');
      var index = property.index;
      property.delete();

      var bytes = toByteData('this will not set');
      expect(() => property.value = bytes, returnsNormally);
      expect(() => readProperty(vmo, index), throwsA(anything),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('removing an already deleted property is a no-op', () {
      var property = node.createByteDataProperty('nothing-here')..delete();

      expect(() => property.delete(), returnsNormally);
    });
  });
}
