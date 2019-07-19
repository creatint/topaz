// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:fidl/fidl.dart' as fidl;

class SuccessCase<T> {
  SuccessCase(this.input, this.type, this.bytes);

  final T input;
  final fidl.FidlType<T> type;
  final Uint8List bytes;

  static void run<T>(
      String name, T input, fidl.FidlType<T> type, Uint8List bytes) {
    group(name, () {
      SuccessCase(input, type, bytes)
        .._checkEncode()
        .._checkDecode();
    });
  }

  void _checkEncode() {
    test('encode', () {
      final fidl.Encoder encoder = fidl.Encoder()..alloc(type.encodedSize);
      type.encode(encoder, input, 0);
      final message = encoder.message;
      expect(Uint8List.view(message.data.buffer, 0, message.dataLength),
          equals(bytes));
    });
  }

  void _checkDecode() {
    test('decode', () {
      final fidl.Decoder decoder = fidl.Decoder(fidl.Message(
          ByteData.view(bytes.buffer, 0, bytes.length), [], bytes.length, 0))
        ..claimMemory(type.encodedSize);
      final actual = type.decode(decoder, 0);
      expect(actual, equals(input));
    });
  }
}

class MarshalFailureCase<T> {
  MarshalFailureCase(this.input, this.type, this.message);

  final T input;
  final fidl.FidlType<T> type;
  final String message;

  static void run<T>(String name, T input, fidl.FidlType<T> type,
      [String message = '']) {
    group(name, () {
      MarshalFailureCase(input, type, message)._checkEncodeFails();
    });
  }

  void _checkEncodeFails() {
    test('encode fails', () {
      final fidl.Encoder encoder = fidl.Encoder()..alloc(type.encodedSize);
      expect(() => type.encode(encoder, input, 0),
          throwsA(predicate((e) => e.message.contains(message))));
    });
  }
}

class UnmarshalFailureCase<T> {
  UnmarshalFailureCase(this.type, this.bytes, this.message);

  final fidl.FidlType<T> type;
  final Uint8List bytes;
  final String message;

  static void run<T>(String name, fidl.FidlType<T> type, Uint8List bytes,
      [String message = '']) {
    group(name, () {
      UnmarshalFailureCase(type, bytes, message)._checkDecodeFails();
    });
  }

  void _checkDecodeFails() {
    test('decode fails', () {
      final fidl.Decoder decoder = fidl.Decoder(fidl.Message(
          ByteData.view(bytes.buffer, 0, bytes.length), [], bytes.length, 0))
        ..claimMemory(type.encodedSize);
      expect(() => type.decode(decoder, 0),
          throwsA(predicate((e) => e.message.contains(message))));
    });
  }
}