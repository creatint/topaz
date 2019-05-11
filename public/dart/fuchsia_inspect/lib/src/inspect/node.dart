// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'inspect.dart';

/// A named node in the Inspect tree that can have [Node]s and
/// values under it.
class Node {
  /// The VMO index of this node.
  /// @nodoc
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  ///
  /// Will be set to null if the Node has been deleted or could not be
  /// created in the VMO.
  /// If so, all actions on this Node should be no-ops and not throw.
  VmoWriter _writer;

  final _values = <String, Value>{};
  final _children = <String, Node>{};

  /// Creates a [Node] with [name] under the [parentIndex].
  ///
  /// Private as an implementation detail to code that understands VMO indices.
  /// Client code that wishes to create [Node]s should use [child].
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

  /// Returns a child [Node] with [name].
  ///
  /// If a child with [name] already exists and was not deleted, this
  /// method returns it. Otherwise, it creates a new [Node].
  Node child(String name) {
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

  /// Deletes this node and any children from underlying storage.
  ///
  /// After a node has been deleted, all calls on it and its children have
  /// no effect and do not result in an error. Calls on a deleted node that
  /// return a Node or Value return an already-deleted object.
  void delete() {
    if (_writer == null) {
      return;
    }
    _values
      ..forEach((_, value) => value.delete())
      ..clear();
    _children
      ..forEach((_, node) => node.delete())
      ..clear();

    _writer.deleteEntity(index);
    _writer = null;
  }

  /// Returns a [StringValue] with [name] on this node.
  ///
  /// If a [StringValue] with [name] already exists and is not deleted,
  /// this method returns it.
  ///
  /// Otherwise, it creates a new value initialized to the empty string.
  ///
  /// Throws [InspectStateError] if a non-deleted value with [name] already
  /// exists but it is not a [StringValue].
  StringValue stringValue(String name) {
    if (_writer == null) {
      return StringValue._deleted();
    }
    if (_values.containsKey(name) && !_values[name]._isDeleted) {
      if (_values[name] is! StringValue) {
        throw InspectStateError("Can't create StringValue named $name;"
            ' a different type exists.');
      }
      return _values[name];
    }
    return _values[name] = StringValue._(name, index, _writer);
  }

  /// Returns a [ByteDataValue] with [name] on this node.
  ///
  /// If a [ByteDataValue] with [name] already exists and is not deleted,
  /// this method returns it.
  ///
  /// Otherwise, it creates a new value initialized to the empty
  /// byte data container.
  ///
  /// Throws [InspectStateError] if a non-deleted value with [name] already exists
  /// but it is not a [ByteDataValue].
  ByteDataValue byteDataValue(String name) {
    if (_writer == null) {
      return ByteDataValue._deleted();
    }
    if (_values.containsKey(name) && !_values[name]._isDeleted) {
      if (_values[name] is! ByteDataValue) {
        throw InspectStateError("Can't create ByteDataValue named $name;"
            ' a different type exists.');
      }
      return _values[name];
    }
    return _values[name] = ByteDataValue._(name, index, _writer);
  }

  /// Returns an [IntValue] with [name] on this node.
  ///
  /// If an [IntValue] with [name] already exists and is not
  /// deleted, this method returns it.
  ///
  /// Otherwise, it creates a new value initialized to 0.
  ///
  /// Throws [InspectStateError] if a non-deleted value with [name]
  /// already exists but it is not an [IntValue].
  IntValue intValue(String name) {
    if (_writer == null) {
      return IntValue._deleted();
    }
    if (_values.containsKey(name) && !_values[name]._isDeleted) {
      if (_values[name] is! IntValue) {
        throw InspectStateError(
            "Can't create IntValue named $name; a different type exists.");
      }
      return _values[name];
    }
    return _values[name] = IntValue._(name, index, _writer);
  }

  /// Returns a [DoubleValue] with [name] on this node.
  ///
  /// If a [DoubleValue] with [name] already exists and is not
  /// deleted, this method returns it.
  ///
  /// Otherwise, it creates a new value initialized to 0.0.
  ///
  /// Throws [InspectStateError] if a non-deleted value with [name]
  /// already exists but it is not a [DoubleValue].
  DoubleValue doubleValue(String name) {
    if (_writer == null) {
      return DoubleValue._deleted();
    }
    if (_values.containsKey(name) && !_values[name]._isDeleted) {
      if (_values[name] is! DoubleValue) {
        throw InspectStateError("Can't create DoubleValue named $name;"
            ' a different type exists.');
      }
      return _values[name];
    }
    return _values[name] = DoubleValue._(name, index, _writer);
  }
}

/// RootNode wraps the root node of the VMO.
///
/// The root node has special behavior: Delete is a NOP.
///
/// This class should be hidden from the public API.
/// @nodoc
class RootNode extends Node {
  /// Creates a Node wrapping the root of the Inspect hierarchy.
  RootNode(VmoWriter writer) : super._root(writer);

  /// Deletes of the root are NOPs.
  @override
  void delete() {}
}
