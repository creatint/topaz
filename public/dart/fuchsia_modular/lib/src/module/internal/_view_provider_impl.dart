// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;
import 'package:fidl_fuchsia_ui_app/fidl_async.dart' as fidl_ui_app;
import 'package:fuchsia_modular/lifecycle.dart';
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';

/// An implementation of the fuchsia.ui.app.ViewProvider FIDL interface
/// that delegates to a function.
///
/// Users of this class should set [onCreateView], which corresponds to
/// the [ViewProvider.createView] method.
class ViewProviderImpl extends fidl_ui_app.ViewProvider {
  fidl_ui_app.ViewProviderBinding _viewProviderBinding;

  /// A function which is invoked when the host receives a [createView] call.
  Future<void> Function(EventPair, InterfaceRequest<fidl_sys.ServiceProvider>,
      InterfaceHandle<fidl_sys.ServiceProvider>) onCreateView;

  /// Creates an instance of [ViewProviderImpl].
  ViewProviderImpl({StartupContext startupContext, Lifecycle lifecycle}) {
    _exposeService(startupContext ?? StartupContext.fromStartupInfo());
    (lifecycle ??= Lifecycle()).addTerminateListener(_terminate);
  }

  /// Implmentation of the ViewProvider.createView method that
  /// delegates to [onCreateView].
  @override
  Future<void> createView(
      EventPair token,
      InterfaceRequest<fidl_sys.ServiceProvider> incomingServices,
      InterfaceHandle<fidl_sys.ServiceProvider> outgoingServices) async {
    if (onCreateView == null) {
      return null;
    }
    await onCreateView(token, incomingServices, outgoingServices);
  }

  void _clearBinding() {
    if (_viewProviderBinding != null && _viewProviderBinding.isBound) {
      _viewProviderBinding.unbind();
      _viewProviderBinding = null;
    }
  }

  void _exposeService(StartupContext startupContext) {
    startupContext.outgoing.addPublicService(
      (InterfaceRequest<fidl_ui_app.ViewProvider> request) {
        _viewProviderBinding = fidl_ui_app.ViewProviderBinding()
          ..bind(this, request);
      },
      fidl_ui_app.ViewProvider.$serviceName,
    );
  }

  Future<void> _terminate() async {
    _clearBinding();
    onCreateView = null;
  }
}
