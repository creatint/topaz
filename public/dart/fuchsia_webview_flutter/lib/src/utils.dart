// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'package:fidl_fuchsia_mem/fidl_async.dart' as fidl_mem;
import 'package:zircon/zircon.dart';

/// Reads a FIDL VMO buffer into a string.
String bufferToString(fidl_mem.Buffer buffer) {
  final dataVmo = SizedVmo(buffer.vmo.handle, buffer.size);
  final data = dataVmo.read(buffer.size);
  dataVmo.close();
  return utf8.decode(data.bytesAsUint8List());
}
