// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic_flutter/child_view.dart'
    show ChildViewConnection;
import 'package:fidl_fuchsia_web/fidl_async.dart' as web;
import 'package:webview/webview.dart';
import '../models/browse_action.dart';

// Business logic for the browser.
// Sinks:
//   BrowseAction: a browsing action - url request, prev/next page, etc.
// Value Notifiers:
//   Url: the current url.
//   ForwardState: bool indicating whether forward action is available.
//   BackState: bool indicating whether back action is available.
//   isLoadedState: bool indicating whether main document has fully loaded.
class BrowserBloc extends web.NavigationEventListener {
  final ChromiumWebView _webView;

  ChildViewConnection get childViewConnection => _webView.childViewConnection;

  // Value Notifiers
  final ValueNotifier<String> url = ValueNotifier<String>('');
  final ValueNotifier<bool> forwardState = ValueNotifier<bool>(false);
  final ValueNotifier<bool> backState = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadedState = ValueNotifier<bool>(true);

  // Sinks
  final _browseActionController = StreamController<BrowseAction>();
  Sink<BrowseAction> get request => _browseActionController.sink;

  BrowserBloc({
    String homePage,
  }) : _webView = ChromiumWebView() {
    _webView.setNavigationEventListener(this);

    if (homePage != null) {
      _handleAction(NavigateToAction(url: homePage));
    }
    _browseActionController.stream.listen(_handleAction);
  }

  @override
  Future<Null> onNavigationStateChanged(web.NavigationState event) async {
    if (event.url != null) {
      log.info('url loaded: ${event.url}');
      url.value = event.url;
    }
    if (event.canGoForward != null) {
      forwardState.value = event.canGoForward;
    }
    if (event.canGoBack != null) {
      backState.value = event.canGoBack;
    }
    if (event.isMainDocumentLoaded != null) {
      isLoadedState.value = event.isMainDocumentLoaded;
    }
  }

  Future<void> _handleAction(BrowseAction action) async {
    switch (action.op) {
      case BrowseActionType.navigateTo:
        final NavigateToAction navigate = action;
        await _webView.controller.loadUrl(
          _sanitizeUrl(navigate.url),
          web.LoadUrlParams(type: web.LoadUrlReason.typed),
        );
        break;
      case BrowseActionType.goBack:
        await _webView.controller.goBack();
        break;
      case BrowseActionType.goForward:
        await _webView.controller.goForward();
        break;
    }
  }

  void dispose() {
    _webView.dispose();
    _browseActionController.close();
  }

  String _sanitizeUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    } else if (url.endsWith('.com')) {
      return 'https://$url';
    } else {
      return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(url)}';
    }
  }
}
