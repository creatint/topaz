// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:fuchsia_vfs/vfs.dart';
import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  Future<void> _assertRead(FileProxy proxy, int bufSize, String expectedString,
      {expectedStatus = ZX.OK}) async {
    var readResponse = await proxy.read(bufSize);
    expect(readResponse.s, expectedStatus);
    expect(String.fromCharCodes(readResponse.data), expectedString);
  }

  Future<void> _assertDescribeVmo(
      FileProxy proxy, String expectedString) async {
    var response = await proxy.describe();
    expect(response.vmofile, isNotNull);
    expect(response.vmofile.vmo.isValid, isTrue);
    final Uint8List value = response.vmofile.vmo.map();
    expect(String.fromCharCodes(value.sublist(0, expectedString.length)),
        expectedString);
  }

  void _assertOpenVmo(response, String expectedString) {
    expect(response.s, ZX.OK);
    expect(response.info, isNotNull);
    expect(response.info.vmofile, isNotNull);
    final Uint8List value = response.info.vmofile.vmo.map();
    expect(String.fromCharCodes(value.sublist(0, expectedString.length)),
        expectedString);
  }

  group('pseudo vmo file:', () {
    test('onOpen with describe flag', () async {
      var stringList = ['test string'];
      var file = _TestPseudoVmoFile.fromStringList(stringList);
      var proxy = file.connect(openRightReadable | openFlagDescribe);

      await proxy.onOpen.first.then((response) {
        _assertOpenVmo(response, stringList[0]);
      }).catchError((err) async {
        fail(err.toString());
      });
    });

    test('pass null vmo function', () {
      _TestPseudoVmoFile produceFile() => _TestPseudoVmoFile.fromVmoFunc(null);
      expect(produceFile, throwsArgumentError);
    });

    test('pass null-producing vmo function', () {
      Vmo produceVmo() => null;
      var file = _TestPseudoVmoFile.fromVmoFunc(produceVmo);
      FileProxy connect() => file.connect(openRightReadable);
      expect(connect, throwsException);
    });

    test('read file', () async {
      var stringList = ['test string', 'hello world', 'lorem ipsum'];
      var file = _TestPseudoVmoFile.fromStringList(stringList);

      for (var expectedString in stringList) {
        var proxy = file.connect(openRightReadable);
        await _assertRead(proxy, expectedString.length, expectedString);
        await proxy.close();
      }
    });

    test('describe duplicate', () async {
      var stringList = ['test string'];
      var file = _TestPseudoVmoFile.fromStringList(stringList);
      var proxy = file.connect(openRightReadable);
      await _assertDescribeVmo(proxy, stringList[0]);
    });
  });
}

class _TestPseudoVmoFile {
  _TestPseudoVmoFile._internal(this._pseudoVmoFile);

  factory _TestPseudoVmoFile.fromStringList(List<String> expectedStrings) {
    return _TestPseudoVmoFile._internal(
        PseudoVmoFile.readOnly(_vmoFromStringFactory(expectedStrings)));
  }

  factory _TestPseudoVmoFile.fromVmoFunc(VmoFn vmoFn) {
    return _TestPseudoVmoFile._internal(PseudoVmoFile.readOnly(vmoFn));
  }

  final PseudoVmoFile _pseudoVmoFile;

  static VmoFn _vmoFromStringFactory(List<String> expectedStrings) {
    int i = 0;

    // callback returns next string in list with each call, restarting at top of
    // list when out of strings
    return () {
      final SizedVmo sizedVmo = SizedVmo.fromUint8List(
          Uint8List.fromList(expectedStrings[i++].codeUnits));
      i %= expectedStrings.length;
      return sizedVmo;
    };
  }

  FileProxy connect(int openRights) {
    var proxy = FileProxy();
    var channel = proxy.ctrl.request().passChannel();
    var interfaceRequest = InterfaceRequest<Node>(channel);
    expect(_pseudoVmoFile.connect(openRights, modeTypeFile, interfaceRequest),
        ZX.OK);
    return proxy;
  }
}
