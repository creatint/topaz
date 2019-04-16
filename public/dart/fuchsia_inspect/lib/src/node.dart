// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A node in the [Inspect] tree that can have associated key-values (KVs).
class Node {
  /// The VMO index of this node.
  @visibleForTesting
  final int index;

  /// The writer for the VMO that backs this node.
  final VmoWriter _writer;

  /// Creates a [Node] with the VMO [index] and [writer].
  ///
  /// Private as an implementation detail to code that understands VMO indices.
  /// Client code that wishes to create [Node]s should use [createChild].
  Node._(this.index, this._writer);

  /// Creates a child [Node] with [name].
  ///
  /// This method is not idempotent: calling it multiple times with the same
  /// [name] will create multiple children with the same name.
  Node createChild(String name) =>
      Node._(_writer.createNode(index, name), _writer);

  /// Creates a [StringProperty] with [name] on this node.
  ///
  /// Does not check whether the property already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [StringProperty]s.
  StringProperty createStringProperty(String name) =>
      StringProperty._(name, index, _writer);
}

/// A VMO-backed key-value pair with a string key and string value.
class StringProperty {
  /// The VMO index for this property.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  final VmoWriter _writer;

  /// Whether this property has been removed from the VMO.
  ///
  /// If so, all actions on this property should be no-ops and not throw.
  bool _isRemoved = false;

  /// Creates a [StringProperty] with [name] under the [parentIndex].
  StringProperty._(String name, int parentIndex, this._writer)
      : index = _writer.createProperty(parentIndex, name);

  /// Sets the value of this property in the VMO.
  set value(String value) {
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
