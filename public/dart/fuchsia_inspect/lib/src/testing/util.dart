// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:typed_data';

import 'package:zircon/zircon.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_holder.dart';

/// A VmoHolder that simply wraps some ByteData.
class FakeVmoHolder implements VmoHolder {
  /// The memory contents of this "VMO".
  final ByteData bytes;

  @override
  Vmo get vmo => null;

  /// Size of the "VMO".
  @override
  final int size;

  /// Wraps a [FakeVmoHolder] around the given data.
  FakeVmoHolder.usingData(this.bytes) : size = bytes.lengthInBytes;

  @override
  void beginWork() {}

  @override
  void commit() {}

  /// Writes to the "VMO".
  @override
  void write(int offset, ByteData data) {}

  /// Reads from the "VMO".
  @override
  ByteData read(int offset, int size) {
    var reading = ByteData(size);
    reading.buffer
        .asUint8List()
        .setAll(0, bytes.buffer.asUint8List(offset, size));
    return reading;
  }

  /// Writes int64 to VMO.
  @override
  void writeInt64(int offset, int value) {}

  /// Writes int64 directly to VMO for immediate visibility.
  @override
  void writeInt64Direct(int offset, int value) {}

  /// Reads int64 from VMO.
  @override
  int readInt64(int offset) => bytes.getInt64(offset, Endian.little);
}
