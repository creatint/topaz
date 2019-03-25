// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart' show InterfaceRequest;
import 'package:fidl_fidl_test_compatibility/fidl_async.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:fuchsia_services/services.dart';

class EchoImpl extends Echo {
  final StartupContext context;

  final _echoEventStreamController = StreamController<Struct>();

  // Saves references to proxies from which we're expecting events.
  Map<String, EchoProxy> proxies = {};

  EchoImpl(this.context);

  Future<Struct> proxyEcho(Struct value, String forwardToServer) async {
    assert(forwardToServer.isNotEmpty);

    final dirProxy = DirectoryProxy();
    final launchInfo = LaunchInfo(
        url: forwardToServer,
        directoryRequest: dirProxy.ctrl.request().passChannel());
    final controller = ComponentControllerProxy();
    await context.launcher
        .createComponent(launchInfo, controller.ctrl.request());
    final echo = EchoProxy();
    Incoming(dirProxy).connectToService(echo);

    return echo.echoStruct(value, '');
  }

  @override
  Future<Struct> echoStruct(Struct value, String forwardToServer) async {
    if (forwardToServer != null && forwardToServer.isNotEmpty) {
      return proxyEcho(value, forwardToServer);
    }
    return value;
  }

  void handleEchoEvent(Struct value, String serverUrl) {
    _echoEventStreamController.add(value);
    // Not technically safe if there's more than one outstanding event on this
    // proxy, but that shouldn't happen in the existing test.
    proxies.remove(serverUrl);
  }

  @override
  Future<void> echoStructNoRetVal(Struct value, String forwardToServer) async {
    if (forwardToServer != null && forwardToServer.isNotEmpty) {
      final dirProxy = DirectoryProxy();
      final launchInfo = LaunchInfo(
          url: forwardToServer,
          directoryRequest: dirProxy.ctrl.request().passChannel());
      final controller = ComponentControllerProxy();
      await context.launcher
          .createComponent(launchInfo, controller.ctrl.request());
      final echo = EchoProxy();
      Incoming(dirProxy).connectToService(echo);
      // Keep echo around until we process the expected event.
      proxies[forwardToServer] = echo;
      echo.echoEvent.listen((Struct val) {
        handleEchoEvent(val, forwardToServer);
      });
      return echo.echoStructNoRetVal(value, '');
    }
    return _echoEventStreamController.add(value);
  }

  @override
  Stream<Struct> get echoEvent => _echoEventStreamController.stream;
}


void main(List<String> args) {
  final EchoBinding echoBinding = EchoBinding();
  final StartupContext context = StartupContext.fromStartupInfo();
  final EchoImpl echoImpl = EchoImpl(context);
  context.outgoing.addPublicService(
      (InterfaceRequest<Echo> request) => echoBinding.bind(echoImpl, request),
      Echo.$serviceName);
}