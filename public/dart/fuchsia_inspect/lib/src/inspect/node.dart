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
  /// Optionally sets the [value], if specified.
  ///
  /// Does not check whether the property already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [StringProperty]s.
  StringProperty createStringProperty(String name, {String value}) {
    var property = StringProperty._(name, index, _writer);

    if (value != null) {
      property.value = value;
    }

    return property;
  }

  /// Creates a [ByteDataProperty] with [name] on this node.
  ///
  /// Optionally sets the [value], if specified.
  ///
  /// Does not check whether the property already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [ByteDataProperty]s.
  ByteDataProperty createByteDataProperty(String name, {ByteData value}) {
    var property = ByteDataProperty._(name, index, _writer);

    if (value != null) {
      property.value = value;
    }

    return property;
  }
}
