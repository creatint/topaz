// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:typed_data';

import 'package:fuchsia_inspect/src/vmo_holder.dart';
import 'package:test/test.dart';

class FakeVmo implements VmoHolder {
  /// The memory contents of this "VMO".
  final ByteData bytes;

  /// Size of the "VMO".
  @override
  final int size;

  /// Creates non-shared (ByteData) memory to simulate VMO operations.
  FakeVmo(this.size) : bytes = ByteData(size);

  /// Writes to the "VMO".
  @override
  void write(int offset, ByteData data) {
    bytes.buffer.asUint8List().setAll(offset, data.buffer.asUint8List());
  }

  /// Reads from the "VMO".
  @override
  ByteData read(int offset, int size) {
    return ByteData.view(bytes.buffer, offset, size);
  }

  /// Writes int64 to VMO.
  @override
  void writeInt64(int offset, int value) =>
      bytes.setInt64(offset, value, Endian.little);

  /// Writes int64 directly to VMO for immediate visibility.
  @override
  void writeInt64Direct(int offset, int value) => writeInt64(offset, value);

  /// Reads int64 from VMO.
  @override
  int readInt64(int offset) => bytes.getInt64(offset, Endian.little);
}

/// Returns the ascii code of this character.
int ascii(String char) {
  if (char.length != 1) {
    throw ArgumentError('char must be 1 character long.');
  }
  var code = char.codeUnitAt(0);
  if (code > 127) {
    throw ArgumentError("char wasn't ascii (code $code)");
  }
  return code;
}

/// returns the hex char corresponding to a 0..15 value.
String hexChar(int value) {
  if (value < 0 || value > 15) {
    throw ArgumentError('Bad value $value');
  }
  return value.toRadixString(16);
}

/// Compares contents, starting at [offset], with the hex values in [spec].
///
/// Valid chars in [spec] are:
///   ' ' (ignored completely)
///   _ x X (skips 4 bits)
///   0..9 a..f A..F (hex value of 4 bits)
///
/// [spec] is little-endian, which makes integer values look weird. If you
/// write 0x234 into memory, it'll be matched by '34 02' (or by 'x4_2')
void compare(FakeVmo vmo, int offset, String spec) {
  int nybble = offset * 2;
  for (int i = 0; i < spec.length; i++) {
    int rune = spec.codeUnitAt(i);
    if (rune == ascii(' ')) {
      continue;
    }
    if (rune == ascii('_') || rune == ascii('x') || rune == ascii('X')) {
      nybble++;
      continue;
    }
    int value;
    if (rune >= ascii('0') && rune <= ascii('9')) {
      value = rune - ascii('0');
    } else if (rune >= ascii('a') && rune <= ascii('f')) {
      value = rune - ascii('a') + 10;
    } else if (rune >= ascii('A') && rune <= ascii('F')) {
      value = rune - ascii('A') + 10;
    } else {
      throw ArgumentError('Illegal char "${String.fromCharCode(rune)}"');
    }
    int byte = nybble ~/ 2;
    int dataAtByte = vmo.bytes.getUint8(byte);
    int dataAtNybble = (nybble & 1 == 0) ? dataAtByte >> 4 : dataAtByte & 0xf;
    if (dataAtNybble != value) {
      expect(dataAtNybble, value,
          reason: 'byte[$byte] = ${dataAtByte.toRadixString(16)}. '
              'Nybble $nybble was ${dataAtNybble.toRadixString(16)} '
              'but expected ${value.toRadixString(16)}.');
    }
    nybble++;
  }
}
