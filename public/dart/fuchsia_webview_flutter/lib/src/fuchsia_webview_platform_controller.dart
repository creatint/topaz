// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;

import 'package:fidl_fuchsia_web/fidl_async.dart' as fidl_web;
import 'package:fidl_fuchsia_net_http/fidl_async.dart' as fidl_net;
import 'package:webview_flutter/platform_interface.dart';

import 'fuchsia_web_services.dart';

/// Fuchsia [WebViewPlatformController] implementation that serves as the entry
/// point for all [fuchsia_webview_flutter/webview.dart]'s apis
class FuchsiaWebViewPlatformController implements WebViewPlatformController {
  /// Helper class to interact with fuchsia web services
  FuchsiaWebServices _fuchsiaWebServices;

  final WebViewPlatformCallbacksHandler _platformCallbacksHandler;

  /// Initializes [FuchsiaWebViewPlatformController]
  FuchsiaWebViewPlatformController(
      int id, this._platformCallbacksHandler, this._fuchsiaWebServices)
      : assert(_platformCallbacksHandler != null) {
    // TODO(nkorsote): remove this prints with an actual impl. The prints are
    // here to satisfy our strict dart linter for now.
    print('id: $id');
    print('_platformCallbacksHandler: $_platformCallbacksHandler');
    print('fuchsiaWebServices: $fuchsiaWebServices');
  }

  /// Returns [FuchsiaWebServices]
  FuchsiaWebServices get fuchsiaWebServices {
    return _fuchsiaWebServices ??= FuchsiaWebServices();
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError(
        'FuchsiaWebView addJavascriptChannels is not implemented on the current platform');
  }

  @override
  Future<bool> canGoBack() {
    throw UnimplementedError(
        'FuchsiaWebView canGoBack is not implemented on the current platform');
  }

  @override
  Future<bool> canGoForward() {
    throw UnimplementedError(
        'FuchsiaWebView canGoForward is not implemented on the current platform');
  }

  @override
  Future<void> clearCache() {
    throw UnimplementedError(
        'FuchsiaWebView clearCache is not implemented on the current platform');
  }

  @override
  Future<String> currentUrl() async {
    final navigationState =
        await fuchsiaWebServices.navigationController.getVisibleEntry();
    return navigationState.url;
  }

  @override
  Future<String> evaluateJavascript(String javascriptString) {
    throw UnimplementedError(
        'FuchsiaWebView evaluateJavascript is not implemented on the current platform');
  }

  @override
  Future<void> goBack() {
    throw UnimplementedError(
        'FuchsiaWebView goBack is not implemented on the current platform');
  }

  @override
  Future<void> goForward() {
    throw UnimplementedError(
        'FuchsiaWebView goForward is not implemented on the current platform');
  }

  @override
  Future<void> loadUrl(
    String url,
    Map<String, String> headers,
  ) async {
    assert(url != null);

    final headersList = <fidl_net.Header>[];
    if (headers != null) {
      headers.forEach((k, v) {
        headersList
            .add(fidl_net.Header(name: utf8.encode(k), value: utf8.encode(v)));
      });
    }

    return fuchsiaWebServices.navigationController.loadUrl(
        url,
        fidl_web.LoadUrlParams(
          type: fidl_web.LoadUrlReason.typed,
          headers: headersList,
        ));
  }

  @override
  Future<void> reload() {
    throw UnimplementedError(
        'FuchsiaWebView reload is not implemented on the current platform');
  }

  @override
  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    throw UnimplementedError(
        'FuchsiaWebView removeJavascriptChannels is not implemented on the current platform');
  }

  @override
  Future<void> updateSettings(WebSettings settings) {
    throw UnimplementedError(
        'FuchsiaWebView updateSettings is not implemented on the current platform');
  }

  /// Clears all cookies for all [WebView] instances.
  ///
  /// Returns true if cookies were present before clearing, else false.
  static Future<bool> clearCookies() {
    throw UnimplementedError(
        'FuchsiaWebView clearCookies is not implemented on the current platform');
  }

  // TODO(nkorsote): implement this method
  // static Map<String, dynamic> creationParamsToMap(
  //     CreationParams creationParams) {
  //   throw UnimplementedError(
  //       'FuchsiaWebView creationParamsToMap is not implemented on the current platform');
  // }
}
