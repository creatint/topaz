// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io';

import 'package:fidl/fidl.dart';
import 'package:fidl_chromium_web/fidl_async.dart' as web;
import 'package:fidl_fuchsia_mem/fidl_async.dart' as fuchsia_mem;
import 'package:fidl_fuchsia_io/fidl_async.dart' as fidl_io;
import 'package:fidl_fuchsia_sys/fidl_async.dart' as sys;
import 'package:fidl_fuchsia_ui_views/fidl_async.dart' as views;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic_flutter/child_view_connection.dart'
    show ChildViewConnection;
import 'package:zircon/zircon.dart';

class ChromiumWebView {
  final sys.ServiceProvider serviceProvider;
  final web.ContextProviderProxy _contextProvider = web.ContextProviderProxy();
  final web.ContextProxy _context = web.ContextProxy();
  final web.FrameProxy _frame = web.FrameProxy();
  final web.NavigationControllerProxy _navigationController =
      web.NavigationControllerProxy();

  final web.NavigationEventObserverBinding _navigationEventObserverBinding =
      web.NavigationEventObserverBinding();

  ChildViewConnection _childViewConnection;

  ChromiumWebView(
    this.serviceProvider, {
    web.LogLevel javascriptLogLevel = web.LogLevel.none,
  }) {
    final contextProviderProxyRequest = _contextProvider.ctrl.request();
    serviceProvider.connectToService(_contextProvider.ctrl.$serviceName,
        contextProviderProxyRequest.passChannel());
    if (!Directory('/svc').existsSync()) {
      log.shout('no /svc directory');
      return;
    }
    final channel = Channel.fromFile('/svc');
    final web.CreateContextParams params = web.CreateContextParams(
        serviceDirectory: InterfaceHandle<fidl_io.Directory>(channel));
    _contextProvider.create(params, _context.ctrl.request());
    _context.createFrame(_frame.ctrl.request());

    // Create a token pair for the newly-created View.
    final tokenPair = EventPairPair();
    assert(tokenPair.status == ZX.OK);
    final viewHolderToken = views.ViewHolderToken(value: tokenPair.first);
    final viewToken = views.ViewToken(value: tokenPair.second);

    _frame.createView2(viewToken.value, null, null);
    _childViewConnection = ChildViewConnection(viewHolderToken);
    _frame
      ..getNavigationController(_navigationController.ctrl.request())
      ..setJavaScriptLogLevel(javascriptLogLevel);
  }

  ChildViewConnection get childViewConnection => _childViewConnection;

  web.NavigationControllerProxy get controller => _navigationController;

  void setNavigationEventObserver(web.NavigationEventObserver observer) {
    _frame.setNavigationEventObserver(
        _navigationEventObserverBinding.wrap(observer));
  }

  Future<bool> injectJavascript(
    String script,
    List<String> origins, {
    web.ExecuteMode executeMode = web.ExecuteMode.onPageLoad,
  }) {
    final vmo = SizedVmo.fromUint8List(utf8.encode(script));
    final buffer = fuchsia_mem.Buffer(vmo: vmo, size: vmo.size);
    return _frame.executeJavaScript(origins, buffer, executeMode);
  }

  Future<bool> postMessage(String message, String targetOrigin,
      {InterfaceRequest<web.MessagePort> outgoingMessagePortRequest}) {
    final vmo = SizedVmo.fromUint8List(utf8.encode(message));
    var msg = web.WebMessage(
      data: fuchsia_mem.Buffer(vmo: vmo, size: vmo.size),
      outgoingTransfer: outgoingMessagePortRequest != null
          ? web.OutgoingTransferable.withMessagePort(outgoingMessagePortRequest)
          : null,
    );
    return _frame.postMessage(msg, targetOrigin);
  }

  void dispose() {
    _navigationController.ctrl.close();
    _frame.ctrl.close();
    _context.ctrl.close();
    _contextProvider.ctrl.close();
  }
}
