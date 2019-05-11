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

  group('String values', () {
    test('are written to the VMO when the value is set', () {
      var value = node.stringValue('color')..setValue('fuchsia');

      expect(readProperty(vmo, value.index),
          equalsByteData(toByteData('fuchsia')));
    });

    test('can be mutated', () {
      var value = node.stringValue('breakfast')..setValue('pancakes');

      expect(readProperty(vmo, value.index),
          equalsByteData(toByteData('pancakes')));

      value.setValue('waffles');
      expect(readProperty(vmo, value.index),
          equalsByteData(toByteData('waffles')));
    });

    test('can be deleted', () {
      var value = node.stringValue('scallops');
      var index = value.index;

      value.delete();

      expect(() => readProperty(vmo, index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('setting a value on an already deleted value is a no-op', () {
      var value = node.stringValue('paella');
      var index = value.index;
      value.delete();

      expect(() => value.setValue('this will not set'), returnsNormally);
      expect(() => readProperty(vmo, index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('removing an already deleted value is a no-op', () {
      var value = node.stringValue('nothing-here')..delete();

      expect(() => value.delete(), returnsNormally);
    });
  });

  group('ByteData values', () {
    test('are written to the VMO when the value is set', () {
      var bytes = toByteData('fuchsia');
      var value = node.byteDataValue('color')..setValue(bytes);

      expect(readProperty(vmo, value.index), equalsByteData(bytes));
    });

    test('can be mutated', () {
      var pancakes = toByteData('pancakes');
      var value = node.byteDataValue('breakfast')..setValue(pancakes);

      expect(readProperty(vmo, value.index), equalsByteData(pancakes));

      var waffles = toByteData('waffles');
      value.setValue(waffles);
      expect(readProperty(vmo, value.index), equalsByteData(waffles));
    });

    test('can be deleted', () {
      var value = node.byteDataValue('scallops');
      var index = value.index;

      value.delete();

      expect(() => readProperty(vmo, index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('setting a value on an already deleted value is a no-op', () {
      var value = node.byteDataValue('paella');
      var index = value.index;
      value.delete();

      var bytes = toByteData('this will not set');
      expect(() => value.setValue(bytes), returnsNormally);
      expect(() => readProperty(vmo, index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('removing an already deleted value is a no-op', () {
      var value = node.byteDataValue('nothing-here')..delete();

      expect(() => value.delete(), returnsNormally);
    });
  });

  group('Property creation (byte-vector Values)', () {
    test('StringValues created twice return the same object', () {
      var childValue = node.stringValue('banana');
      var childValue2 = node.stringValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, same(childValue2));
    });

    test('StringValues created after deletion return different objects', () {
      var childValue = node.stringValue('banana')..delete();
      var childValue2 = node.stringValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, isNot(equals(childValue2)));
    });

    test('ByteDataValues created twice return the same object', () {
      var childValue = node.byteDataValue('banana');
      var childValue2 = node.byteDataValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, same(childValue2));
    });

    test('ByteDataValues created after deletion return different objects', () {
      var childValue = node.byteDataValue('banana')..delete();
      var childValue2 = node.byteDataValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, isNot(equals(childValue2)));
    });

    test('Changing StringValue to ByteDataValue throws', () {
      node.stringValue('banana');
      expect(() => node.byteDataValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing StringValue to IntValue throws', () {
      node.stringValue('banana');
      expect(() => node.intValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing StringValue to DoubleValue throws', () {
      node.stringValue('banana');
      expect(() => node.doubleValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing ByteDataValue to StringValue throws', () {
      node.byteDataValue('banana');
      expect(() => node.stringValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing ByteDataValue to IntValue throws', () {
      node.byteDataValue('banana');
      expect(() => node.intValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing ByteDataValue to DoubleValue throws', () {
      node.byteDataValue('banana');
      expect(() => node.doubleValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('If no space, creation gives a deleted StringValue', () {
      var tinyVmo = FakeVmo(64);
      var writer = VmoWriter(tinyVmo);
      var context = StartupContext.fromStartupInfo();
      Inspect inspect = InspectImpl(context, writer);
      var tinyRoot = inspect.root;
      var missingValue = tinyRoot.stringValue('missing');
      expect(() => missingValue.setValue('something'), returnsNormally);
      expect(() => readProperty(vmo, missingValue.index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted ByteDataValue', () {
      var tinyVmo = FakeVmo(64);
      var writer = VmoWriter(tinyVmo);
      var context = StartupContext.fromStartupInfo();
      Inspect inspect = InspectImpl(context, writer);
      var tinyRoot = inspect.root;
      var bytes = toByteData('this will not set');
      var missingValue = tinyRoot.byteDataValue('missing');
      expect(() => missingValue.setValue(bytes), returnsNormally);
      expect(() => readProperty(vmo, missingValue.index),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });
  });

  group('Int Values', () {
    test('are created with value 0', () {
      var value = node.intValue('foo');

      expect(readInt(vmo, value), isZero);
    });

    test('are written to the VMO when the value is set', () {
      var value = node.intValue('eggs')..setValue(12);

      expect(readInt(vmo, value), 12);
    });

    test('can be mutated', () {
      var value = node.intValue('locusts')..setValue(10);
      expect(readInt(vmo, value), 10);

      value.setValue(1000);

      expect(readInt(vmo, value), 1000);
    });

    test('can add arbitrary values', () {
      var value = node.intValue('bagels')..setValue(13);
      expect(readInt(vmo, value), 13);

      value.add(13);

      expect(readInt(vmo, value), 26);
    });

    test('can subtract arbitrary values', () {
      var value = node.intValue('bagels')..setValue(13);
      expect(readInt(vmo, value), 13);

      value.subtract(6);

      expect(readInt(vmo, value), 7);
    });

    test('can be deleted', () {
      var value = node.intValue('sheep')..delete();

      expect(
          () => readInt(vmo, value), throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted value');
    });

    test('setting a value on an already deleted value is a no-op', () {
      var value = node.intValue('webpages')..delete();

      expect(() => value.setValue(404), returnsNormally);
      expect(
          () => readInt(vmo, value), throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted value');
    });

    test('removing an already deleted value is a no-op', () {
      var value = node.intValue('nothing-here')..delete();

      expect(() => value.delete(), returnsNormally);
    });
  });

  group('DoubleValues', () {
    test('are created with value 0', () {
      var value = node.doubleValue('foo');

      expect(readDouble(vmo, value), isZero);
    });

    test('are written to the VMO when the value is set', () {
      var value = node.doubleValue('foo')..setValue(2.5);

      expect(readDouble(vmo, value), 2.5);
    });

    test('can be mutated', () {
      var value = node.doubleValue('bar')..setValue(3.0);
      expect(readDouble(vmo, value), 3.0);

      value.setValue(3.5);

      expect(readDouble(vmo, value), 3.5);
    });

    test('can add arbitrary values', () {
      var value = node.doubleValue('cake')..setValue(1.5);
      expect(readDouble(vmo, value), 1.5);

      value.add(1.5);

      expect(readDouble(vmo, value), 3);
    });

    test('can subtract arbitrary values', () {
      var value = node.doubleValue('cake')..setValue(5);
      expect(readDouble(vmo, value), 5);

      value.subtract(0.5);

      expect(readDouble(vmo, value), 4.5);
    });

    test('can be deleted', () {
      var value = node.doubleValue('circumference')..delete();

      expect(() => readDouble(vmo, value),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted value');
    });

    test('setting a value on an already deleted value is a no-op', () {
      var value = node.doubleValue('pounds')..delete();

      expect(() => value.setValue(50.6), returnsNormally);
      expect(() => readDouble(vmo, value),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted value');
    });

    test('removing an already deleted value is a no-op', () {
      var value = node.doubleValue('nothing-here')..delete();

      expect(() => value.delete(), returnsNormally);
    });
  });

  group('value creation', () {
    test('IntValues created twice return the same object', () {
      var childValue = node.intValue('banana');
      var childValue2 = node.intValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, same(childValue2));
    });

    test('IntValues created after deletion return different objects', () {
      var childValue = node.intValue('banana')..delete();
      var childValue2 = node.intValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, isNot(equals(childValue2)));
    });

    test('DoubleValues created twice return the same object', () {
      var childValue = node.doubleValue('banana');
      var childValue2 = node.doubleValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, same(childValue2));
    });

    test('DoubleValues created after deletion return different objects', () {
      var childValue = node.doubleValue('banana')..delete();
      var childValue2 = node.doubleValue('banana');

      expect(childValue, isNotNull);
      expect(childValue2, isNotNull);
      expect(childValue, isNot(equals(childValue2)));
    });

    test('Changing IntValue to DoubleValue throws', () {
      node.intValue('banana');
      expect(() => node.doubleValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing IntValue to StringValue throws', () {
      node.intValue('banana');
      expect(() => node.stringValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing IntValue to ByteDataValue throws', () {
      node.intValue('banana');
      expect(() => node.byteDataValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing DoubleValue to IntValue throws', () {
      node.doubleValue('banana');
      expect(() => node.intValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing DoubleValue to StringValue throws', () {
      node.doubleValue('banana');
      expect(() => node.stringValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('Changing DoubleValue to ByteDataValue throws', () {
      node.doubleValue('banana');
      expect(() => node.byteDataValue('banana'),
          throwsA(const TypeMatcher<InspectStateError>()));
    });

    test('If no space, creation gives a deleted IntValue', () {
      var tinyVmo = FakeVmo(64);
      var writer = VmoWriter(tinyVmo);
      var context = StartupContext.fromStartupInfo();
      Inspect inspect = InspectImpl(context, writer);
      var tinyRoot = inspect.root;
      var missingValue = tinyRoot.intValue('missing');
      expect(() => missingValue.setValue(1), returnsNormally);
      expect(() => readInt(vmo, missingValue),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });

    test('If no space, creation gives a deleted DoubleValue', () {
      var tinyVmo = FakeVmo(64);
      var writer = VmoWriter(tinyVmo);
      var context = StartupContext.fromStartupInfo();
      Inspect inspect = InspectImpl(context, writer);
      var tinyRoot = inspect.root;
      var missingValue = tinyRoot.doubleValue('missing');
      expect(() => missingValue.setValue(1.0), returnsNormally);
      expect(() => readDouble(vmo, missingValue),
          throwsA(const TypeMatcher<StateError>()),
          reason: 'cannot read VMO values from a deleted property');
    });
  });
}
