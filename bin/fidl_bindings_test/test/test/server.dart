// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl_fidl_examples_bindingstest/fidl_async.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart'
    show ComponentControllerProxy, LaunchInfo;
import 'package:fuchsia_services/services.dart';

const _kServerName =
    'fuchsia-pkg://fuchsia.com/fidl_bindings_test_server#meta/fidl_bindings_test_server.cmx';

StartupContext _context = StartupContext.fromStartupInfo();

class TestServerInstance {
  final TestServerProxy proxy = TestServerProxy();
  final ComponentControllerProxy controller = ComponentControllerProxy();

  Future<void> start() async {
    final dirProxy = DirectoryProxy();
    final launchInfo = LaunchInfo(
        url: _kServerName,
        directoryRequest: dirProxy.ctrl.request().passChannel());
    await _context.launcher
        .createComponent(launchInfo, controller.ctrl.request());
    Incoming(dirProxy).connectToService(proxy);
  }

  Future<void> stop() async {
    proxy.ctrl.close();
    if (controller.ctrl.isBound) {
      await controller.kill();
    }
  }
}
