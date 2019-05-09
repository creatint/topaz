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

  group('Int metrics', () {
    test('default to 0 if the value is unspecified on creation', () {
      var metric = node.createIntMetric('foo');

      expect(readInt(vmo, metric), isZero);
    });

    test('are written to the VMO when the value is set', () {
      var metric = node.createIntMetric('eggs')..setValue(12);

      expect(readInt(vmo, metric), 12);

      var foo = node.createIntMetric('locusts')..increment();
      expect(readInt(vmo, foo), 1);
    });

    test('can be mutated', () {
      var metric = node.createIntMetric('locusts')..setValue(10);
      expect(readInt(vmo, metric), 10);

      metric.setValue(1000);

      expect(readInt(vmo, metric), 1000);
    });

    test('can add arbitrary values', () {
      var metric = node.createIntMetric('bagels')..setValue(13);
      expect(readInt(vmo, metric), 13);

      metric.add(13);

      expect(readInt(vmo, metric), 26);
    });

    test('can increment by 1', () {
      var metric = node.createIntMetric('bagels')..setValue(12);
      expect(readInt(vmo, metric), 12);

      metric.increment();

      expect(readInt(vmo, metric), 13);
    });

    test('can subtract arbitrary values', () {
      var metric = node.createIntMetric('bagels')..setValue(13);
      expect(readInt(vmo, metric), 13);

      metric.subtract(6);

      expect(readInt(vmo, metric), 7);
    });

    test('can decrement by 1', () {
      var metric = node.createIntMetric('soup-for-you')..setValue(1);
      expect(readInt(vmo, metric), 1);

      metric.decrement();

      expect(readInt(vmo, metric), 0);
    });

    test('can be deleted', () {
      var metric = node.createIntMetric('sheep')..delete();

      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted metric');
    });

    test('setting a value on an already deleted metric is a no-op', () {
      var metric = node.createIntMetric('webpages')..delete();

      expect(() => metric.setValue(404), returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted metric');
    });

    test('incrementing on an already deleted metric is a no-op', () {
      var metric = node.createIntMetric('apples')..delete();

      expect(() => metric.increment(), returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted metric');
    });
    test('removing an already deleted metric is a no-op', () {
      var metric = node.createIntMetric('nothing-here')..delete();

      expect(() => metric.delete(), returnsNormally);
    });
  });

  group('Double metrics', () {
    test('default to 0 if the value is unspecified on creation', () {
      var metric = node.createDoubleMetric('foo');

      expect(readDouble(vmo, metric), isZero);
    });

    test('are written to the VMO when the value is set', () {
      var metric = node.createDoubleMetric('foo')..setValue(2.5);

      expect(readDouble(vmo, metric), 2.5);
    });

    test('can be mutated', () {
      var metric = node.createDoubleMetric('bar')..setValue(3.0);
      expect(readDouble(vmo, metric), 3.0);

      metric.setValue(3.5);

      expect(readDouble(vmo, metric), 3.5);
    });

    test('can add arbitrary values', () {
      var metric = node.createDoubleMetric('cake')..setValue(1.5);
      expect(readDouble(vmo, metric), 1.5);

      metric.add(1.5);

      expect(readDouble(vmo, metric), 3);
    });

    test('can increment by 1', () {
      var metric = node.createDoubleMetric('cake')..setValue(1.5);
      expect(readDouble(vmo, metric), 1.5);

      metric.increment();

      expect(readDouble(vmo, metric), 2.5);
    });

    test('can subtract arbitrary values', () {
      var metric = node.createDoubleMetric('cake')..setValue(5);
      expect(readDouble(vmo, metric), 5);

      metric.subtract(0.5);

      expect(readDouble(vmo, metric), 4.5);
    });

    test('can decrement by 1', () {
      var metric = node.createDoubleMetric('donuts')..setValue(12);
      expect(readDouble(vmo, metric), 12);

      metric.decrement();

      expect(readDouble(vmo, metric), 11);
    });

    test('can be deleted', () {
      var metric = node.createDoubleMetric('circumference')..delete();

      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted metric');
    });

    test('setting a value on an already deleted metric is a no-op', () {
      var metric = node.createDoubleMetric('pounds')..delete();

      expect(() => metric.setValue(50.6), returnsNormally);
      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a deleted metric');
    });

    test('removing an already deleted metric is a no-op', () {
      var metric = node.createDoubleMetric('nothing-here')..delete();

      expect(() => metric.delete(), returnsNormally);
    });
  });

  group('Metric creation', () {
    test('IntMetrics created twice return the same object', () {
      var childMetric = node.createIntMetric('banana');
      var childMetric2 = node.createIntMetric('banana');

      expect(childMetric, isNotNull);
      expect(childMetric2, isNotNull);
      expect(childMetric, same(childMetric2));
    });

    test('IntMetrics created after deletion return different objects', () {
      var childMetric = node.createIntMetric('banana')..delete();
      var childMetric2 = node.createIntMetric('banana');

      expect(childMetric, isNotNull);
      expect(childMetric2, isNotNull);
      expect(childMetric, isNot(equals(childMetric2)));
    });

    test('DoubleMetrics created twice return the same object', () {
      var childMetric = node.createDoubleMetric('banana');
      var childMetric2 = node.createDoubleMetric('banana');

      expect(childMetric, isNotNull);
      expect(childMetric2, isNotNull);
      expect(childMetric, same(childMetric2));
    });

    test('DoubleMetrics created after deletion return different objects', () {
      var childMetric = node.createDoubleMetric('banana')..delete();
      var childMetric2 = node.createDoubleMetric('banana');

      expect(childMetric, isNotNull);
      expect(childMetric2, isNotNull);
      expect(childMetric, isNot(equals(childMetric2)));
    });

    test('Changing IntMetric to DoubleMetric throws', () {
      node.createIntMetric('banana');
      expect(() => node.createDoubleMetric('banana'), throwsA(anything));
    });

    test('Changing DoubleMetric to IntMetric throws', () {
      node.createDoubleMetric('banana');
      expect(() => node.createIntMetric('banana'), throwsA(anything));
    });
  });
}
