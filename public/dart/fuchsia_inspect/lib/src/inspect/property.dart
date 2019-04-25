// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A VMO-backed key-value pair with a [String] key and [T] value.
class _Property<T> {
  /// The VMO index for this property.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  final VmoWriter _writer;

  /// Whether this property has been removed from the VMO.
  ///
  /// If so, all actions on this property should be no-ops and not throw.
  bool _isRemoved = false;

  /// Creates a [_Property] with [name] under the [parentIndex].
  _Property(String name, int parentIndex, this._writer)
      : index = _writer.createProperty(parentIndex, name);

  /// Sets the value of this property in the VMO.
  set value(T value) {
    if (_isRemoved) {
      return;
    }

    _writer.setProperty(index, value);
  }

  /// Remove this property from the VMO.
  ///
  /// After a property has been removed, it should no longer be used, so callers
  /// should clear their references to this property after calling remove.
  /// Any calls on an already removed property will be no-ops.
  void remove() {
    if (_isRemoved) {
      return;
    }

    _writer.deleteProperty(index);
    _isRemoved = true;
  }
}

/// A VMO-backed key-value pair with a [String] key and [String] value.
class StringProperty extends _Property<String> {
  StringProperty._(String name, int parentIndex, VmoWriter writer)
      : super(name, parentIndex, writer);
}

/// A VMO-backed key-value pair with a [String] key and [ByteData] value.
class ByteDataProperty extends _Property<ByteData> {
  ByteDataProperty._(String name, int parentIndex, VmoWriter writer)
      : super(name, parentIndex, writer);
}
