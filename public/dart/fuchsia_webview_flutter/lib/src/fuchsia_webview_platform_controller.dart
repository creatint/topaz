// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;

import 'package:fidl/fidl.dart' as fidl;
import 'package:fidl_fuchsia_web/fidl_async.dart' as fidl_web;
import 'package:fidl_fuchsia_net_http/fidl_async.dart' as fidl_net;
import 'package:webview_flutter/platform_interface.dart';
import 'package:fuchsia_logger/logger.dart';

import 'fuchsia_web_services.dart';
import 'utils.dart' as utils;

/// Fuchsia [WebViewPlatformController] implementation that serves as the entry
/// point for all [fuchsia_webview_flutter/webview.dart]'s apis
class FuchsiaWebViewPlatformController extends fidl_web.NavigationEventListener
    implements WebViewPlatformController {
  /// Helper class to interact with fuchsia web services
  FuchsiaWebServices _fuchsiaWebServices;
  String _currentUrl;
  // Reason: sdk_version_set_literal unsupported until version 2.2
  // ignore: prefer_collection_literals
  final _pendingChannels = Set<String>();

  final WebViewPlatformCallbacksHandler _platformCallbacksHandler;
  final _javascriptChannelSubscriptions =
      <String, StreamSubscription<String>>{};

  /// Initializes [FuchsiaWebViewPlatformController]
  FuchsiaWebViewPlatformController(this._platformCallbacksHandler,
      CreationParams creationParams, this._fuchsiaWebServices)
      : assert(_platformCallbacksHandler != null) {
    fuchsiaWebServices.setNavigationEventListener(this);
    updateSettings(creationParams.webSettings);
    if (creationParams.initialUrl != null) {
      loadUrl(creationParams.initialUrl, {});
    }
    _pendingChannels.addAll(creationParams.javascriptChannelNames);
  }

  /// Returns [FuchsiaWebServices]
  FuchsiaWebServices get fuchsiaWebServices {
    return _fuchsiaWebServices ??= FuchsiaWebServices();
  }

  @override
  Future<void> onNavigationStateChanged(fidl_web.NavigationState state) async {
    // TODO(miguelfrde): instead of storing just the current url, store the
    // current state for use in canGoBack, canGoForward, etc.
    if (state.url != null) {
      _currentUrl = state.url;
    }
    if (state.isMainDocumentLoaded != null && state.isMainDocumentLoaded) {
      final channelsToAdd =
          _pendingChannels.union(_javascriptChannelSubscriptions.keys.toSet());
      await _createChannelSubscriptions(channelsToAdd);
      _pendingChannels.clear();
      _platformCallbacksHandler.onPageFinished(_currentUrl);
    }
  }

  @override
  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) async {
    await _createChannelSubscriptions(javascriptChannelNames);
  }

  @override
  Future<bool> canGoBack() async {
    final navigationState =
        await fuchsiaWebServices.navigationController.getVisibleEntry();
    return navigationState.canGoBack;
  }

  @override
  Future<bool> canGoForward() async {
    final navigationState =
        await fuchsiaWebServices.navigationController.getVisibleEntry();
    return navigationState.canGoForward;
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
  Future<String> evaluateJavascript(String javascriptString) async {
    return fuchsiaWebServices.evaluateJavascript(['*'], javascriptString);
  }

  @override
  Future<void> goBack() {
    return fuchsiaWebServices.navigationController.goBack();
  }

  @override
  Future<void> goForward() {
    return fuchsiaWebServices.navigationController.goForward();
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
    return fuchsiaWebServices.navigationController
        .reload(fidl_web.ReloadType.partialCache);
  }

  @override
  Future<void> removeJavascriptChannels(
      Set<String> javascriptChannelNames) async {
    for (final channelName in javascriptChannelNames) {
      if (_javascriptChannelSubscriptions.containsKey(channelName)) {
        await _javascriptChannelSubscriptions[channelName].cancel();
        _javascriptChannelSubscriptions.remove(channelName);
        await fuchsiaWebServices
            .evaluateJavascript(['*'], 'window.$channelName = undefined;');
      }
    }
  }

  @override
  Future<void> updateSettings(WebSettings settings) {
    if (settings.debuggingEnabled != null) {
      return fuchsiaWebServices.setJavaScriptLogLevel(settings.debuggingEnabled
          ? fidl_web.ConsoleLogLevel.debug
          : fidl_web.ConsoleLogLevel.none);
    }
    return Future.value();
  }

  /// Clears all cookies for all [WebView] instances.
  ///
  /// Returns true if cookies were present before clearing, else false.
  static Future<bool> clearCookies() {
    throw UnimplementedError(
        'FuchsiaWebView clearCookies is not implemented on the current platform');
  }

  /// Close all remaining subscriptions and connections.
  void dispose() {
    for (final entry in _javascriptChannelSubscriptions.entries) {
      entry.value.cancel();
    }
    fuchsiaWebServices.dispose();
  }

  /// For each channel in [javascriptChannelNames] creates an object with the
  /// channel name on window in the frame. That object will contain a
  /// `postMessage` method. Messages sent through that method will be received
  /// here and notified back to the client of the webview.
  /// The process for each channel is:
  ///   1. Inject the script that will create the object on window to the
  ///      webview. This script will initially wait for a 'share-port' message.
  ///   2. postMessage 'share-port' to the frame.
  ///   3. The frame has a listener on window and will reply with a
  ///      share-port-ack and a port to which the frame will send messages.
  ///   4. Bind that port and start listening on it.
  ///   5. When a message arrives on that port it is sent to the client through
  ///      the platform callback.
  Future<void> _createChannelSubscriptions(
      Set<String> javascriptChannelNames) async {
    for (final channelName in javascriptChannelNames) {
      // Close any connections to that object (if any existed)
      if (_javascriptChannelSubscriptions.containsKey(channelName)) {
        await _javascriptChannelSubscriptions[channelName].cancel();
      }

      // Create a JavaScript object with one postMessage method. This object
      // will be exposed on window.$channelName when the FIDL communication is
      // established. Any window.$channelName already set will be removed.
      final script = _scriptForChannel(channelName);
      await evaluateJavascript(script);

      // Creates the message channel connection.
      fidl_web.MessagePortProxy incomingPort;
      try {
        incomingPort = await _bindIncomingPort();
      } on Exception catch (e) {
        log.warning('Failed to bind incoming port for $channelName: $e');
        continue;
      }

      // Subscribe for incoming messages.
      final incomingMessagesStream = _startReceivingMessages(incomingPort);
      _javascriptChannelSubscriptions[channelName] =
          incomingMessagesStream.listen(
        (message) async {
          _platformCallbacksHandler.onJavaScriptChannelMessage(
              channelName, message);
        },
      );
    }
  }

  /// Communicates with the script injected by `_scriptForChannel` to get a port
  /// from the web page with which to communicate with the page. See comments on
  /// `_createChannelSubscriptions` for details on the process.
  Future<fidl_web.MessagePortProxy> _bindIncomingPort() async {
    final messagePort = fidl_web.MessagePortProxy();
    await fuchsiaWebServices.postMessage('*', 'share-port',
        outgoingMessagePortRequest: messagePort.ctrl.request());

    final msg = await messagePort.receiveMessage();
    final ackMsg = utils.bufferToString(msg.data);
    if (ackMsg != 'share-port-ack') {
      throw Exception('Expected "share-port-ack", got: "$ackMsg"');
    }
    if (msg.incomingTransfer == null || msg.incomingTransfer.isEmpty) {
      throw Exception('failed to provide an incoming message port');
    }
    final incomingMessagePort = fidl_web.MessagePortProxy();
    incomingMessagePort.ctrl.bind(msg.incomingTransfer[0].messagePort);
    return incomingMessagePort;
  }

  /// Script injected to the frame to create an object with the given name on
  /// window. See comments on `_createChannelSubscriptions` for details on the
  /// process.
  String _scriptForChannel(String channelName) {
    return """
        (function() {
          function init$channelName(event) {
            if (event.data == 'share-port' && event.ports && event.ports.length > 0) {
              console.log("Registering channel $channelName");
              const messageChannel = new MessageChannel();
              event.ports[0].postMessage('share-port-ack', [messageChannel.port2]);
              window.$channelName = new $channelName(messageChannel);
              window.removeEventListener('message', init$channelName, true);
            }
          }

          window.addEventListener('message', init$channelName, true);

          class $channelName {
            constructor(messageChannel) {
              this._messageChannel = messageChannel;
            }

            postMessage(message) {
              this._messageChannel.port1.postMessage(message);
            }
          }

          window.$channelName = undefined;
        })();
      """;
  }

  /// Listens for messages on the incoming port and streams them.
  Stream<String> _startReceivingMessages(
      fidl_web.MessagePortProxy incomingMessagePort) async* {
    // ignore: literal_only_boolean_expressions
    while (true) {
      try {
        final msg = await incomingMessagePort.receiveMessage();
        yield utils.bufferToString(msg.data);
      } on fidl.FidlError {
        // Occurs when the incoming port is closed (ie navigate to another page).
        break;
      }
    }
  }
}
