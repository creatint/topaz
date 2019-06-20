// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:device_settings/model.dart';
import 'package:fidl_fuchsia_amber/fidl_async.dart' as amber;
import 'package:fidl_fuchsia_pkg/fidl_async.dart' as pkg;
import 'package:fidl_fuchsia_pkg_rewrite/fidl_async.dart' as pkg_rewrite;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class TestSystemInterface extends Mock implements SystemInterface {
  @override
  int get currentTime => 0;

  @override
  void dispose() {}
}

class MockAmberControl extends Mock implements amber.Control {}

class MockRepositoryManager extends Mock implements pkg.RepositoryManager {}

class MockRewriteManager extends Mock implements pkg_rewrite.Engine {}

class MockRepositoryIterator extends Mock implements pkg.RepositoryIterator {}

void main() {
  // Ensure start only reacts to the first invocation.
  test('test_start', () async {
    final TestSystemInterface sysInterface = TestSystemInterface();

    when(sysInterface.listRepositories())
        .thenAnswer((_) => Stream.fromIterable([]));

    when(sysInterface.listRules()).thenAnswer((_) => Stream.fromIterable([]));

    when(sysInterface.listStaticRules())
        .thenAnswer((_) => Stream.fromIterable([]));

    final DeviceSettingsModel model = DeviceSettingsModel(sysInterface);
    await model.start();

    // Ensure resolver is interacted with on the first start.
    verify(sysInterface.listRepositories());
    verify(sysInterface.listRules());
    verify(sysInterface.listStaticRules());

    // We should not be waiting on anything in the second start as it should be
    // an early return.
    await model.start();

    // Ensure resolver has not been interacted with since the first start.
    verifyNever(sysInterface.listRepositories());
    verifyNever(sysInterface.listRules());
    verifyNever(sysInterface.listStaticRules());
  });

  // Makes sure the updating state properly reflects current amber proxy
  // activity.
  test('test_channel_updating_state', () async {
    final TestSystemInterface sysInterface = TestSystemInterface();

    var repoCompleter = Completer();
    var ruleCompleter = Completer();
    var staticRuleCompleter = Completer();

    when(sysInterface.listRepositories()).thenAnswer((_) async* {
      for (var repo in await repoCompleter.future) {
        yield repo;
      }
    });
    when(sysInterface.listRules()).thenAnswer((_) async* {
      for (var rule in await ruleCompleter.future) {
        yield rule;
      }
    });
    when(sysInterface.listStaticRules()).thenAnswer((_) async* {
      for (var rule in await staticRuleCompleter.future) {
        yield rule;
      }
    });

    final DeviceSettingsModel model = DeviceSettingsModel(sysInterface);
    final Future startFuture = model.start();

    // On start, the model should report it is updating as the proxy has not
    // returned
    expect(model.channelUpdating, true);
    repoCompleter.complete([]);
    ruleCompleter.complete([]);
    staticRuleCompleter.complete([]);
    await startFuture;
    expect(model.channelUpdating, false);

    // Reset update completer so it can be used in the next step.
    repoCompleter = Completer();
    ruleCompleter = Completer();
    staticRuleCompleter = Completer();

    when(sysInterface.updateRules(any)).thenAnswer((_) async {
      return 0;
    });

    // make sure we are also updating when selecting a channel.
    Future selectFuture = model.selectChannel(
        pkg.RepositoryConfig(repoUrl: 'fuchsia-pkg://example.com'));
    expect(model.channelUpdating, true);
    repoCompleter.complete([]);
    ruleCompleter.complete([]);
    staticRuleCompleter.complete([]);
    await selectFuture;
    expect(model.channelUpdating, false);
  });
}