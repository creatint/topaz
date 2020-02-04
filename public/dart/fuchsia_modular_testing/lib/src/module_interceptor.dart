// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:fuchsia_modular/src/lifecycle/internal/_lifecycle_impl.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular/src/module/internal/_intent_handler_impl.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular/src/module/internal/_view_provider_impl.dart'; // ignore: implementation_imports
import 'package:fuchsia_services/src/internal/_startup_context_impl.dart'; // ignore: implementation_imports
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart'
    as fidl_modular_testing;
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;

import 'module_with_view_provider_impl.dart';

/// A function which is called when a new module that is being launched.
typedef OnNewModule = void Function(ModuleWithViewProviderImpl module);

/// A helper class for managing the interception of module inside the
/// [TestHarness].
///
/// When modules which are registered to be mocked are launched the
/// [OnNewModule] function will be executed.
///
/// ```
/// ModuleInterceptor(testHarness.onNewComponent)
///   .mockModule(moduleUrl, (module) {
///     module
///       ..registerIntentHandler(MyCoolIntentHandler());
///       ..registerViewProvider(MyCoolViewProvider());
///   });
/// ```
class ModuleInterceptor {
  final _registeredModules = <String, OnNewModule>{};
  final _mockedModules = <String, _MockedModule>{};
  StreamSubscription<fidl_modular_testing.TestHarness$OnNewComponent$Response>
      _streamSubscription;

  /// Creates an instance of this which will listen to
  /// the [onNewComponentStream].
  ModuleInterceptor(
      Stream<fidl_modular_testing.TestHarness$OnNewComponent$Response>
          onNewComponentStream)
      : assert(onNewComponentStream != null) {
    _streamSubscription = onNewComponentStream.listen(_handleResponse);
  }

  /// Dispose of the interceptor.
  ///
  /// This method will cancel the onNewComponent stream subscription.
  /// The object is no longer valid after this method is called.
  void dispose() {
    if (_streamSubscription != null) {
      _streamSubscription.cancel();
      _streamSubscription = null;
    }
  }

  /// Register a [moduleUrl] to be mocked.
  ///
  /// If a component with the component url which matches [moduleUrl] is
  /// registered to be interecepted by the test harness [onNewModule] will be
  /// called when that component is first launched. The [onNewModule] method
  /// will be called with an injected [Module] object. This method can be
  /// treated like a normal main method in a non mocked module.
  void mockModule(String moduleUrl, OnNewModule onNewModule) {
    ArgumentError.checkNotNull(moduleUrl, 'moduleUrl');
    ArgumentError.checkNotNull(onNewModule, 'onNewModule');

    if (moduleUrl.isEmpty) {
      throw ArgumentError('moduleUrl must not be empty');
    }

    if (_registeredModules.containsKey(moduleUrl)) {
      throw Exception(
          'Attempting to add [$moduleUrl] twice. Module URLs must be unique');
    }
    _registeredModules[moduleUrl] = onNewModule;
  }

  /// This method is called by the listen method when this object is used as the
  /// handler to the [TestHarnessProxy.onNewComponent] stream.
  void _handleResponse(
      fidl_modular_testing.TestHarness$OnNewComponent$Response response) {
    final startupInfo = response.startupInfo;
    final componentUrl = startupInfo.launchInfo.url;
    if (_registeredModules.containsKey(componentUrl)) {
      final mockedModule = _MockedModule(
        startupInfo: startupInfo,
        interceptedComponentRequest: response.interceptedComponent,
      );
      _mockedModules[componentUrl] = mockedModule;
      _registeredModules[componentUrl](mockedModule.module);
    } else {
      log.info('Skipping launched component [$componentUrl] '
          'because it was not registered');
    }
  }
}

/// A helper class which helps manage the lifecyle of a mocked module
class _MockedModule {
  /// The intercepted component. This object can be used to control the
  /// launched component.
  final fidl_modular_testing.InterceptedComponentProxy interceptedComponent =
      fidl_modular_testing.InterceptedComponentProxy();

  /// The instance of the [Module] which is running in this environment
  ModuleWithViewProviderImpl module;

  /// The startup context for this environment
  StartupContextImpl context;

  /// The lifecycle service for this environment
  LifecycleImpl lifecycle;

  _MockedModule({
    fidl_sys.StartupInfo startupInfo,
    InterfaceHandle<fidl_modular_testing.InterceptedComponent>
        interceptedComponentRequest,
  }) {
    context = StartupContextImpl.from(startupInfo);

    // Note: we want to have a exitHandler which does not call exit here
    // because this mocked module is running inside the test process and
    // calling fuchsia.exit will cause the test process to close.
    lifecycle = LifecycleImpl(context: context, exitHandler: (_) {})
      ..addTerminateListener(() async {
        interceptedComponent.ctrl.close();
      });

    module = ModuleWithViewProviderImpl(
        viewProviderImpl:
            ViewProviderImpl(startupContext: context, lifecycle: lifecycle),
        intentHandlerImpl: IntentHandlerImpl(startupContext: context),
        lifecycle: lifecycle);

    interceptedComponent.ctrl.bind(interceptedComponentRequest);
  }
}
