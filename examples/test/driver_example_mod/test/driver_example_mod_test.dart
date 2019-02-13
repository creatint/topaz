// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_testing_runner/fidl_async.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:fuchsia_modular/service_connection.dart';
import 'package:fuchsia_remote_debug_protocol/logging.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';

void main() {
  group('driver example tests', () {
    FlutterDriver driver;
    TestRunnerProxy testRunner;

    setUpAll(() async {
      // TODO(DX-561): Update logging messages in
      // fuchsia_remote_debug_protocol so that this doesn't need to be set to
      // `all`.
      Logger.globalLevel = LoggingLevel.all;
      testRunner = new TestRunnerProxy();
      connectToEnvironmentService(testRunner);
      const Pattern isolatePattern = 'driver_example_mod';
      driver = await FlutterDriver.connect(
          fuchsiaModuleTarget: isolatePattern,
          printCommunication: true,
          logCommunicationToFile: false);
    });

    tearDownAll(() async {
      await driver?.close();
      // Must be invoked before closing the connection to this interface;
      // otherwise the TestRunner service will assume that the connection broke
      // due to the test crashing.
      await testRunner.done();
    });

    test('driver connection', () {
      expect(driver, isNotNull);
    });

    test('add to counter. remove from counter', () async {
      await driver.tap(find.text('+1'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      await driver.tap(find.text('+1'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      await driver.tap(find.text('+5'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      await driver.tap(find.text('-1'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      SerializableFinder textFinder =
          find.text('This counter has a value of: 6');
      // If this value hasn't been set correctly the app will crash, as the
      // widget will not be findable.
      await driver.tap(textFinder);
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      await driver.tap(find.text('-5'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      await driver.tap(find.text('-1'));
      await new Future<Null>.delayed(const Duration(milliseconds: 200));
      textFinder = find.text('This counter has a value of: 0');
      await driver.tap(textFinder);
    });
  });
}
