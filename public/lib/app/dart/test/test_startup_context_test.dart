// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:lib.app.dart/testing/test_startup_context.dart';
import 'package:lib.app.dart/app.dart';
import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  TestStartupContext testContext = TestStartupContext();
  StartupContext.provideStartupContext(testContext);

  group('Fake context', () {
    test('can be obtained through fromStartupInfo', () {
      expect(StartupContext.fromStartupInfo(), testContext);
    });
    test('should not crash with normal calls', () {
      final context = StartupContext.fromStartupInfo();

      context.outgoingServices.addServiceForName((req) {}, 'service');
      context.environmentServices.ctrl.close();
      context.close();
    });
    test('should connect a service when connected', () {
      final context = StartupContext.fromStartupInfo();
      var wasConnected = false;

      testContext.withTestService((req) {
        wasConnected = true;
      }, 'connectedService');

      context.environmentServices.connectToService(
          'connectedService', Channel(Handle.invalid()));

      expect(wasConnected, true);
    }, skip: 'TODO(tvolkert): re-enable this test');
  });

  // TODO(ejia): add tests with full fidl service
}
