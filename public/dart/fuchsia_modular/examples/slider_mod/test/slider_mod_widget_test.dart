// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:fuchsia_remote_debug_protocol/logging.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';

const Pattern _isolatePattern = 'slider_mod';
const _testAppUrl = 'fuchsia-pkg://fuchsia.com/slider_mod#meta/slider_mod.cmx';
const _basemgrUrl = 'fuchsia-pkg://fuchsia.com/basemgr#meta/basemgr.cmx';

// Starts basemgr with dev shells. This should be called from within a
// try/finally or similar construct that closes the component controller.
Future<void> _startBasemgr(
    InterfaceRequest<ComponentController> controllerRequest,
    String rootModUrl) async {
  final context = StartupContext.fromStartupInfo();

  final launchInfo = LaunchInfo(url: _basemgrUrl, arguments: [
    '--base_shell=fuchsia-pkg://fuchsia.com/dev_base_shell#meta/dev_base_shell.cmx',
    '--session_shell=fuchsia-pkg://fuchsia.com/dev_session_shell#meta/dev_session_shell.cmx',
    '--session_shell_args=--root_module=$rootModUrl',
    '--story_shell=fuchsia-pkg://fuchsia.com/dev_story_shell#meta/dev_story_shell.cmx',
    '--test',
    '--enable_presenter',
    '--run_base_shell_with_test_runner=false'
  ]);
  await context.launcher.createComponent(launchInfo, controllerRequest);
}

void main() {
  final controller = ComponentControllerProxy();
  FlutterDriver driver;

  // The following boilerplate is a one time setup required to make
  // flutter_driver work in Fuchsia.
  //
  // When a module built using Flutter starts up in debug mode, it creates an
  // instance of the Dart VM, and spawns an Isolate (isolated Dart execution
  // context) containing your module.
  setUpAll(() async {
    Logger.globalLevel = LoggingLevel.all;

    await _startBasemgr(controller.ctrl.request(), _testAppUrl);

    // Creates an object you can use to search for your mod on the machine
    driver = await FlutterDriver.connect(
        fuchsiaModuleTarget: _isolatePattern,
        printCommunication: true,
        logCommunicationToFile: false);
  });

  tearDownAll(() async {
    await driver?.close();
    controller.ctrl.close();
  });

  test(
      'Verify the agent is connected and replies with the correct Fibonacci '
      'result', () async {
    print('tapping on Calc Fibonacci button');
    await driver.tap(find.text('Calc Fibonacci'));
    print('verifying the result');
    await driver.waitFor(find.byValueKey('fib-result-widget-key'));
    print('test is finished successfully');
  });
}
