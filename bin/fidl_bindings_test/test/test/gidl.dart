// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:fidl/fidl.dart' as fidl;

// ignore: avoid_classes_with_only_static_members
abstract class Encoders {
  static fidl.Encoder get old {
    return fidl.Encoder();
  }

  static fidl.Encoder get v1 {
    return fidl.Encoder()
      ..encodeUnionAsXUnionBytes = true;
  }
}

// ignore: avoid_classes_with_only_static_members
abstract class Decoders {
  static fidl.Decoder get old {
    return fidl.Decoder.fromRawArgs(null, []);
  }

  static fidl.Decoder get v1 {
    return fidl.Decoder.fromRawArgs(null, [])
      ..decodeUnionFromXUnionBytes = true;
  }
}

Uint8List _encode<T>(fidl.Encoder encoder, fidl.FidlType<T> type, T value) {
  encoder.alloc(type.encodingInlineSize(encoder));
  type.encode(encoder, value, 0);
  final message = encoder.message;
  return Uint8List.view(message.data.buffer, 0, message.data.lengthInBytes);
}

T _decode<T>(fidl.Decoder decoder, fidl.FidlType<T> type, Uint8List bytes) {
  decoder
    ..data = ByteData.view(bytes.buffer, 0, bytes.length)
    ..claimMemory(type.decodingInlineSize(decoder));
  return type.decode(decoder, 0);
}

class EncodeSuccessCase<T> {
  EncodeSuccessCase(this.encoder, this.input, this.type, this.bytes);

  final fidl.Encoder encoder;
  final T input;
  final fidl.FidlType<T> type;
  final Uint8List bytes;

  static void run<T>(fidl.Encoder encoder, String name, T input,
      fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      EncodeSuccessCase(encoder, input, type, bytes)._checkEncode();
    });
  }

  void _checkEncode() {
    test('encode', () {
      expect(_encode(encoder, type, input), equals(bytes));
    });
  }
}

class DecodeSuccessCase<T> {
  DecodeSuccessCase(this.decoder, this.input, this.type, this.bytes);

  final fidl.Decoder decoder;
  final T input;
  final fidl.FidlType<T> type;
  final Uint8List bytes;

  static void run<T>(fidl.Decoder decoder, String name, T input,
      fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      DecodeSuccessCase(decoder, input, type, bytes)._checkDecode();
    });
  }

  void _checkDecode() {
    test('decode', () {
      expect(_decode(decoder, type, bytes), equals(input));
    });
  }
}

class EncodeFailureCase<T> {
  EncodeFailureCase(this.encoder, this.input, this.type, this.code);

  final fidl.Encoder encoder;
  final T input;
  final fidl.FidlType<T> type;
  final fidl.FidlErrorCode code;

  static void run<T>(fidl.Encoder encoder, String name, T input,
      fidl.FidlType<T> type, fidl.FidlErrorCode code) {
    group(name, () {
      EncodeFailureCase(encoder, input, type, code)._checkEncodeFails();
    });
  }

  void _checkEncodeFails() {
    test('encode fails', () {
      expect(() => _encode(encoder, type, input),
          throwsA(predicate((e) => e.code == code)));
    });
  }
}

class DecodeFailureCase<T> {
  DecodeFailureCase(this.decoder, this.type, this.bytes, this.code);

  final fidl.Decoder decoder;
  final fidl.FidlType<T> type;
  final Uint8List bytes;
  final fidl.FidlErrorCode code;

  static void run<T>(fidl.Decoder decoder, String name,
      fidl.FidlType<T> type, Uint8List bytes, fidl.FidlErrorCode code) {
    group(name, () {
      DecodeFailureCase(decoder, type, bytes, code)._checkDecodeFails();
    });
  }

  void _checkDecodeFails() {
    test('decode fails', () {
      expect(() => _decode(decoder, type, bytes),
          throwsA(predicate((e) => e is fidl.FidlError && e.code == code)));
    });
  }
}
