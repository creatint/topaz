// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../vmo/vmo_writer.dart';

/// Exposes internal constructor to other implementation files within the
/// package but should be hidden to clients of the package.
IntMetric internalIntMetric(
        String name, int parentIndex, VmoWriter writer, int value) =>
    IntMetric._(name, parentIndex, writer, value);

/// Exposes internal constructor to other implementation files within the
/// package but should be hidden to clients of the package.
DoubleMetric internalDoubleMetric(
        String name, int parentIndex, VmoWriter writer, double value) =>
    DoubleMetric._(name, parentIndex, writer, value);

/// A VMO-backed key-value pair with a [String] key and num value.
abstract class _Metric<T extends num> {
  /// The VMO index for this metric.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  final VmoWriter _writer;

  /// Whether this metric has been removed from the VMO.
  ///
  /// If so, all actions on this metric should be no-ops and not throw.
  bool _isRemoved = false;

  /// Creates a [_Metric] with [name] and [value] under the [parentIndex].
  _Metric(String name, int parentIndex, this._writer, T value)
      : index = _writer.createMetric(parentIndex, name, value);

  /// Sets the value of this metric in the VMO.
  set value(T value) {
    if (_isRemoved) {
      return;
    }

    _writer.setMetric(index, value);
  }

  /// Adds [delta] to the value of this metric in the VMO.
  void add(T delta) {
    if (_isRemoved) {
      return;
    }

    _writer.addMetric(index, delta);
  }

  /// Increments the value of this metric by 1.
  void increment();

  /// Decrements the value of this metric by 1.
  void decrement();

  /// Subtracts [delta] from the value of this metric in the VMO.
  void subtract(T delta) {
    if (_isRemoved) {
      return;
    }

    _writer.subMetric(index, delta);
  }

  /// Remove this metric from the VMO.
  ///
  /// After a metric has been removed, it should no longer be used, so callers
  /// should clear their references to this metric after calling remove.
  /// Any calls on an already removed metric will be no-ops.
  void remove() {
    if (_isRemoved) {
      return;
    }

    _writer.deleteMetric(index);
    _isRemoved = true;
  }
}

/// A VMO-backed key-value pair with a [String] key and [int] value.
class IntMetric extends _Metric<int> {
  IntMetric._(String name, int parentIndex, VmoWriter writer, int value)
      : super(name, parentIndex, writer, value);

  @override
  void increment() => add(1);

  @override
  void decrement() => subtract(1);
}

/// A VMO-backed key-value pair with a [String] key and [double] value.
class DoubleMetric extends _Metric<double> {
  DoubleMetric._(String name, int parentIndex, VmoWriter writer, double value)
      : super(name, parentIndex, writer, value);

  @override
  void increment() => add(1.0);

  @override
  void decrement() => subtract(1.0);
}
