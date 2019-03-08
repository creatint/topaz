// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:typed_data';

import 'package:fuchsia_inspect/src/block.dart';
import 'package:fuchsia_inspect/src/vmo_fields.dart';
import 'package:fuchsia_inspect/src/vmo_holder.dart';
import 'package:test/test.dart';

void main() {
  group('Block', () {
    test('accepts state (type) correctly', () {
      _accepts('lock/unlock', [BlockType.header], (block) {
        block.lock();
        block.unlock();
      });
      _accepts(
          'becomeRoot', [BlockType.reserved], (block) => block.becomeRoot());
      _accepts(
          'becomeNode', [BlockType.anyValue], (block) => block.becomeNode());
      _accepts('becomeProperty', [BlockType.anyValue],
          (block) => block.becomeProperty());
      _accepts('setChildren', [BlockType.nodeValue, BlockType.tombstone],
          (block) => block.childCount = 0);
      _accepts('getChildren', [BlockType.nodeValue, BlockType.tombstone],
          (block) => block.childCount);

      _accepts('setPropertyTotalLength', [BlockType.propertyValue],
          (block) => block.propertyTotalLength = 0);
      _accepts('getPropertyTotalLength', [BlockType.propertyValue],
          (block) => block.propertyTotalLength);
      _accepts('setPropertyExtentIndex', [BlockType.propertyValue],
          (block) => block.propertyExtentIndex = 0);
      _accepts('getPropertyExtentIndex', [BlockType.propertyValue],
          (block) => block.propertyExtentIndex);
      _accepts('setPropertyFlags', [BlockType.propertyValue],
          (block) => block.propertyFlags = 0);
      _accepts('getPropertyFlags', [BlockType.propertyValue],
          (block) => block.propertyFlags);

      _accepts('becomeTombstone', [BlockType.nodeValue],
          (block) => block.becomeTombstone());
      _accepts('becomeReserved', [BlockType.free],
          (block) => block.becomeReserved());
      _accepts('nextFree', [BlockType.free], (block) => block.nextFree);
      _accepts('becomeValue', [BlockType.reserved],
          (block) => block.becomeValue(nameIndex: 1, parentIndex: 2));
      _accepts(
          'nameIndex',
          [
            BlockType.nodeValue,
            BlockType.anyValue,
            BlockType.propertyValue,
            BlockType.intValue,
            BlockType.doubleValue
          ],
          (block) => block.nameIndex);
      _accepts(
          'parentIndex',
          [
            BlockType.nodeValue,
            BlockType.anyValue,
            BlockType.propertyValue,
            BlockType.intValue,
            BlockType.doubleValue
          ],
          (block) => block.parentIndex);
      _accepts('becomeDoubleMetric', [BlockType.anyValue],
          (block) => block.becomeDoubleMetric(0.0));
      _accepts('becomeIntMetric', [BlockType.anyValue],
          (block) => block.becomeIntMetric(0));
      _accepts('intValueGet', [BlockType.intValue], (block) => block.intValue);
      _accepts(
          'intValueSet', [BlockType.intValue], (block) => block.intValue = 0);
      _accepts('doubleValueGet', [BlockType.doubleValue],
          (block) => block.doubleValue);
      _accepts('doubleValueSet', [BlockType.doubleValue],
          (block) => block.doubleValue = 0.0);
      _accepts('becomeName', [BlockType.reserved],
          (block) => block.becomeName('foo'));
      _accepts('extentIndexSet', [BlockType.propertyValue],
          (block) => block.propertyExtentIndex = 0);
      _accepts(
          'nextExtentGet', [BlockType.extent], (block) => block.nextExtent);
    });

    test('can read, including payload bits', () {
      var vmo = FakeVmo(32);
      vmo.bytes
        ..setUint8(0, 0x01 | (BlockType.propertyValue.value << 4))
        ..setUint8(1, 0x14) // Parent index should be 0x14
        ..setUint8(4, 0x20) // Name index should be 0x32. 4..7 bits of
        ..setUint8(5, 0x03) //   byte 4 + (0..3 bits of byte 5) << 4
        ..setUint8(8, 0x7f) // Length should be 0x7f
        ..setUint8(12, 0x0a) // Extent
        ..setUint8(15, 0xb0); // Flags 0xb
      _compare(
          vmo.bytes,
          0,
          '${_hexChar(BlockType.propertyValue.value)} 1'
          '14 00 00  20 03 00 00  7f00 0000 0a00 00b0');
      var block = Block.read(vmo, 0);
      expect(block.size, 32);
      expect(block.type.value, BlockType.propertyValue.value);
      expect(block.parentIndex, 0x14);
      expect(block.nameIndex, 0x32);
      expect(block.propertyTotalLength, 0x7f);
      expect(block.propertyExtentIndex, 0xa);
      expect(block.propertyFlags, 0xb);
    });

    test('can read, including payload bytes', () {
      var vmo = FakeVmo(32);
      vmo.bytes
        ..setUint8(0, 0x01 | (BlockType.nameUtf8.value << 4))
        ..setUint8(1, 0x02) // Set length to 2
        ..setUint8(8, 0x41) // 'a'
        ..setUint8(9, 0x42); // 'b'
      _compare(
          vmo.bytes,
          0,
          '${_hexChar(BlockType.nameUtf8.value)} 1'
          '02 00 00 0000 0000  4142 0000 0000 0000 0000');
      var block = Block.read(vmo, 0);
      expect(block.size, 32);
      expect(block.type.value, BlockType.nameUtf8.value);
      expect(block.payloadBytes.getUint8(0), 0x41);
      expect(block.payloadBytes.getUint8(1), 0x42);
    });
  });

  group('Block operations write to VMO correctly:', () {
    test('Creating, locking, and unlocking the VMO header', () {
      var vmo = FakeVmo(32);
      var block = Block.create(vmo, 0)..becomeHeader();
      _compare(
          vmo.bytes,
          0,
          '${_hexChar(BlockType.header.value)} 0'
          '00 0000 49 4E 53 50  0000 0000 0000 0000');
      block.lock();
      _compare(
          vmo.bytes,
          0,
          '${_hexChar(BlockType.header.value)} 0'
          '00 0000 49 4E 53 50  0100 0000 0000 0000');
      block.unlock();
      _compare(
          vmo.bytes,
          0,
          '${_hexChar(BlockType.header.value)} 0'
          '00 0000 49 4E 53 50  0200 0000 0000 0000');
    });

    test('Becoming the special root node', () {
      var vmo = FakeVmo(64);
      Block.create(vmo, 1).becomeRoot();
      _compare(vmo.bytes, 16,
          '${_hexChar(BlockType.nodeValue.value)} 0 00 0000 2000 0000 0000');
    });

    test('Becoming and modifying an intValue via free, reserved, anyValue', () {
      var vmo = FakeVmo(64);
      var block = Block.create(vmo, 2)..becomeFree(5);
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.free.value)} 1 05 00 00 0000 0000');
      expect(block.nextFree, 5);
      block.becomeReserved();
      _compare(vmo.bytes, 32, '${_hexChar(BlockType.reserved.value)} 1');
      block.becomeValue(parentIndex: 0xbc, nameIndex: 0x7d);
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.anyValue.value)} 1 bc 00 00 d0 07 00 00');
      block.becomeIntMetric(0xbeef);
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.intValue.value)} 1 bc 00 00 d0 07 00 00 efbe');
      block.intValue += 1;
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.intValue.value)} 1 bc 00 00 d0 07 00 00 f0be');
    });

    test('Becoming a nodeValue and then a tombstone', () {
      var vmo = FakeVmo(64);
      var block = Block.create(vmo, 2)
        ..becomeFree(5)
        ..becomeReserved()
        ..becomeValue(parentIndex: 0xbc, nameIndex: 0x7d)
        ..becomeNode();
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.nodeValue.value)} 1 bc 00 00 d0 07 00 00 0000');
      block.childCount += 1;
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.nodeValue.value)} 1 bc 00 00 d0 07 00 00 0100');
      block.becomeTombstone();
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.tombstone.value)} 1 bc 00 00 d0 07 00 00 0100');
    });

    test('Becoming and modifying doubleValue', () {
      var vmo = FakeVmo(64);
      var block = Block.create(vmo, 2)
        ..becomeFree(5)
        ..becomeReserved()
        ..becomeValue(parentIndex: 0xbc, nameIndex: 0x7d)
        ..becomeDoubleMetric(1.0);
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.doubleValue.value)} 1 bc 00 00 d0 07 00 00 ');
      expect(vmo.bytes.getFloat64(40, Endian.little), 1.0);
      block.doubleValue++;
      expect(vmo.bytes.getFloat64(40, Endian.little), 2.0);
    });

    test('Becoming and modifying a propertyValue', () {
      var vmo = FakeVmo(64);
      var block = Block.create(vmo, 2)
        ..becomeFree(5)
        ..becomeReserved()
        ..becomeValue(parentIndex: 0xbc, nameIndex: 0x7d)
        ..becomeProperty();
      _compare(
          vmo.bytes,
          32,
          '${_hexChar(BlockType.propertyValue.value)} 1 bc 00 00 d0 07 00 00 '
          '00 00 00 00  00 00 00 00');
      block
        ..propertyExtentIndex = 0x35
        ..propertyTotalLength = 0x17b
        ..propertyFlags = 0xa;
      _compare(
          vmo.bytes,
          32,
          '${_hexChar(BlockType.propertyValue.value)} 1 bc 00 00 d0 07 00 00 '
          '7b 01 00 00  35 00 00 a0');
      expect(block.propertyTotalLength, 0x17b);
      expect(block.propertyExtentIndex, 0x35);
      expect(block.propertyFlags, 0xa);
    });

    test('Becoming a name', () {
      var vmo = FakeVmo(64);
      Block.create(vmo, 2).becomeName('abc');
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.nameUtf8.value)} 1 03 0000 0000 0000 61 62 63');
    });

    test('Becoming and setting an extent', () {
      var vmo = FakeVmo(64);
      var block = Block.create(vmo, 2)
        ..becomeFree(4)
        ..becomeReserved()
        ..becomeExtent(0x42)
        ..setExtentPayload(Block.stringToByteData('abc'));
      _compare(vmo.bytes, 32,
          '${_hexChar(BlockType.extent.value)} 1 42 0000 0000 0000 61 62 63');
      expect(block.nextExtent, 0x42);
      expect(block.payloadSpaceBytes, block.size - headerSizeBytes);
    });
  });
}

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

/// Verify which block types are accepted by which functions.
///
/// For all block types (including anyValue), creates a block of that type and
///  passes it to [testFunction].
/// [previousStates] contains the types that should not throw
/// an error. All others should throw.
void _accepts(String testName, List<BlockType> previousStates, testFunction) {
  var vmo = FakeVmo(4096);
  for (BlockType type in BlockType.values) {
    var block = Block.createWithType(vmo, 0, type);
    if (previousStates.contains(type)) {
      expect(() => testFunction(block), returnsNormally,
          reason: '$testName should have accepted type $type');
    } else {
      expect(() => testFunction(block), throwsA(anything),
          reason: '$testName should not accept type $type');
    }
  }
}

int _ascii(String char) => char.codeUnitAt(0);

String _hexChar(int value) {
  if (value < 0 || value > 15) {
    throw ArgumentError('Bad value $value');
  }
  if (value < 10) {
    return String.fromCharCode(value + _ascii('0'));
  } else {
    return String.fromCharCode(value - 10 + _ascii('a'));
  }
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
void _compare(ByteData data, int offset, String spec) {
  int nybble = offset * 2;
  for (int i = 0; i < spec.length; i++) {
    int rune = spec.codeUnitAt(i);
    if (rune == _ascii(' ')) {
      continue;
    }
    if (rune == _ascii('_') || rune == _ascii('x') || rune == _ascii('X')) {
      nybble++;
      continue;
    }
    int value;
    if (rune >= _ascii('0') && rune <= _ascii('9')) {
      value = rune - _ascii('0');
    } else if (rune >= _ascii('a') && rune <= _ascii('f')) {
      value = rune - _ascii('a') + 10;
    } else if (rune >= _ascii('A') && rune <= _ascii('F')) {
      value = rune - _ascii('A') + 10;
    } else {
      throw ArgumentError('Illegal char "${String.fromCharCode(rune)}"');
    }
    int byte = nybble ~/ 2;
    int dataAtByte = data.getUint8(byte);
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
