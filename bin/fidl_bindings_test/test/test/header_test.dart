// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:pedantic/pedantic.dart';
import 'package:topaz.bin.fidl_bindings_test.test._fidl_bindings_test_dart_library/server.dart';
import 'package:zircon/zircon.dart';

import 'package:fidl_fidl_examples_bindingstest/fidl_async.dart';
import 'package:test/test.dart';
import 'package:fidl/fidl.dart';

void main() {
  group('magic number', () {
    test('requests', () async {
      final TestServerProxy proxy = TestServerProxy();
      Channel server = proxy.ctrl.request().passChannel();
      await proxy.oneWayStringArg('foo');
      final ReadResult result = server.queryAndRead();
      final Message message = Message.fromReadResult(result);
      expect(message.magic, equals(kMagicNumberInitial));
    });

    test('events', () async {
      final TestServerProxy proxy = TestServerProxy();
      Channel client = proxy.ctrl.request().passChannel();
      await proxy.sendStringEvent('bar');
      final ReadResult result = client.queryAndRead();
      final Message message = Message.fromReadResult(result);
      expect(message.magic, equals(kMagicNumberInitial));
    });

    test('responses', () async {
      final TestServerInstance server = TestServerInstance();
      await server.start();
      Completer magicNumberCompleter = Completer();
      server.proxy.ctrl.onResponse = (Message message) {
        magicNumberCompleter.complete(message.magic);
      };

      // this request will complete with an error after server.stop() since
      // onResponse will never respond to it
      unawaited(server.proxy.twoWayStringArg('baz').catchError((e) {}));
      int magic = await magicNumberCompleter.future;
      expect(magic, equals(kMagicNumberInitial));

      await server.stop();
    });
  });
}
