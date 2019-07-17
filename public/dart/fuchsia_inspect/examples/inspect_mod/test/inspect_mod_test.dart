// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:io' as dartio;
import 'dart:typed_data';
import 'package:fidl_fuchsia_modular/fidl_async.dart';
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:fuchsia_remote_debug_protocol/logging.dart';
import 'package:fuchsia_services/services.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';
import 'util.dart';

import 'vmo_reader.dart' show VmoReader;

const Pattern _testAppName = 'inspect_mod.cmx';
const _testAppUrl = 'fuchsia-pkg://fuchsia.com/inspect_mod#meta/$_testAppName';
const _modularTestHarnessURL =
    'fuchsia-pkg://fuchsia.com/modular_test_harness#meta/modular_test_harness.cmx';

TestHarnessProxy testHarnessProxy = TestHarnessProxy();
ComponentControllerProxy testHarnessController = ComponentControllerProxy();

// TODO(CF-603) Replace the test-harness / launch-mod boilerplate when possible.
// Starts Modular TestHarness with dev shells. This should be called from within
// a try/finally or similar construct that closes the component controller.
Future<void> _startTestHarness() async {
  final launcher = LauncherProxy();
  final incoming = Incoming();

  // launch TestHarness component
  StartupContext.fromStartupInfo().incoming.connectToService(launcher);
  await launcher.createComponent(
      LaunchInfo(
          url: _modularTestHarnessURL,
          directoryRequest: incoming.request().passChannel()),
      testHarnessController.ctrl.request());

  // connect to TestHarness service
  incoming.connectToService(testHarnessProxy);

  // helper function to convert a map of service to url into list of
  // [ComponentService]
  List<ComponentService> _toComponentServices(
      Map<String, String> serviceToUrl) {
    final componentServices = <ComponentService>[];
    for (final svcName in serviceToUrl.keys) {
      componentServices
          .add(ComponentService(name: svcName, url: serviceToUrl[svcName]));
    }
    return componentServices;
  }

  final testHarnessSpec = TestHarnessSpec(
      envServicesToInherit: [
        'fuchsia.net.SocketProvider',
        'fuchsia.net.NameLookup',
        'fuchsia.posix.socket.Provider'
      ],
      envServices: EnvironmentServicesSpec(
          servicesFromComponents: _toComponentServices({
        'fuchsia.auth.account.AccountManager':
            'fuchsia-pkg://fuchsia.com/account_manager#meta/account_manager.cmx',
        'fuchsia.devicesettings.DeviceSettingsManager':
            'fuchsia-pkg://fuchsia.com/device_settings_manager#meta/device_settings_manager.cmx',
        'fuchsia.fonts.Provider':
            'fuchsia-pkg://fuchsia.com/fonts#meta/fonts.cmx',
        'fuchsia.sysmem.Allocator':
            'fuchsia-pkg://fuchsia.com/sysmem_connector#meta/sysmem_connector.cmx',
        'fuchsia.tracelink.Registry':
            'fuchsia-pkg://fuchsia.com/trace_manager#meta/trace_manager.cmx',
        'fuchsia.ui.input.ImeService':
            'fuchsia-pkg://fuchsia.com/ime_service#meta/ime_service.cmx',
        'fuchsia.ui.policy.Presenter':
            'fuchsia-pkg://fuchsia.com/root_presenter#meta/root_presenter.cmx',
        'fuchsia.ui.scenic.Scenic':
            'fuchsia-pkg://fuchsia.com/scenic#meta/scenic.cmx',
        'fuchsia.vulkan.loader.Loader':
            'fuchsia-pkg://fuchsia.com/vulkan_loader#meta/vulkan_loader.cmx'
      })));

  // run the test harness which will create an encapsulated test env
  await testHarnessProxy.run(testHarnessSpec);
}

Future<void> _launchModUnderTest() async {
  // get the puppetMaster service from the encapsulated test env
  final puppetMasterProxy = PuppetMasterProxy();
  await testHarnessProxy.connectToModularService(
      ModularService.withPuppetMaster(puppetMasterProxy.ctrl.request()));
  // use puppetMaster to start a fake story an launch the mod under test
  final storyPuppetMasterProxy = StoryPuppetMasterProxy();
  await puppetMasterProxy.controlStory(
      'fooStoryName', storyPuppetMasterProxy.ctrl.request());
  await storyPuppetMasterProxy.enqueue(<StoryCommand>[
    StoryCommand.withAddMod(AddMod(
        modName: ['inspect_mod'],
        modNameTransitional: 'root',
        intent: Intent(action: 'action', handler: _testAppUrl),
        surfaceRelation: SurfaceRelation()))
  ]);
  await storyPuppetMasterProxy.execute();
}

Future<String> _readInspect() async {
  // WARNING: 0) These paths are extremely fragile.
  var globs = [
    // TODO(vickiecheng): remove this one once stories reuse session envs.
    '/hub/r/modular_test_harness_*/*/r/session-*/*/r/*/*/c/flutter_*_runner.cmx/*/c/$_testAppName/*/out/debug/root.inspect',
    '/hub/r/modular_test_harness_*/*/c/flutter_*_runner.cmx/*/c/$_testAppName/*/out/debug/root.inspect',
    '/hub/r/mth_*/*/r/session-*/*/r/*/*/c/flutter_*_runner.cmx/*/c/$_testAppName/*/out/debug/root.inspect',
    '/hub/r/mth_*/*/c/flutter_*_runner.cmx/*/c/$_testAppName/*/out/debug/root.inspect',
  ];
  for (final globString in globs) {
    await for (var f in Glob(globString).list()) {
      if (f is dartio.File) {
        // WARNING: 1) This read is not atomic.
        // WARNING: 2) This won't work with VMOs written in C++ and maybe elsewhere.
        // TODO(CF-603): Use direct VMO read when possible.
        var vmoBytes = await f.readAsBytes();
        var vmoData = ByteData(vmoBytes.length);
        for (int i = 0; i < vmoBytes.length; i++) {
          vmoData.setUint8(i, vmoBytes[i]);
        }
        var vmo = FakeVmoReader.usingData(vmoData);
        return VmoReader(vmo).toString();
      }
    }
  }
  throw Exception('could not find inspect node');
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

    await _startTestHarness();
    await _launchModUnderTest();

    // Creates an object you can use to search for your mod on the machine
    driver = await FlutterDriver.connect(
        fuchsiaModuleTarget: _testAppName,
        printCommunication: true,
        logCommunicationToFile: false);
  });

  tearDownAll(() async {
    await driver?.close();
    controller.ctrl.close();

    testHarnessProxy.ctrl.close();
    testHarnessController.ctrl.close();
  });

  Future<String> tapAndWait(String buttonName, String nextState) async {
    await driver.tap(find.text(buttonName));
    await driver.waitFor(find.byValueKey(nextState));
    return await _readInspect();
  }

  test('Put the program through its paces', () async {
    // Wait for initial StateBloc value to appear
    await driver.waitFor(find.byValueKey('Program has started'));
    var inspect = await _readInspect();
    expect('<> >> IntProperty "interesting": 118', isIn(inspect));
    expect('<> >> DoubleProperty "double down": 3.23', isIn(inspect));
    expect('<> >> ByteDataProperty  "bytes": 01 02 03 04', isIn(inspect));
    expect('<> >> StringProperty "greeting": "Hello World"', isIn(inspect));
    expect('<> >> Node: "home-page"', isIn(inspect));
    expect('<> >> >> IntProperty "counter": 0', isIn(inspect));
    expect('<> >> >> StringProperty "background-color": "Color(0xffffffff)"',
        isIn(inspect));
    expect('<> >> >> StringProperty "title": "Hello Inspect!"', isIn(inspect));

    // Tap the "Increment counter" button
    inspect = await tapAndWait('Increment counter', 'Counter was incremented');
    expect('IntProperty "counter": 0', isNot(isIn(inspect)));
    expect('IntProperty "counter": 1', isIn(inspect));

    // Tap the "Decrement counter" button
    inspect = await tapAndWait('Decrement counter', 'Counter was decremented');
    expect('IntProperty "counter": 1', isNot(isIn(inspect)));
    expect('IntProperty "counter": 0', isIn(inspect));

    // The node name below is truncated due to limitations of the maximum node
    // name length.
    var preTreeInspect = inspect;
    inspect = await tapAndWait('Make tree', 'Tree was made');
    expect(
        '<> >> >> Node: "I think that I shall never see01234567890123456789012345"\n'
        '<> >> >> >> IntProperty "int0": 0',
        isIn(inspect));

    inspect = await tapAndWait('Grow tree', 'Tree was grown');
    expect('<> >> >> >> IntProperty "int0": 0', isIn(inspect));
    expect('<> >> >> >> IntProperty "int1": 1', isIn(inspect));

    inspect = await tapAndWait('Delete tree', 'Tree was deleted');
    expect(inspect, preTreeInspect);

    inspect = await tapAndWait('Grow tree', 'Tree was grown');
    expect(inspect, preTreeInspect);

    inspect = await tapAndWait('Make tree', 'Tree was made');
    expect(
        '<> >> >> Node: "I think that I shall never see01234567890123456789012345"\n'
        '<> >> >> >> IntProperty "int3": 3',
        isIn(inspect));

    inspect = await tapAndWait('Get answer', 'Waiting for answer');
    expect('>> StringProperty "waiting": "for a hint"', isIn(inspect));

    inspect = await tapAndWait('Give hint', 'Displayed answer');
    expect('>> StringProperty "waiting": "for a hint"', isNot(isIn(inspect)));

    inspect = await tapAndWait('Change color', 'Color was changed');
    expect('<> >> >> StringProperty "background-color": "Color(0xffffffff)"',
        isNot(isIn(inspect)));
    expect('<> >> >> StringProperty "background-color": "', isIn(inspect));
  });
}
