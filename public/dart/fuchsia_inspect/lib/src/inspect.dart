// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia_services/services.dart';

import 'vmo_writer.dart';

const int _defaultVmoSizeBytes = 256 * 1024;

/// Inspect exposes a structured tree of internal component state in a VMO.
class Inspect {
  final VmoWriter _writer;

  /// Initialize the VMO with given or default size.
  Inspect(StartupContext context, [int vmoSize = _defaultVmoSizeBytes])
      : _writer = VmoWriter.withSize(vmoSize) {
    // TODO(CF-602): Remove this placeholder.
    print('hello inspect!');

    _publish(context);
  }

  /// Publishes the Inspect data to the component's (as provided by its
  /// [context]) out/ directory.
  void _publish(StartupContext context) {
    context.outgoing.debugDir().addNode('root.inspect', _writer.vmoNode);
  }

  /// Placeholder for the upper-level API.
  bool get valid => _writer != null;
}
