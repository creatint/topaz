// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:fuchsia_scenic_flutter/child_view.dart' show ChildView;
import 'package:webview_flutter/platform_interface.dart';

import 'fuchsia_web_services.dart';
import 'fuchsia_webview_platform_controller.dart';

/// Builds an Fuchsia webview.
class FuchsiaWebView implements WebViewPlatform {
  /// The fuchsia implementation of [WebViewPlatformController]
  FuchsiaWebServices fuchsiaWebServices;

  /// This constructor should only be used to inject a platform controller for
  /// testing.
  ///
  /// TODO(nkorsote): hide this implementation detail
  @visibleForTesting
  FuchsiaWebView({this.fuchsiaWebServices});

  @override
  Widget build({
    @required WebViewPlatformCallbacksHandler webViewPlatformCallbacksHandler,
    BuildContext context,
    CreationParams creationParams,
    WebViewPlatformCreatedCallback onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) {
    assert(webViewPlatformCallbacksHandler != null);

    final controller = FuchsiaWebViewPlatformController(
        webViewPlatformCallbacksHandler, creationParams, fuchsiaWebServices);

    onWebViewPlatformCreated(controller);
    return ChildView(
        connection: controller.fuchsiaWebServices.childViewConnection);
  }

  @override
  Future<bool> clearCookies() =>
      FuchsiaWebViewPlatformController.clearCookies();
}
