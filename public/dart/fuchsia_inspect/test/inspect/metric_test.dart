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
      var metric = node.createIntMetric('eggs', value: 12);

      expect(readInt(vmo, metric), 12);

      var foo = node.createIntMetric('locusts')..increment();
      expect(readInt(vmo, foo), 1);
    });

    test('can be mutated', () {
      var metric = node.createIntMetric('locusts', value: 10);
      expect(readInt(vmo, metric), 10);

      metric.value = 1000;

      expect(readInt(vmo, metric), 1000);
    });

    test('can add arbitrary values', () {
      var metric = node.createIntMetric('bagels', value: 13);
      expect(readInt(vmo, metric), 13);

      metric.add(13);

      expect(readInt(vmo, metric), 26);
    });

    test('can increment by 1', () {
      var metric = node.createIntMetric('bagels', value: 12);
      expect(readInt(vmo, metric), 12);

      metric.increment();

      expect(readInt(vmo, metric), 13);
    });

    test('can subtract arbitrary values', () {
      var metric = node.createIntMetric('bagels', value: 13);
      expect(readInt(vmo, metric), 13);

      metric.subtract(6);

      expect(readInt(vmo, metric), 7);
    });

    test('can decrement by 1', () {
      var metric = node.createIntMetric('soup-for-you', value: 1);
      expect(readInt(vmo, metric), 1);

      metric.decrement();

      expect(readInt(vmo, metric), 0);
    });

    test('can be removed', () {
      var metric = node.createIntMetric('sheep')..remove();

      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed metric');
    });

    test('setting a value on an already removed metric is a no-op', () {
      var metric = node.createIntMetric('webpages')..remove();

      expect(() => metric.value = 404, returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed metric');
    });

    test('incrementing on an already removed metric is a no-op', () {
      var metric = node.createIntMetric('apples')..remove();

      expect(() => metric.increment(), returnsNormally);
      expect(() => readInt(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed metric');
    });
    test('removing an already removed metric is a no-op', () {
      var metric = node.createIntMetric('nothing-here')..remove();

      expect(() => metric.remove(), returnsNormally);
    });
  });

  group('Double metrics', () {
    test('default to 0 if the value is unspecified on creation', () {
      var metric = node.createDoubleMetric('foo');

      expect(readDouble(vmo, metric), isZero);
    });

    test('are written to the VMO when the value is set', () {
      var metric = node.createDoubleMetric('foo', value: 2.5);

      expect(readDouble(vmo, metric), 2.5);
    });

    test('can be mutated', () {
      var metric = node.createDoubleMetric('bar', value: 3.0);
      expect(readDouble(vmo, metric), 3.0);

      metric.value = 3.5;

      expect(readDouble(vmo, metric), 3.5);
    });

    test('can add arbitrary values', () {
      var metric = node.createDoubleMetric('cake', value: 1.5);
      expect(readDouble(vmo, metric), 1.5);

      metric.add(1.5);

      expect(readDouble(vmo, metric), 3);
    });

    test('can increment by 1', () {
      var metric = node.createDoubleMetric('cake', value: 1.5);
      expect(readDouble(vmo, metric), 1.5);

      metric.increment();

      expect(readDouble(vmo, metric), 2.5);
    });

    test('can subtract arbitrary values', () {
      var metric = node.createDoubleMetric('cake', value: 5);
      expect(readDouble(vmo, metric), 5);

      metric.subtract(0.5);

      expect(readDouble(vmo, metric), 4.5);
    });

    test('can decrement by 1', () {
      var metric = node.createDoubleMetric('donuts', value: 12);
      expect(readDouble(vmo, metric), 12);

      metric.decrement();

      expect(readDouble(vmo, metric), 11);
    });

    test('can be removed', () {
      var metric = node.createDoubleMetric('circumference')..remove();

      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed metric');
    });

    test('setting a value on an already removed metric is a no-op', () {
      var metric = node.createDoubleMetric('pounds')..remove();

      expect(() => metric.value = 50.6, returnsNormally);
      expect(() => readDouble(vmo, metric), throwsA(anything),
          reason: 'cannot read VMO values from a removed metric');
    });

    test('removing an already removed metric is a no-op', () {
      var metric = node.createDoubleMetric('nothing-here')..remove();

      expect(() => metric.remove(), returnsNormally);
    });
  });
}
