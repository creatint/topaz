// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia_services/services.dart';
import 'package:meta/meta.dart';

import '../vmo/vmo_writer.dart';
import 'node.dart';

const int _defaultVmoSizeBytes = 256 * 1024;

/// Inspect exposes a structured tree of internal component state in a VMO.
class Inspect {
  final VmoWriter _writer;

  Node _root;

  /// Initializes a VMO with [vmoSize] and publishes the Inspect data on the
  /// component's (as provided by its [context]) out/ directory.
  factory Inspect(StartupContext context,
      [int vmoSize = _defaultVmoSizeBytes]) {
    var writer = VmoWriter.withSize(vmoSize);
    context.outgoing.debugDir().addNode('root.inspect', writer.vmoNode);
    return Inspect.internal(writer);
  }

  /// Constructor that takes a [VmoWriter] as a parameter, allowing for
  /// injection of fakes for testing.
  @visibleForTesting
  Inspect.internal(this._writer) {
    _root = internalNode(_writer.rootNode, _writer);
  }

  /// The root [Node] of this Inspect tree.
  Node get root => _root;
}
