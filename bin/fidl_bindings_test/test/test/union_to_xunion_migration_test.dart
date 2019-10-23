// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:fidl/fidl.dart' as $fidl;

void main() {
  group('union to xunion migration', () {
    test('decode xunion bytes into union', () {
      int inputValue = 5;

      var encoder = $fidl.Encoder()..alloc(24);

      var xunion = XUnion.withPrimitive(inputValue);
      kXUnion_Type.encode(encoder, xunion, 0);

      var decoder = DecoderThatDecodesUnionsFromXunions(encoder.message)
        ..claimMemory(24);
      var union = kUnion_Type.decode(decoder, 0);
      expect(union.primitive, equals(inputValue));
    });

    test('encode xunion bytes from union', () {
      $fidl.enableWriteXUnionBytesForUnion = true;
      int inputValue = 5;

      var xunionEncoder = $fidl.Encoder()..alloc(24);
      var xunion = XUnion.withPrimitive(inputValue);
      kXUnion_Type.encode(xunionEncoder, xunion, 0);

      var unionEncoder = $fidl.Encoder()..alloc(24);
      var union = Union.withPrimitive(inputValue);
      kUnion_Type.encode(unionEncoder, union, 0);

      final unionBytes = unionEncoder.message.data.buffer.asUint8List();
      final xunionBytes = xunionEncoder.message.data.buffer.asUint8List();
      expect(unionBytes.length, equals(xunionBytes.length));
      for (int i = 0; i < unionBytes.length; i++) {
        expect(unionBytes[i], equals(xunionBytes[i]));
      }
      $fidl.enableWriteXUnionBytesForUnion = false;
    });
  });
}

class DecoderThatDecodesUnionsFromXunions extends $fidl.Decoder {
  DecoderThatDecodesUnionsFromXunions($fidl.Message message) : super(message);

  @override
  bool decodeUnionFromXUnionBytes() => true;
}

// Generated code modified to keep ordinals the same:

enum UnionTag {
  primitive,
  stringNeedsConstructor,
  vectorStringAlsoNeedsConstructor,
}

class Union extends $fidl.Union {
  const Union.withPrimitive(int value)
      : _data = value,
        _tag = UnionTag.primitive;

  const Union.withStringNeedsConstructor(String value)
      : _data = value,
        _tag = UnionTag.stringNeedsConstructor;

  const Union.withVectorStringAlsoNeedsConstructor(List<String> value)
      : _data = value,
        _tag = UnionTag.vectorStringAlsoNeedsConstructor;

  Union._(UnionTag tag, Object data)
      : _tag = tag,
        _data = data;

  final UnionTag _tag;
  final dynamic _data;
  int get primitive {
    if (_tag != UnionTag.primitive) {
      //ignore: avoid_returning_null
      return null;
    }
    return _data;
  }

  String get stringNeedsConstructor {
    if (_tag != UnionTag.stringNeedsConstructor) {
      return null;
    }
    return _data;
  }

  List<String> get vectorStringAlsoNeedsConstructor {
    if (_tag != UnionTag.vectorStringAlsoNeedsConstructor) {
      return null;
    }
    return _data;
  }

  @override
  String toString() {
    switch (_tag) {
      case UnionTag.primitive:
        return r'Union.primitive($primitive)';
      case UnionTag.stringNeedsConstructor:
        return r'Union.stringNeedsConstructor($stringNeedsConstructor)';
      case UnionTag.vectorStringAlsoNeedsConstructor:
        return r'Union.vectorStringAlsoNeedsConstructor($vectorStringAlsoNeedsConstructor)';
      default:
        return null;
    }
  }

  UnionTag get $tag => _tag;

  @override
  int get $index => _tag.index;

  @override
  Object get $data => _data;

  //ignore: prefer_constructors_over_static_methods
  static Union _ctor(int index, Object data) {
    return Union._(UnionTag.values[index], data);
  }
}

// See FIDL-308:
// ignore: recursive_compile_time_constant
// ignore: constant_identifier_names
const $fidl.UnionType<Union> kUnion_Type = $fidl.UnionType<Union>(
  inlineSizeOld: 24,
  inlineSizeV1NoEE: 24,
  members: <$fidl.MemberType>[
    $fidl.MemberType<int>(
        type: $fidl.Int32Type(), offsetOld: 8, offsetV1NoEE: 8),
    $fidl.MemberType<String>(
        type: $fidl.StringType(maybeElementCount: null, nullable: false),
        offsetOld: 8,
        offsetV1NoEE: 8),
    $fidl.MemberType<List<String>>(
        type: $fidl.VectorType<List<String>>(
            element: $fidl.StringType(maybeElementCount: null, nullable: false),
            maybeElementCount: null,
            nullable: false),
        offsetOld: 8,
        offsetV1NoEE: 8),
  ],
  ctor: Union._ctor,
  ordinalToIndex: <int, int>{
    910042901: 0,
    891204917: 1,
    1452916587: 2,
  },
);

enum XUnionTag {
  primitive,
  stringNeedsConstructor,
  vectorStringAlsoNeedsConstructor,
}

// ignore: constant_identifier_names
const Map<int, XUnionTag> _XUnionTag_map = {
  910042901: XUnionTag.primitive,
  891204917: XUnionTag.stringNeedsConstructor,
  1452916587: XUnionTag.vectorStringAlsoNeedsConstructor,
};

class XUnion extends $fidl.XUnion {
  const XUnion.withPrimitive(int value)
      : _ordinal = 910042901,
        _data = value;

  const XUnion.withStringNeedsConstructor(String value)
      : _ordinal = 891204917,
        _data = value;

  const XUnion.withVectorStringAlsoNeedsConstructor(List<String> value)
      : _ordinal = 1452916587,
        _data = value;

  XUnion._(int ordinal, Object data)
      : _ordinal = ordinal,
        _data = data;

  final int _ordinal;
  final dynamic _data;

  XUnionTag get $tag => _XUnionTag_map[_ordinal];

  int get primitive {
    if (_ordinal != 910042901) {
      //ignore: avoid_returning_null
      return null;
    }
    return _data;
  }

  String get stringNeedsConstructor {
    if (_ordinal != 891204917) {
      return null;
    }
    return _data;
  }

  List<String> get vectorStringAlsoNeedsConstructor {
    if (_ordinal != 1452916587) {
      return null;
    }
    return _data;
  }

  @override
  String toString() {
    switch (_ordinal) {
      case 910042901:
        return 'XUnion.primitive($primitive)';
      case 891204917:
        return 'XUnion.stringNeedsConstructor($stringNeedsConstructor)';
      case 1452916587:
        return 'XUnion.vectorStringAlsoNeedsConstructor($vectorStringAlsoNeedsConstructor)';
      default:
        return null;
    }
  }

  @override
  int get $ordinal => _ordinal;

  @override
  Object get $data => _data;

  //ignore: prefer_constructors_over_static_methods
  static XUnion _ctor(int ordinal, Object data) {
    return XUnion._(ordinal, data);
  }
}

// See FIDL-308:
// ignore: recursive_compile_time_constant
// ignore: constant_identifier_names
const $fidl.XUnionType<XUnion> kXUnion_Type = $fidl.XUnionType<XUnion>(
  inlineSizeOld: 24,
  inlineSizeV1NoEE: 24,
  members: <int, $fidl.FidlType>{
    910042901: $fidl.Int32Type(),
    891204917: $fidl.StringType(maybeElementCount: null, nullable: false),
    1452916587: $fidl.VectorType<List<String>>(
        element: $fidl.StringType(maybeElementCount: null, nullable: false),
        maybeElementCount: null,
        nullable: false),
  },
  ctor: XUnion._ctor,
);
