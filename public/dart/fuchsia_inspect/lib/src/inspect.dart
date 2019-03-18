// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'vmo_writer.dart';

const int _defaultVmoSizeBytes = 256 * 1024;

/// Inspect exposes a structured tree of internal component state in a VMO.
class Inspect {
  final VmoWriter _vmo;

  /// Initialize the VMO with given or default size.
  Inspect([int vmoSize = _defaultVmoSizeBytes])
      : _vmo = VmoWriter.withSize(vmoSize) {
    // TODO(CF-602): Remove this placeholder.
    print('hello inspect!');
  }

  /// Placeholder for the upper-level API.
  bool get valid => _vmo != null;
}
