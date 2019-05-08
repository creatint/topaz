// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A VMO-backed key-value pair with a [String] key and num value.
abstract class _Metric<T extends num> {
  /// The VMO index for this metric.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  ///
  /// Will be set to null if the metric has been deleted or could not be
  /// created in the VMO.
  /// If so, all actions on this metric should be no-ops and not throw.
  VmoWriter _writer;

  /// Creates a [_Metric] with [name] and [value] under the [parentIndex].
  _Metric(String name, int parentIndex, this._writer, T value)
      : index = _writer.createMetric(parentIndex, name, value) {
    if (index == invalidIndex) {
      _writer = null;
    }
  }

  /// Creates a [_Metric] that never does anything.
  ///
  /// These are returned when calling create__Metric on a deleted [Node].
  _Metric.deleted()
      : _writer = null,
        index = invalidIndex;

  bool get _isDeleted => _writer == null;

  /// Sets the value of this [_Metric].
  void setValue(T value) {
    _writer?.setMetric(index, value);
  }

  /// Adds [delta] to the value of this metric in the VMO.
  void add(T delta) {
    _writer?.addMetric(index, delta);
  }

  /// Increments the value of this metric by 1.
  void increment();

  /// Decrements the value of this metric by 1.
  void decrement();

  /// Subtracts [delta] from the value of this metric in the VMO.
  void subtract(T delta) {
    _writer?.subMetric(index, delta);
  }

  /// Delete this metric from the VMO.
  ///
  /// After a metric has been deleted, it should no longer be used, so callers
  /// should clear their references to this metric after calling delete.
  /// Any calls on an already deleted metric will be no-ops.
  void delete() {
    _writer?.deleteMetric(index);
    _writer = null;
  }
}

/// A VMO-backed key-value pair with a [String] key and [int] value.
class IntMetric extends _Metric<int> {
  IntMetric._(String name, int parentIndex, VmoWriter writer)
      : super(name, parentIndex, writer, 0);

  IntMetric._deleted() : super.deleted();

  @override
  void increment() => add(1);

  @override
  void decrement() => subtract(1);
}

/// A VMO-backed key-value pair with a [String] key and [double] value.
class DoubleMetric extends _Metric<double> {
  DoubleMetric._(String name, int parentIndex, VmoWriter writer)
      : super(name, parentIndex, writer, 0.0);

  DoubleMetric._deleted() : super.deleted();

  @override
  void increment() => add(1.0);

  @override
  void decrement() => subtract(1.0);
}
