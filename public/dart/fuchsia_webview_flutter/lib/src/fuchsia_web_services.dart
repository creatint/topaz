// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart' as fidl_io;
import 'package:fidl_fuchsia_mem/fidl_async.dart' as fidl_mem;
import 'package:fidl_fuchsia_web/fidl_async.dart' as fidl_web;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_scenic_flutter/child_view_connection.dart';
import 'package:fuchsia_services/services.dart';
import 'package:zircon/zircon.dart';
import 'package:fuchsia_scenic/views.dart';
import 'package:fuchsia_vfs/vfs.dart';

import 'utils.dart' as utils;

/// Helper class to help connect and interface with 'fuchsia.web.*' services.
class FuchsiaWebServices {
  final fidl_web.ContextProviderProxy _contextProviderProxy =
      fidl_web.ContextProviderProxy();
  final fidl_web.ContextProxy _contextProxy = fidl_web.ContextProxy();
  final fidl_web.FrameProxy _frameProxy = fidl_web.FrameProxy();
  final fidl_web.NavigationControllerProxy _navigationControllerProxy =
      fidl_web.NavigationControllerProxy();

  final fidl_web.NavigationEventListenerBinding
      _navigationEventObserverBinding =
      fidl_web.NavigationEventListenerBinding();

  ChildViewConnection _childViewConnection;

  /// Constructs [FuchsiaWebServices] and connects to various 'fuchsia.web.*`
  /// services.
  FuchsiaWebServices() {
    StartupContext.fromStartupInfo()
        .incoming
        .connectToService(_contextProviderProxy);

    // TODO(nkorsote): [service_directory] is effectively the sandbox inside
    // which the created Context will run. If you give it a direct handle to
    // component's /svc directory then it'll have access to everything the
    // component can access. Alternatively, refactor this to use an Outgoing
    // Directory.
    if (!Directory('/svc').existsSync()) {
      log.shout('no /svc directory');
      return;
    }
    final channel = Channel.fromFile('/svc');
    final directory = fidl_io.DirectoryProxy()
      ..ctrl.bind(InterfaceHandle<fidl_io.Directory>(channel));
    final composedDir =
        ComposedPseudoDir(directory: directory, inheritedNodes: [
      'fuchsia.fonts.Provider',
      'fuchsia.logger.LogSink',
      'fuchsia.media.Audio',
      'fuchsia.mediacodec.CodecFactory',
      'fuchsia.net.SocketProvider',
      'fuchsia.netstack.Netstack',
      'fuchsia.process.Launcher',
      'fuchsia.sysmem.Allocator',
      'fuchsia.ui.input.ImeService',
      'fuchsia.ui.input.ImeVisibilityService',
      'fuchsia.ui.scenic.Scenic',
      'fuchsia.vulkan.loader.Loader',
    ]);
    final pair = ChannelPair();
    composedDir.serve(InterfaceRequest<fidl_io.Node>(pair.first));

    final fidl_web.CreateContextParams contextParams =
        fidl_web.CreateContextParams(
            serviceDirectory: InterfaceHandle<fidl_io.Directory>(pair.second));

    _contextProviderProxy.create(contextParams, _contextProxy.ctrl.request());
    _contextProxy.createFrame(frame.ctrl.request());

    // Create token pair and pass one end to the webview and the other to child
    // view connection which will be used to construct the child view widget
    // that the webview will live in.
    final tokenPair = ViewTokenPair();
    frame.createView(tokenPair.viewToken);
    _childViewConnection = ChildViewConnection(tokenPair.viewHolderToken);
    frame.getNavigationController(_navigationControllerProxy.ctrl.request());
  }

  /// Sets the javascript log level for the frame.
  Future<void> setJavaScriptLogLevel(fidl_web.ConsoleLogLevel level) {
    return frame.setJavaScriptLogLevel(level);
  }

  /// Returns a connection to a child view.
  ///
  /// It can be used to construct a [ChildView] widget that will display the
  /// view's contents.
  ChildViewConnection get childViewConnection => _childViewConnection;

  /// Returns [fidl_web.NavigationControllerProxy]
  fidl_web.NavigationControllerProxy get navigationController =>
      _navigationControllerProxy;

  /// Returns [fidl_web.FrameProxy]
  fidl_web.FrameProxy get frame => _frameProxy;

  /// Preforms the all the necessary cleanup.
  void dispose() {
    _navigationControllerProxy.ctrl.close();
    _frameProxy.ctrl.close();
    _contextProxy.ctrl.close();
    _contextProviderProxy.ctrl.close();
  }

  /// Executes a UTF-8 encoded [script] in the frame if the frame's URL has
  /// an origin which matches entries in [origins].
  ///
  /// At least one [origins] entry must be specified.
  /// If a wildcard "*" is specified in [origins], then the script will be
  /// evaluated unconditionally.
  ///
  /// Note that scripts share the same execution context as the document,
  /// meaning that document may modify variables, classes, or objects set by
  /// the script in arbitrary or unpredictable ways.
  ///
  /// If an error occured, the FrameError will be set to one of these values:
  /// BUFFER_NOT_UTF8: [script] is not UTF-8 encoded.
  /// INVALID_ORIGIN: The Frame's current URL does not match any of the
  ///                 values in [origins] or [origins] is an empty vector.
  // TODO(crbug.com/900391): Investigate if we can run the scripts in
  // isolated JS worlds.
  Future<String> evaluateJavascript(List<String> origins, String script) async {
    final vmo = SizedVmo.fromUint8List(utf8.encode(script));
    final buffer = fidl_mem.Buffer(vmo: vmo, size: vmo.size);
    // TODO(nkosote): add catchError and decorate the error based on the error
    // code.
    // TODO(miguelfrde): replace with executeJavaScript once chromium rolls.
    await frame.executeJavaScriptNoResult(origins, buffer);
    final resultVmo = SizedVmo.fromUint8List(utf8.encode('1'));
    final resultBuffer = fidl_mem.Buffer(vmo: resultVmo, size: resultVmo.size);
    return utils.bufferToString(resultBuffer);
  }

  /// Posts a message to the [fidl_web.Frame]'s onMessage handler.
  ///
  /// [targetOrigin] restricts message delivery to the specified origin. If
  /// [targetOrigin] is "*", then the message will be sent to the document
  /// regardless of its origin.
  ///
  /// If an error occurred, the FrameError will be set to one of these values:
  /// - INTERNAL_ERROR: The WebEngine failed to create a message pipe.
  /// - BUFFER_NOT_UTF8: The script in [message]'s [fidl_web.WebMessage.data]
  ///   property is not UTF-8 encoded.
  /// - INVALID_ORIGIN: origins is an empty vector.
  /// - NO_DATA_IN_MESSAGE: The [fidl_web.WebMessage.data] property is missing
  ///   in [message].
  Future<void> postMessage(
    String targetOrigin,
    String message, {
    InterfaceRequest<fidl_web.MessagePort> outgoingMessagePortRequest,
  }) {
    final vmo = SizedVmo.fromUint8List(utf8.encode(message));
    var msg = fidl_web.WebMessage(
      data: fidl_mem.Buffer(vmo: vmo, size: vmo.size),
      outgoingTransfer: outgoingMessagePortRequest != null
          ? [
              fidl_web.OutgoingTransferable.withMessagePort(
                  outgoingMessagePortRequest)
            ]
          : null,
    );
    // TODO(nkosote): add catchError and decorate the error based on the error
    // code
    return frame.postMessage(targetOrigin, msg);
  }

  /// Sets the listener for handling page navigation events.
  ///
  /// The [observer] to use. Unregisters any existing listener if null.
  void setNavigationEventListener(fidl_web.NavigationEventListener observer) {
    frame.setNavigationEventListener(
        _navigationEventObserverBinding.wrap(observer));
  }
}
