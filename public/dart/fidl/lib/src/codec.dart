// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:zircon/zircon.dart';

import 'error.dart';
import 'message.dart';

// ignore_for_file: always_specify_types
// ignore_for_file: avoid_positional_boolean_parameters
// ignore_for_file: public_member_api_docs

// Switches default union encoding from legacy union bytes to xunion
// bytes -- this value is referenced by the generated bindings only.
// This is part of the union to xunion migration.
bool defaultEnableWriteXUnionBytesForUnion = true;

const int _kAlignment = 8;
const int _kAlignmentMask = 0x7;

const int _kUnionAsXUnionFlag = 1;

int _align(int size) =>
    size + ((_kAlignment - (size & _kAlignmentMask)) & _kAlignmentMask);

void _throwIfNegative(int value) {
  if (value < 0) {
    throw FidlError(
        'Cannot encode a negative value for an unsigned type: $value');
  }
}

bool _hasUnionAsXUnionFlag(ByteData data) {
  assert(data.buffer.lengthInBytes > kMessageFlagOffset);
  return (data.getUint8(kMessageFlagOffset) & _kUnionAsXUnionFlag) != 0;
}

const int _kInitialBufferSize = 1024;

class Encoder {
  Encoder({@required this.encodeUnionAsXUnionBytes});

  Message get message {
    final ByteData trimmed = ByteData.view(data.buffer, 0, _extent);
    return Message(trimmed, _handles);
  }

  ByteData data = ByteData(_kInitialBufferSize);
  final List<Handle> _handles = <Handle>[];
  int _extent = 0;

  // Indicates whether unions should be encoded as xunion. When `true`, unions
  // are encoded as xunions (v1). When `false`, unions are encoded as
  // static-unions (old).
  final bool encodeUnionAsXUnionBytes;

  void _grow(int newSize) {
    final Uint8List newList = Uint8List(newSize)
      ..setRange(0, data.lengthInBytes, data.buffer.asUint8List());
    data = newList.buffer.asByteData();
  }

  void _claimMemory(int claimSize) {
    _extent += claimSize;
    if (_extent > data.lengthInBytes) {
      int newSize = data.lengthInBytes + claimSize;
      newSize += newSize >> 1;
      _grow(newSize);
    }
  }

  int alloc(int size) {
    int offset = _extent;
    _claimMemory(_align(size));
    return offset;
  }

  int nextOffset() {
    return _extent;
  }

  int countHandles() {
    return _handles.length;
  }

  void addHandle(Handle value) {
    _handles.add(value);
  }

  void encodeMessageHeader(int ordinal, int txid) {
    alloc(kMessageHeaderSize);
    encodeUint32(txid, kMessageTxidOffset);
    if (encodeUnionAsXUnionBytes) {
      encodeUint8(_kUnionAsXUnionFlag, kMessageFlagOffset);
    } else {
      encodeUint8(0, kMessageFlagOffset);
    }
    encodeUint8(0, kMessageFlagOffset + 1);
    encodeUint8(0, kMessageFlagOffset + 2);
    encodeUint8(kMagicNumberInitial, kMessageMagicOffset);
    encodeUint64(ordinal, kMessageOrdinalOffset);
  }

  void encodeBool(bool value, int offset) {
    data.setInt8(offset, value ? 1 : 0);
  }

  void encodeInt8(int value, int offset) {
    data.setInt8(offset, value);
  }

  void encodeUint8(int value, int offset) {
    _throwIfNegative(value);
    data.setUint8(offset, value);
  }

  void encodeInt16(int value, int offset) {
    data.setInt16(offset, value, Endian.little);
  }

  void encodeUint16(int value, int offset) {
    _throwIfNegative(value);
    data.setUint16(offset, value, Endian.little);
  }

  void encodeInt32(int value, int offset) {
    data.setInt32(offset, value, Endian.little);
  }

  void encodeUint32(int value, int offset) {
    _throwIfNegative(value);
    data.setUint32(offset, value, Endian.little);
  }

  void encodeInt64(int value, int offset) {
    data.setInt64(offset, value, Endian.little);
  }

  void encodeUint64(int value, int offset) {
    data.setUint64(offset, value, Endian.little);
  }

  void encodeFloat32(double value, int offset) {
    data.setFloat32(offset, value, Endian.little);
  }

  void encodeFloat64(double value, int offset) {
    data.setFloat64(offset, value, Endian.little);
  }
}

class Decoder {
  Decoder(Message message)
      : data = message.data,
        handles = message.handles,
        decodeUnionFromXUnionBytes = _hasUnionAsXUnionFlag(message.data);

  Decoder.fromRawArgs(this.data, this.handles, this.decodeUnionFromXUnionBytes);

  ByteData data;
  List<Handle> handles;

  int _nextOffset = 0;
  int _nextHandle = 0;
  // True if a given union should be decoded from xunion bytes
  // false if it should be decoded from legacy union bytes
  bool decodeUnionFromXUnionBytes = false;

  int nextOffset() {
    return _nextOffset;
  }

  int claimMemory(int size) {
    final int result = _nextOffset;
    _nextOffset += _align(size);
    if (_nextOffset > data.lengthInBytes) {
      throw FidlError('Cannot access out of range memory');
    }
    return result;
  }

  int countClaimedHandles() {
    return _nextHandle;
  }

  Handle claimHandle() {
    if (_nextHandle >= handles.length) {
      throw FidlError('Cannot access out of range handle');
    }
    return handles[_nextHandle++];
  }

  bool decodeBool(int offset) => data.getInt8(offset) != 0;

  int decodeInt8(int offset) => data.getInt8(offset);

  int decodeUint8(int offset) => data.getUint8(offset);

  int decodeInt16(int offset) => data.getInt16(offset, Endian.little);

  int decodeUint16(int offset) => data.getUint16(offset, Endian.little);

  int decodeInt32(int offset) => data.getInt32(offset, Endian.little);

  int decodeUint32(int offset) => data.getUint32(offset, Endian.little);

  int decodeInt64(int offset) => data.getInt64(offset, Endian.little);

  int decodeUint64(int offset) => data.getUint64(offset, Endian.little);

  double decodeFloat32(int offset) => data.getFloat32(offset, Endian.little);

  double decodeFloat64(int offset) => data.getFloat64(offset, Endian.little);
}
