// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:fuchsia_logger/logger.dart';
import 'package:fidl_fuchsia_web/fidl_async.dart' as web;
import 'package:meta/meta.dart';
import 'package:webview/webview.dart';
import '../models/browse_action.dart';

// Business logic for the browser.
// Sinks:
//   BrowseAction: a browsing action - url request, prev/next page, etc.
// Streams:
//   Url: streams the current url.
//   ForwardState: streams bool indicating whether forward action is available.
//   BackState: streams bool indicating whether back action is available.
class BrowserBloc extends web.NavigationEventListener {
  final ChromiumWebView webView;

  // Streams
  final _urlController = StreamController<String>.broadcast();
  Stream<String> get url => _urlController.stream;
  final _forwardController = StreamController<bool>.broadcast();
  Stream<bool> get forwardState => _forwardController.stream;
  final _backController = StreamController<bool>.broadcast();
  Stream<bool> get backState => _backController.stream;

  // Sinks
  final _browseActionController = StreamController<BrowseAction>();
  Sink<BrowseAction> get request => _browseActionController.sink;

  BrowserBloc({
    @required this.webView,
    String homePage,
  }) : assert(webView != null) {
    webView.setNavigationEventListener(this);

    if (homePage != null) {
      _handleAction(NavigateToAction(url: homePage));
    }
    _browseActionController.stream.listen(_handleAction);
  }

  @override
  Future<Null> onNavigationStateChanged(web.NavigationState event) async {
    if (event.url != null) {
      log.info('url loaded: ${event.url}');
      _urlController.add(event.url);
    }
    if (event.canGoForward != null) {
      _forwardController.add(event.canGoForward);
    }
    if (event.canGoBack != null) {
      _backController.add(event.canGoBack);
    }
  }

  Future<void> _handleAction(BrowseAction action) async {
    switch (action.op) {
      case BrowseActionType.navigateTo:
        final NavigateToAction navigate = action;
        await webView.controller.loadUrl(
            navigate.url, web.LoadUrlParams(type: web.LoadUrlReason.typed));
        break;
      case BrowseActionType.goBack:
        await webView.controller.goBack();
        break;
      case BrowseActionType.goForward:
        await webView.controller.goForward();
        break;
    }
  }

  void dispose() {
    _urlController.close();
    _browseActionController.close();
    _forwardController.close();
    _backController.close();
  }
}
