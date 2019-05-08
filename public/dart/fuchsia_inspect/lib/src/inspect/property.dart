// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../vmo/vmo_writer.dart';

/// Exposes internal constructor to other implementation files within the
/// package but should be hidden to clients of the package.
StringProperty internalStringProperty(
        String name, int parentIndex, VmoWriter writer) =>
    StringProperty._(name, parentIndex, writer);

/// Exposes internal constructor to other implementation files within the
/// package but should be hidden to clients of the package.
ByteDataProperty internalByteDataProperty(
        String name, int parentIndex, VmoWriter writer) =>
    ByteDataProperty._(name, parentIndex, writer);

/// A VMO-backed key-value pair with a [String] key and [T] value.
class _Property<T> {
  /// The VMO index for this property.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  ///
  /// Will be set to null if the property has been deleted or could not be
  ///  created in the VMO.
  /// If so, all actions on this property will be no-ops and not throw.
  VmoWriter _writer;

  /// Creates a [_Property] with [name] under the [parentIndex].
  _Property(String name, int parentIndex, this._writer)
      : index = _writer.createProperty(parentIndex, name);

  /// Sets the value of this property in the VMO.
  set value(T value) {
    _writer?.setProperty(index, value);
  }

  /// Delete this property from the VMO.
  ///
  /// After a property has been deleted, it should no longer be used, so callers
  /// should clear their references to this property after calling delete.
  /// Any calls on an already deleted property will be no-ops.
  void delete() {
    _writer?.deleteProperty(index);
    _writer = null;
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
