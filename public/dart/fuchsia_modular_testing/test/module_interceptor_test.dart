// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl_modular;
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart' as fidl_testing;
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:fuchsia_modular_testing/src/module_interceptor.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular_testing/src/test_harness_fixtures.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular_testing/src/test_harness_spec_builder.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular_testing/test.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockViewProvider extends Mock implements ViewProvider {}

void main() {
  setupLogger();

  group('mock registration', () {
    ModuleInterceptor moduleInterceptor;

    setUp(() {
      moduleInterceptor = ModuleInterceptor(
          Stream<TestHarness$OnNewComponent$Response>.empty());
    });

    test('mockModule throws for null moduleUrl', () {
      expect(() => moduleInterceptor.mockModule(null, (_) {}),
          throwsArgumentError);
    });

    test('mockModule throws for empty moduleUrl', () {
      expect(
          () => moduleInterceptor.mockModule('', (_) {}), throwsArgumentError);
    });

    test('mockModule throws for missing callback', () {
      expect(() => moduleInterceptor.mockModule(generateComponentUrl(), null),
          throwsArgumentError);
    });

    test('mockModule throws for registering module twice', () {
      final moduleUrl = generateComponentUrl();
      void callback(_) {}

      moduleInterceptor.mockModule(moduleUrl, callback);

      expect(() => moduleInterceptor.mockModule(moduleUrl, callback),
          throwsException);
    });
  });

  group('module intercepting', () {
    TestHarnessProxy harness;
    String moduleUrl;
    ModuleInterceptor interceptor;

    /// Launches a module with the component URL [moduleUrl].
    Future<void> launchModule(String moduleUrl) async {
      final puppetMaster = fidl_modular.PuppetMasterProxy();

      await harness.connectToModularService(
          fidl_testing.ModularService.withPuppetMaster(
              puppetMaster.ctrl.request()));

      final storyPuppetMaster = fidl_modular.StoryPuppetMasterProxy();
      await puppetMaster.controlStory(
          'test_story', storyPuppetMaster.ctrl.request());
      puppetMaster.ctrl.close();

      await storyPuppetMaster.enqueue([
        fidl_modular.StoryCommand.withAddMod(fidl_modular.AddMod(
          intent: fidl_modular.Intent(action: '', handler: moduleUrl),
          surfaceParentModName: [],
          modName: ['test_mod'],
          surfaceRelation: fidl_modular.SurfaceRelation(),
        ))
      ]);
      await storyPuppetMaster.execute();
      storyPuppetMaster.ctrl.close();
    }

    setUp(() async {
      moduleUrl = generateComponentUrl();
      harness = await launchTestHarness();
      interceptor = ModuleInterceptor(harness.onNewComponent);
    });

    tearDown(() {
      harness.ctrl.close();
      interceptor.dispose();
    });

    test('onNewModule called for mocked module', () async {
      final spec = (TestHarnessSpecBuilder()
            ..addComponentToIntercept(moduleUrl))
          .build();

      final didCallMockModule = Completer<bool>();
      interceptor.mockModule(moduleUrl, (module) {
        expect(module, isNotNull);
        module
          ..registerViewProvider(NoopViewProvider())
          ..registerIntentHandler(NoopIntentHandler());
        didCallMockModule.complete(true);
      });

      await harness.run(spec);
      await launchModule(moduleUrl);

      expect(await didCallMockModule.future, isTrue);
    });

    test('onNewModule can register a ViewProvider', () async {
      final spec = (TestHarnessSpecBuilder()
            ..addComponentToIntercept(moduleUrl))
          .build();

      final viewProvider = _MockViewProvider();
      final didCallCreateView = Completer<bool>();

      when(viewProvider.createView(any, any, any)).thenAnswer((_) {
        didCallCreateView.complete(true);
        return Future.value();
      });

      interceptor.mockModule(moduleUrl, (module) {
        module
          ..registerViewProvider(viewProvider)
          ..registerIntentHandler(NoopIntentHandler());
      });

      await harness.run(spec);
      await launchModule(moduleUrl);

      expect(await didCallCreateView.future, isTrue);
      verify(viewProvider.createView(any, any, any)).called(isNonZero);
    });
  });
}
