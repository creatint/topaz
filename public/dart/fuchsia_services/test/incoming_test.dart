// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_test_fuchsia_service_foo/fidl_async.dart';
import 'package:fuchsia_services/src/incoming.dart';
import 'package:fuchsia_services/src/outgoing.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  Incoming _incoming;
  DirectoryProxy _dirProxy;

  setUp(() {
    _dirProxy = DirectoryProxy();
    _incoming = Incoming(_dirProxy);
  });

  group('null checks:', () {
    test('connectToService throws on null', () {
      expect(() => _incoming.connectToService(null), throwsArgumentError);
    });

    test('connectToServiceWithChannel throws on null', () {
      expect(
          () => _incoming.connectToServiceWithChannel(
              null, Channel(Handle.invalid())),
          throwsArgumentError);
      expect(
          () => _incoming.connectToServiceWithChannel(DirectoryProxy(), null),
          throwsArgumentError);
    });

    test('connectToServiceByNameWithChannel throws on null', () {
      expect(
          () => _incoming.connectToServiceByNameWithChannel(
              null, Channel(Handle.invalid())),
          throwsException);
      expect(
          () =>
              _incoming.connectToServiceByNameWithChannel('serviceName', null),
          throwsArgumentError);
    });
  });

  group('connections:', () {
    Outgoing outgoing;
    StreamController<bool> streamController;
    Stream connectorStream;
    FooProxy fooProxy;

    setUp(() {
      outgoing = Outgoing();
      streamController = StreamController<bool>.broadcast();
      connectorStream = streamController.stream;
      fooProxy = FooProxy();

      // expose foo service and add true event to the stream upon connection
      outgoing.addPublicService((_) {
        streamController
          ..add(true)
          ..close();
      }, fooProxy.$serviceData.getName());

      // mimic the responsibility of startup context and serve the dir channel
      outgoing
          .publicDir()
          .serve(InterfaceRequest(_dirProxy.ctrl.request().passChannel()));
    });

    test('Successfully connectToService', () async {
      // verify connecting to fooProxy via incoming is successful
      _incoming.connectToService(fooProxy);
      // by asserting on the stream response
      connectorStream.listen(expectAsync1((response) {
        expect(response, true);
      }));
    });

    test('Successfully connectToServiceWithChannel', () async {
      // verify connecting to fooProxy via incoming is successful
      _incoming.connectToServiceWithChannel(
          fooProxy, fooProxy.ctrl.request().passChannel());
      // by asserting on the stream response
      connectorStream.listen(expectAsync1((response) {
        expect(response, true);
      }));
    });

    test('Successfully connectToServiceByNameWithChannel', () async {
      // verify connecting to fooProxy via incoming is successful
      _incoming.connectToServiceByNameWithChannel(
          fooProxy.$serviceData.getName(),
          fooProxy.ctrl.request().passChannel());

      // by asserting on the stream response
      connectorStream.listen(expectAsync1((response) {
        expect(response, true);
      }));
    });
  });
}
