// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:device_settings/model.dart';
import 'package:fidl_fuchsia_amber/fidl_async.dart' as amber;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class TestSystemInterface implements SystemInterface {
  MockAmberControl mockAmberControl = MockAmberControl();
  Completer<List<amber.SourceConfig>> updateCompleter;

  TestSystemInterface() {
    resetChannelUpdateCompleter();
    when(amberControl.listSrcs()).thenAnswer((_) => updateCompleter.future);
  }

  void resetChannelUpdateCompleter() {
    updateCompleter = Completer<List<amber.SourceConfig>>();
  }

  @override
  int get currentTime => 0;

  @override
  amber.Control get amberControl => mockAmberControl;

  @override
  void dispose() {}
}

class MockAmberControl extends Mock implements amber.Control {}

void main() {
  // Ensure start only reacts to the first invocation.
  test('test_start', () async {
    final TestSystemInterface sysInterface = TestSystemInterface();

    //ignore: unawaited_futures
    DeviceSettingsModel model = DeviceSettingsModel(sysInterface)..start();

    // Ensure amberProxy is interacted with on the first start.
    verify(sysInterface.mockAmberControl.listSrcs());

    // We should not be waiting on anything in the second start as it should be
    // an early return.
    await model.start();

    // Ensure amberProxy has not been interacted with since the first start.
    verifyNever(sysInterface.mockAmberControl.listSrcs());
  });

  // Makes sure the updating state properly reflects current amber proxy
  // activity.
  test('test_channel_updating_state', () async {
    final TestSystemInterface sysInterface = TestSystemInterface();
    final DeviceSettingsModel model = DeviceSettingsModel(sysInterface);

    final Future startFuture = model.start();

    // On start, the model should report it is updating as the proxy has not
    // returned
    expect(model.channelUpdating, true);
    sysInterface.updateCompleter.complete([]);
    await startFuture;
    expect(model.channelUpdating, false);

    // Reset update completer so it can be used in the next step.
    sysInterface.resetChannelUpdateCompleter();

    // make sure we are also updating when selecting a channel.
    Future selectFuture = model.selectChannel(null);
    expect(model.channelUpdating, true);
    sysInterface.updateCompleter.complete([]);
    await selectFuture;
    expect(model.channelUpdating, false);
  });
}
