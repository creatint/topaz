// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:io';
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

  @override
  void beginWork() {}

  @override
  void commit() {}

  /// Writes to the "VMO".
  @override
  void write(int offset, ByteData data) {
    bytes.buffer.asUint8List().setAll(offset,
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

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

/// Writes block contents in hexadecimal, nicely formatted, to stdout.
///
/// This is very useful in debugging, so I'll leave it in although it's not
/// used in testing.
void dumpBlocks(FakeVmo vmo, {int startIndex = 0, int howMany32 = -1}) {
  int lastIndex = (howMany32 == -1)
      ? (vmo.bytes.lengthInBytes >> 4) - 1
      : startIndex + howMany32 - 1;
  stdout.writeln('Dumping blocks from $startIndex through $lastIndex');
  for (int index = startIndex; index <= lastIndex;) {
    String lowNybble(int offset) => hexChar(vmo.bytes.getUint8(offset) & 15);
    String highNybble(int offset) => hexChar(vmo.bytes.getUint8(offset) >> 4);
    stdout.write('${(index * 16).toRadixString(16).padLeft(3, '0')}: ');
    for (int byte = 0; byte < 8; byte++) {
      stdout
        ..write('${lowNybble(index * 16 + byte)} ')
        ..write('${highNybble(index * 16 + byte)} ');
    }
    int order = vmo.bytes.getUint8(index * 16) & 0xf;
    int numWords = 1 << (order + 1);
    String byteToHex(int offset) =>
        vmo.bytes.getUint8(offset).toRadixString(16).padLeft(2, '0');
    for (int word = 1; word < numWords; word++) {
      stdout.write('  ');
      for (int byte = 0; byte < 8; byte++) {
        stdout.write('${byteToHex(index * 16 + word * 8 + byte)} ');
      }
    }
    index += 1 << order;
    stdout.writeln('');
  }
}