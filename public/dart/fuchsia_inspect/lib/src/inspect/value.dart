// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A VMO-backed key-value pair with a [String] key and a typed value.
abstract class Value<T> {
  /// The VMO index for this value.
  /// @nodoc
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  ///
  /// Will be set to null if the [Value] has been deleted or could not be
  /// created in the VMO.
  /// If so, all actions on this [Value] should be no-ops and not throw.
  VmoWriter _writer;

  /// Creates a modifiable [Value].
  Value._(this.index, this._writer) {
    if (index == invalidIndex) {
      _writer = null;
    }
  }

  /// Creates a [Value] that never does anything.
  ///
  /// These are returned when calling methods on a deleted Node,
  /// or if there is no space for a newly created value in underlying storage.
  Value.deleted()
      : _writer = null,
        index = invalidIndex;

  bool get _isDeleted => _writer == null;

  /// Sets the value of this [Value].
  void setValue(T value);

  /// Deletes this value from underlying storage.
  /// Calls on a deleted value have no effect and do not result in an error.
  void delete() {
    _writer?.deleteEntity(index);
    _writer = null;
  }
}

/// Sets value on "Property" type values - those which store a byte-vector.
mixin Property<T> on Value<T> {
  @override
  void setValue(T value) {
    _writer?.setProperty(index, value);
  }
}

/// Operations on "Metric" type values - those which store a number.
mixin Arithmetic<T extends num> on Value<T> {
  /// Adds [delta] to the value of this metric.
  void add(T delta) {
    _writer?.addMetric(index, delta);
  }

  /// Subtracts [delta] from the value of this metric.
  void subtract(T delta) {
    _writer?.subMetric(index, delta);
  }

  @override
  void setValue(T value) {
    _writer?.setMetric(index, value);
  }
}

/// A value holding an [int].
///
/// Only [Node.intValue()] can create this object.
class IntValue extends Value<int> with Arithmetic<int> {
  IntValue._(String name, int parentIndex, VmoWriter writer)
      : super._(writer.createMetric(parentIndex, name, 0), writer);

  IntValue._deleted() : super.deleted();
}

/// A value holding a [double].
///
/// Only [Node.doubleValue()] can create this object.
class DoubleValue extends Value<double> with Arithmetic<double> {
  DoubleValue._(String name, int parentIndex, VmoWriter writer)
      : super._(writer.createMetric(parentIndex, name, 0.0), writer);

  DoubleValue._deleted() : super.deleted();
}

/// A value holding a [String].
///
/// Only [Node.stringValue()] can create this object.
class StringValue extends Value<String> with Property<String> {
  StringValue._(String name, int parentIndex, VmoWriter writer)
      : super._(writer.createProperty(parentIndex, name), writer);

  StringValue._deleted() : super.deleted();
}

/// A value holding a [ByteData].
///
/// Only [Node.byteDataValue()] can create this object.
class ByteDataValue extends Value<ByteData> with Property<ByteData> {
  ByteDataValue._(String name, int parentIndex, VmoWriter writer)
      : super._(writer.createProperty(parentIndex, name), writer);

  ByteDataValue._deleted() : super.deleted();
}
