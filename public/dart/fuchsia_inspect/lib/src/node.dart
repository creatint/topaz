// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'vmo_writer.dart';

/// A node in the [Inspect] tree that can have associated key-values (KVs).
class Node {
  /// The VMO index of this node.
  final int _index;

  /// The writer for the VMO that backs this node.
  final VmoWriter _writer;

  /// Creates a [Node] with the VMO [index] and [writer].
  Node(this._index, this._writer);

  /// Creates a [StringProperty] with [name] on this node.
  ///
  /// Does not check whether the property already exists. This method is not
  /// idempotent and calling it multiple times with the same [name] will
  /// create multiple [StringProperty]s.
  StringProperty createStringProperty(String name) =>
      StringProperty(name, _index, _writer);
}

/// A VMO-backed key-value pair with a string key and string value.
class StringProperty {
  /// The VMO index for this property.
  @visibleForTesting
  final int index;

  /// The writer for the underlying VMO.
  final VmoWriter _writer;

  /// Creates a [StringProperty] with [name] under the [parentIndex].
  StringProperty(String name, int parentIndex, this._writer)
      : index = _writer.createProperty(parentIndex, name);

  /// Sets the value of this property in the VMO.
  set value(String value) => _writer.setProperty(index, value);
}
