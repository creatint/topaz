// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A node in the [Inspect] tree that can have associated key-values (KVs).
class Node {
  /// The VMO index of this node.
  /// @nodoc
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  ///
  /// Will be set to null if the Metric has been deleted or could not be
  /// created in the VMO.
  /// If so, all actions on this Metric should be no-ops and not throw.
  VmoWriter _writer;

  final _properties = <String, _Property>{};
  final _metrics = <String, _Metric>{};
  final _children = <String, Node>{};

  /// Creates a [Node] with [name] under the [parentIndex].
  ///
  /// Private as an implementation detail to code that understands VMO indices.
  /// Client code that wishes to create [Node]s should use [createChild].
  Node._(String name, int parentIndex, this._writer)
      : index = _writer.createNode(parentIndex, name) {
    if (index == invalidIndex) {
      _writer = null;
    }
  }

  /// Wraps the special root node.
  Node._root(this._writer) : index = _writer.rootNode;

  /// Creates a Node that never does anything.
  ///
  /// These are returned when calling createChild on a deleted [Node].
  Node._deleted()
      : _writer = null,
        index = invalidIndex;

  bool get _isDeleted => _writer == null;

  /// Creates a child [Node] with [name].
  ///
  /// If a child with [name] already exists, this
  /// method returns it. Otherwise, it creates a new [Node].
  Node createChild(String name) {
    if (_writer == null) {
      return Node._deleted();
    }
    // TODO(cphoenix): Tell parents when deleted, instead of asking children.
    // Asking children allows the map to grow without limit as children are
    // created and deleted (e.g. ring buffer).
    if (_children.containsKey(name) && !_children[name]._isDeleted) {
      return _children[name];
    }
    return _children[name] = Node._(name, index, _writer);
  }

  /// Delete this node and any children from underlying storage.
  ///
  /// After a node has been deleted, all calls on it and its children will have
  /// no effect, but will not result in an error.
  void delete() {
    if (_writer == null) {
      return;
    }
    _properties
      ..forEach((_, property) => property.delete())
      ..clear();
    _metrics
      ..forEach((_, metric) => metric.delete())
      ..clear();
    _children
      ..forEach((_, node) => node.delete())
      ..clear();

    _writer.deleteNode(index);
    _writer = null;
  }

  /// Creates a [StringProperty] with [name] on this node.
  ///
  /// If a [StringProperty] with [name] already exists and is not deleted,
  /// this method returns it.
  ///
  /// Otherwise, it creates a new property initialized to the empty string.
  ///
  /// Throws [StateError] if a non-deleted property with [name] already exists
  /// but it is not a [StringProperty].
  StringProperty createStringProperty(String name) {
    if (_writer == null) {
      return StringProperty._deleted();
    }
    if (_properties.containsKey(name) && !_properties[name]._isDeleted) {
      if (_properties[name] is! StringProperty) {
        throw InspectStateError("Can't create StringProperty named $name;"
            ' a different type exists.');
      }
      return _properties[name];
    }
    return _properties[name] = StringProperty._(name, index, _writer);
  }

  /// Creates a [ByteDataProperty] with [name] on this node.
  ///
  /// If a [ByteDataProperty] with [name] already exists and is not deleted,
  /// this method returns it.
  ///
  /// Otherwise, it creates a new property initialized to the empty
  /// byte data container.
  ///
  /// Throws [StateError] if a non-deleted property with [name] already exists
  /// but it is not a [ByteDataProperty].
  ByteDataProperty createByteDataProperty(String name) {
    if (_writer == null) {
      return ByteDataProperty._deleted();
    }
    if (_properties.containsKey(name) && !_properties[name]._isDeleted) {
      if (_properties[name] is! ByteDataProperty) {
        throw InspectStateError("Can't create ByteDataProperty named $name;"
            ' a different type exists.');
      }
      return _properties[name];
    }
    return _properties[name] = ByteDataProperty._(name, index, _writer);
  }

  /// Creates an [IntMetric] with [name] on this node.
  ///
  /// If an [IntMetric] with [name] already exists and is not
  /// deleted, this method returns it.
  ///
  /// Otherwise, it creates a new metric initialized to 0.
  ///
  /// Throws [StateError] if a non-deleted metric with [name]
  /// already exists but it is not an [IntMetric].
  IntMetric createIntMetric(String name) {
    if (_writer == null) {
      return IntMetric._deleted();
    }
    if (_metrics.containsKey(name) && !_metrics[name]._isDeleted) {
      if (_metrics[name] is! IntMetric) {
        throw InspectStateError(
            "Can't create IntMetric named $name; a different type exists.");
      }
      return _metrics[name];
    }
    return _metrics[name] = IntMetric._(name, index, _writer);
  }

  /// Creates a [DoubleMetric] with [name] on this node.
  ///
  /// If a [DoubleMetric] with [name] already exists and is not
  /// deleted, this method returns it.
  ///
  /// Otherwise, it creates a new metric initialized to 0.0.
  ///
  /// Throws [StateError] if a non-deleted metric with [name]
  /// already exists but it is not a [DoubleMetric].
  DoubleMetric createDoubleMetric(String name) {
    if (_writer == null) {
      return DoubleMetric._deleted();
    }
    if (_metrics.containsKey(name) && !_metrics[name]._isDeleted) {
      if (_metrics[name] is! DoubleMetric) {
        throw InspectStateError("Can't create DoubleMetric named $name;"
            ' a different type exists.');
      }
      return _metrics[name];
    }
    return _metrics[name] = DoubleMetric._(name, index, _writer);
  }
}

/// RootNode wraps the root node of the VMO.
///
/// The root node has special behavior: Delete is a NOP.
///
/// This class should be hidden from the public API.
class RootNode extends Node {
  /// Creates a Node wrapping the root of the Inspect hierarchy.
  RootNode(VmoWriter writer) : super._root(writer);

  /// Deletes of the root are NOPs.
  @override
  void delete() {}
}
