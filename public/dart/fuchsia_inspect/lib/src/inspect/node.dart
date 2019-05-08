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

  /// Creates a [Node] with [name] under the [parentIndex].
  ///
  /// Private as an implementation detail to code that understands VMO indices.
  /// Client code that wishes to create [Node]s should use [createChild].
  Node._(String name, int parentIndex, this._writer)
      : index = _writer.createNode(parentIndex, name);

  /// Wraps the special root node.
  Node._root(this._writer) : index = _writer.rootNode;

  /// Creates a child [Node] with [name].
  ///
  /// This method is not idempotent: calling it multiple times with the same
  /// [name] will create multiple children with the same name.
  Node createChild(String name) => Node._(name, index, _writer);

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

  /// Creates a [IntMetric] with [name] on this node.
  ///
  /// Optionally sets the [value], if specified.
  ///
  /// Does not check whether the metric already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [IntMetric]s.
  IntMetric createIntMetric(String name, {int value = 0}) =>
      IntMetric._(name, index, _writer, value);

  /// Creates a [DoubleMetric] with [name] on this node.
  ///
  /// Optionally sets the [value], if specified.
  ///
  /// Does not check whether the metric already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [DoubleMetric]s.
  DoubleMetric createDoubleMetric(String name, {double value = 0.0}) =>
      DoubleMetric._(name, index, _writer, value);
}

/// RootNode wraps the root node of the VMO.
///
/// The root node will have special behavior: Delete is a NOP.
///
/// This class should be hidden from the public API.
class RootNode extends Node {
  /// Creates a Node wrapping the root of the Inspect hierarchy.
  RootNode(VmoWriter writer) : super._root(writer);
}
