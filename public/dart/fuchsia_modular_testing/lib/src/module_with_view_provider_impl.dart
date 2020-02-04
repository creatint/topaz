// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl_modular;
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;
import 'package:fuchsia_modular/lifecycle.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:fuchsia_modular/src/module/internal/_intent_handler_impl.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular/src/module/internal/_module_impl.dart'; // ignore: implementation_imports
import 'package:fuchsia_modular/src/module/internal/_view_provider_impl.dart'; // ignore: implementation_imports
import 'package:meta/meta.dart';
import 'package:zircon/zircon.dart';

/// A [Module] that exposes a view through [ViewProvider].
class ModuleWithViewProviderImpl extends ModuleImpl {
  ViewProvider _viewProvider;
  ViewProviderImpl _viewProviderImpl; // ignore: unused_field

  /// Creates an instance of [ModuleWithViewProviderImpl].
  ModuleWithViewProviderImpl({
    @required ViewProviderImpl viewProviderImpl,
    @required IntentHandlerImpl intentHandlerImpl,
    Lifecycle lifecycle,
    fidl_modular.ModuleContext moduleContext,
  }) : super(
            intentHandlerImpl: intentHandlerImpl,
            lifecycle: lifecycle,
            moduleContext: moduleContext) {
    (lifecycle ??= Lifecycle()).addTerminateListener(_terminate);
    _viewProviderImpl = viewProviderImpl
      ..onCreateView = _proxyCreateViewToViewProvider;
  }

  /// Sets the [ViewProvider] for this module.
  ///
  /// Throws a [ModuleStateException] if a [ViewProvider] has already
  /// been registered.
  void registerViewProvider(ViewProvider viewProvider) {
    if (_viewProvider != null) {
      throw ModuleStateException(
          'View provider registration failed because a provider is already '
          'registered.');
    }

    _viewProvider = viewProvider;
  }

  Future<void> _proxyCreateViewToViewProvider(
      EventPair token,
      InterfaceRequest<fidl_sys.ServiceProvider> incomingServices,
      InterfaceHandle<fidl_sys.ServiceProvider> outgoingServices) async {
    if (_viewProvider == null) {
      throw ModuleStateException(
          'Module received ViewProvider.CreateView but no ViewProvider was '
          'registered to handle it. If you do not intend for the module to '
          'provide a view but still need a module that exposes a ViewProvider, '
          'register a NoopViewProvider.');
    }
    await _viewProvider.createView(token, incomingServices, outgoingServices);
  }

  Future<void> _terminate() async {
    _viewProvider = null;
  }
}
