// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'package:fidl/fidl.dart';
import 'package:test/test.dart';
import 'package:fidl_fidl_examples_bindingstest/fidl_async.dart';
import 'package:zircon/zircon.dart';

// TODO(fxb/8047) test this in gidl
void main() async {
  group('encode/decode', () {
    test('unknown ordinal flexible', () async {
      final xunion = ExampleXunion.withBar(0x01020304);
      var encoder = Encoder()..alloc(24);
      kExampleXunion_Type.encode(encoder, xunion, 0);

      // overwrite the ordinal to be unknown
      encoder.encodeUint64(0x1234, 0);

      final decoder = Decoder(encoder.message)..claimMemory(24);
      ExampleXunion unknownXunion = kExampleXunion_Type.decode(decoder, 0);
      UnknownRawData actual = unknownXunion.$data;
      // there are 4 additional bytes of padding for the uint32
      final expected =
          UnknownRawData(Uint8List.fromList([4, 3, 2, 1, 0, 0, 0, 0]), []);
      expect(actual.data, equals(expected.data));
      expect(actual.handles, equals(expected.handles));

      encoder = Encoder()..alloc(24);
      kExampleXunion_Type.encode(encoder, unknownXunion, 0);
      expect(encoder.message.data.lengthInBytes, 32);
      final bytes = encoder.message.data.buffer.asUint8List(0, 32);
      expect(
          bytes,
          equals([
            0x34, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // ordinal + padding
            0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // num bytes/handles
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // PRESENT
            0x04, 0x03, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, // data + padding
          ]));
      expect(encoder.message.handles.length, 0);
    });

    test('unknown ordinal flexible with handles', () async {
      ChannelPair pair = ChannelPair();
      expect(pair.status, equals(ZX.OK));
      pair.second.close();

      final xunion = ExampleXunion.withWithHandle(
          NumberHandleNumber(n1: 1, h: pair.first.handle, n2: 2));
      var encoder = Encoder()..alloc(24);
      kExampleXunion_Type.encode(encoder, xunion, 0);

      // overwrite the ordinal to be unknown
      encoder.encodeUint64(0x1234, 0);

      final decoder = Decoder(encoder.message)..claimMemory(24);
      ExampleXunion unknownXunion = kExampleXunion_Type.decode(decoder, 0);
      UnknownRawData actual = unknownXunion.$data;
      final expectedData = Uint8List.fromList([
        0x01, 0x00, 0x00, 0x00, // n1
        0xFF, 0xFF, 0xFF, 0xFF, // kHandlePresent
        0x02, 0x00, 0x00, 0x00, // n2
        0x00, 0x00, 0x00, 0x00, // padding
      ]);
      expect(actual.data, equals(expectedData));
      expect(actual.handles.length, equals(1));

      encoder = Encoder()..alloc(24);
      kExampleXunion_Type.encode(encoder, unknownXunion, 0);
      expect(encoder.message.data.lengthInBytes, 40);
      final bytes = encoder.message.data.buffer.asUint8List(0, 40);
      expect(
          bytes,
          equals([
            0x34, 0x12, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // ordinal + padding
            0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, // num bytes/handles
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // PRESENT
            0x01, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, // n1 + h
            0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // n2 + paddding
          ]));
      expect(encoder.message.handles.length, equals(1));
      encoder.message.handles[0].close();
    });

    test('unknown ordinal strict', () async {
      final xunion = ExampleStrictXunion.withBar(15);
      final encoder = Encoder()..alloc(24);
      kExampleStrictXunion_Type.encode(encoder, xunion, 0);

      // overwrite the ordinal to be unknown
      encoder.encodeUint64(12345, 0);

      final decoder = Decoder(encoder.message)..claimMemory(24);
      expect(
          () => kExampleStrictXunion_Type.decode(decoder, 0),
          throwsA(predicate((e) =>
              e is FidlError &&
              e.code == FidlErrorCode.fidlStrictXUnionUnknownField)));
    });
  });

  test('xunion both ordinals', () async {
    // xunion can be decoded using both sets of ordinals
    final hashedBytes = Uint8List.fromList([
      0x9e, 0xb1, 0x27, 0x72, 0x00, 0x00, 0x00, 0x00, // hashed ordinal
      0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // num bytes/handles
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // PRESENT
      0x04, 0x03, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, // data + padding
    ]);
    var decoder = Decoder(Message(ByteData.view(hashedBytes.buffer), []))
      ..claimMemory(24);
    ExampleXunion hashedXunion = kExampleXunion_Type.decode(decoder, 0);
    expect(hashedXunion.$data, 0x01020304);

    final explicitBytes = Uint8List.fromList([
      0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // explicit ordinal
      0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // num bytes/handles
      0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, // PRESENT
      0x04, 0x03, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, // data + padding
    ]);
    decoder = Decoder(Message(ByteData.view(explicitBytes.buffer), []))
      ..claimMemory(24);
    ExampleXunion explicitXunion = kExampleXunion_Type.decode(decoder, 0);
    expect(explicitXunion.$data, 0x01020304);

    // xunion only uses ordinals provided as keys to the members field when
    // encoding
    var encoder = Encoder()..alloc(24);
    kExampleXunion_Type.encode(encoder, hashedXunion, 0);
    expect(encoder.message.data.lengthInBytes, 32);
    expect(
        encoder.message.data.buffer.asUint8List(0, 32), equals(explicitBytes));

    encoder = Encoder()..alloc(24);
    kExampleXunion_Type.encode(encoder, explicitXunion, 0);
    expect(encoder.message.data.lengthInBytes, 32);
    expect(
        encoder.message.data.buffer.asUint8List(0, 32), equals(explicitBytes));
  });
}
