// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_auth/fidl_async.dart';
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:fidl_fuchsia_ui_viewsv1token/fidl_async.dart';
import 'package:flutter/widgets.dart';
import 'package:zircon/zircon.dart';

/// Called when an authentication overlay needs to be started.
typedef OnStartOverlay = void Function(ViewHolderToken viewHolderToken);

/// An [AuthenticationUiContext] which calls its callbacks to show an overlay.
class AuthenticationUiContextImpl extends AuthenticationUiContext {
  /// Called when an aunthentication overlay needs to be started.
  final OnStartOverlay _onStartOverlay;

  /// Called when an aunthentication overlay needs to be stopped.
  final VoidCallback _onStopOverlay;

  /// Builds an AuthenticationUiContext that takes |ViewHolderToken| callbacks
  /// to start and stop an authentication display overlay.
  AuthenticationUiContextImpl(
      {OnStartOverlay onStartOverlay, VoidCallback onStopOverlay})
      : _onStartOverlay = onStartOverlay,
        _onStopOverlay = onStopOverlay;

  @override
  // ignore: override_on_non_overriding_method
  Future<void> startOverlay(InterfaceHandle<ViewOwner> viewOwner) =>
      startOverlay2(EventPair(viewOwner?.passChannel()?.passHandle()));

  @override
  // ignore: override_on_non_overriding_method
  Future<void> startOverlay2(EventPair viewHolderToken) {
    _onStartOverlay?.call(ViewHolderToken(value: viewHolderToken));
    return null;
  }

  @override
  Future<void> stopOverlay() {
    _onStopOverlay?.call();
    return null;
  }
}
