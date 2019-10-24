// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:fidl/fidl.dart' as fidl;

abstract class Encoding {
  Uint8List encode<T>(fidl.FidlType<T> type, T input);
  T decode<T>(fidl.FidlType<T> type, Uint8List bytes);
}

class EncodingOld extends Encoding {
  @override
  Uint8List encode<T>(fidl.FidlType<T> type, T input) {
    final fidl.Encoder encoder = fidl.Encoder()
      ..alloc(type.encodingInlineSize());
    type.encode(encoder, input, 0);
    final message = encoder.message;
    return Uint8List.view(message.data.buffer, 0, message.dataLength);
  }

  @override
  T decode<T>(fidl.FidlType<T> type, Uint8List bytes) {
    final fidl.Decoder decoder = fidl.Decoder(fidl.Message(
        ByteData.view(bytes.buffer, 0, bytes.length), [], bytes.length, 0));
    decoder.claimMemory(type.decodingInlineSize(decoder));
    return type.decode(decoder, 0);
  }
}

class SuccessCase<T, E extends Encoding> {
  static void run<T, E extends Encoding>(E encoding, String name, T input,
      fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      EncodeSuccessCase(encoding, input, type, bytes)._checkEncode();
      DecodeSuccessCase(encoding, input, type, bytes)._checkDecode();
    });
  }
}

class EncodeSuccessCase<T, E extends Encoding> {
  EncodeSuccessCase(this.encoding, this.input, this.type, this.bytes);

  final E encoding;
  final T input;
  final fidl.FidlType<T> type;
  final Uint8List bytes;

  static void run<T, E extends Encoding>(E encoding, String name, T input,
      fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      EncodeSuccessCase(encoding, input, type, bytes)._checkEncode();
    });
  }

  void _checkEncode() {
    test('encode', () {
      expect(encoding.encode(type, input), equals(bytes));
    });
  }
}

class DecodeSuccessCase<T, E extends Encoding> {
  DecodeSuccessCase(this.encoding, this.input, this.type, this.bytes);

  final E encoding;
  final T input;
  final fidl.FidlType<T> type;
  final Uint8List bytes;

  static void run<T, E extends Encoding>(E encoding, String name, T input,
      fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      DecodeSuccessCase(encoding, input, type, bytes)._checkDecode();
    });
  }

  void _checkDecode() {
    test('decode', () {
      expect(encoding.decode(type, bytes), equals(input));
    });
  }
}

class EncodeFailureCase<T, E extends Encoding> {
  EncodeFailureCase(this.encoding, this.input, this.type, this.code);

  final E encoding;
  final T input;
  final fidl.FidlType<T> type;
  final fidl.FidlErrorCode code;

  static void run<T, E extends Encoding>(E encoding, String name, T input,
      fidl.FidlType<T> type, fidl.FidlErrorCode code) {
    group(name, () {
      EncodeFailureCase(encoding, input, type, code)._checkEncodeFails();
    });
  }

  void _checkEncodeFails() {
    test('encode fails', () {
      expect(() => encoding.encode(type, input),
          throwsA(predicate((e) => e.code == code)));
    });
  }
}

class DecodeFailureCase<T, E extends Encoding> {
  DecodeFailureCase(this.encoding, this.type, this.bytes, this.code);

  final E encoding;
  final fidl.FidlType<T> type;
  final Uint8List bytes;
  final fidl.FidlErrorCode code;

  static void run<T, E extends Encoding>(E encoding, String name,
      fidl.FidlType<T> type, Uint8List bytes, fidl.FidlErrorCode code) {
    group(name, () {
      DecodeFailureCase(encoding, type, bytes, code)._checkDecodeFails();
    });
  }

  void _checkDecodeFails() {
    test('decode fails', () {
      expect(() => encoding.decode(type, bytes),
          throwsA(predicate((e) => e is fidl.FidlError && e.code == code)));
    });
  }
}
