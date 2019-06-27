// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:zircon/zircon.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';

import 'pseudo_file.dart';

typedef VmoFn = Vmo Function();

/// A [PseudoVmoFile] is a [VmoFile] typed [PseudoFile] whose content is read
/// from a [Vmo] dynamically produced by a supplied callback.
///
/// Each FIDL connection to a [PseudoVmoFile] calls the supplied callback once
/// and reads the content of the produced [Vmo] into a buffer. Therefore,
/// connection order is important.
///
/// Reads on each connection are seperately buffered.
class PseudoVmoFile extends PseudoFile {
  final VmoFn _vmoFn;

  /// Constructor for read-only [Vmo]
  ///
  /// Throws Exception if _vmoFn or any of its resulting vmos are null.
  PseudoVmoFile.readOnly(this._vmoFn)
      : super.readOnly(() {
          Vmo vmo = _vmoFn();
          if (vmo == null) {
            throw Exception('Vmo cannot be null');
          }

          int size = vmo.getSize().size;
          return vmo.read(size).bytesAsUint8List();
        }) {
    ArgumentError.checkNotNull(_vmoFn, 'Vmo Function');
  }

  /// Describes this node and exposes a duplicate of the underlying Vmo.
  ///
  /// Returns null when vmoFn returns null or duplicate fails.
  ///
  /// The function calls the passed callback.
  @override
  NodeInfo describe() {
    final Vmo originalVmo = _vmoFn();
    final Vmo duplicatedVmo =
        originalVmo?.duplicate(ZX.RIGHTS_BASIC | ZX.RIGHT_READ | ZX.RIGHT_MAP);
    if (duplicatedVmo == null) {
      return null;
    }

    return NodeInfo.withVmofile(Vmofile(
        vmo: duplicatedVmo, offset: 0, length: originalVmo.getSize().size));
  }
}
