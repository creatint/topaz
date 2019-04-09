// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'child_scene_layer.dart';

typedef ChildViewConnectionCallback = void Function(
    ChildViewConnection connection);
typedef ChildViewConnectionStateCallback = void Function(
    ChildViewConnection connection, bool newState);

/// A connection with a child view.
///
/// Used with the [ChildView] widget to display a child view.
class ChildViewConnection {
  // TODO consider providing this API after MS-2293 is fixed
  // factory ChildViewConnection.launch(String url, Launcher launcher,
  //     {InterfaceRequest<ComponentController> controller,
  //     InterfaceRequest<ServiceProvider> childServices,
  //     ChildViewConnectionCallback onConnected,
  //     ChildViewConnectionCallback onDisconnected}) {
  //   final Services services = Services();
  //   final LaunchInfo launchInfo =
  //       LaunchInfo(url: url, directoryRequest: services.request());
  //   try {
  //     launcher.createComponent(launchInfo, controller);
  //     return ChildViewConnection.connect(services,
  //         childServices: childServices,
  //         onConnected: onConnected,
  //         onDisconnected: onDisconnected);
  //   } finally {
  //     services.close();
  //   }
  // }

  // TODO consider providing this API after MS-2293 is fixed
  // factory ChildViewConnection.connect(Services services,
  //     {InterfaceRequest<ServiceProvider> childServices,
  //     ChildViewConnectionCallback onConnected,
  //     ChildViewConnectionCallback onDisconnected}) {
  // final app.ViewProviderProxy viewProvider = app.ViewProviderProxy();
  // services.connectToService(viewProvider.ctrl);
  // try {
  //   EventPairPair viewTokens = EventPairPair();
  //   assert(viewTokens.status == ZX.OK);

  //   viewProvider.createView(viewTokens.second, childServices, null);
  //   return ChildViewConnection.fromViewHolderToken(viewTokens.first,
  //       onConnected: onConnected, onDisconnected: onDisconnected);
  //   } finally {
  //     viewProvider.ctrl.close();
  //   }
  // }

  // Status callbacks.
  final ChildViewConnectionCallback _onConnectedCallback;
  final ChildViewConnectionCallback _onDisconnectedCallback;
  final ChildViewConnectionStateCallback _onStateChangedCallback;
  VoidCallback _onViewInfoAvailable;

  // Token and SceneHost used to reference and render content from a remote
  // Scene.
  ViewHolderToken _viewHolderToken;
  SceneHost _sceneHost;

  // The number of render objects attached to this view. In between frames, we
  // might have more than one connected if we get added to a render object
  // before we get removed from the old render object. By the time we get around
  // to computing our layout, we must be back to just having one render object.
  int _attachments = 0;
  bool get _attached => _attachments > 0;

  /// Creates this connection from a ViewHolderToken.
  ChildViewConnection(ViewHolderToken viewHolderToken,
      {ChildViewConnectionCallback onAvailable,
      ChildViewConnectionCallback onUnavailable,
      ChildViewConnectionStateCallback onStateChanged})
      : _onConnectedCallback = onAvailable,
        _onDisconnectedCallback = onUnavailable,
        _onStateChangedCallback = onStateChanged,
        _viewHolderToken = viewHolderToken {
    assert(_viewHolderToken?.value != null);
  }

  /// Only call when the connection is available.
  void requestFocus() {
    // TODO(SCN-1186): Use new mechanism to implement RequestFocus.
  }

  /// Callback that is fired when the |ChildViewConnection|'s View is connected.
  void _onConnected() {
    if (_onViewInfoAvailable != null) {
      _onViewInfoAvailable();
    }
    if (_onConnectedCallback != null) {
      _onConnectedCallback(this);
    }
  }

  /// Callback that is fired when the |ChildViewConnection|'s View is disconnected.
  void _onDisconnected() {
    if (_onDisconnectedCallback != null) {
      _onDisconnectedCallback(this);
    }
  }

  /// Callback that is fired when the |ChildViewConnection|'s View changes state.
  void _onStateChanged(bool newState) {
    if (_onStateChangedCallback != null) {
      _onStateChangedCallback(this, newState);
    }
  }

  void _attach() {
    if (_sceneHost == null) {
      assert(!_attached);
      assert(_viewHolderToken.value.isValid);
      _sceneHost = SceneHost.fromViewHolderToken(
          _viewHolderToken.value.passHandle(),
          _onConnected,
          _onDisconnected,
          _onStateChanged);
    }
    ++_attachments;
  }

  void _detach() {
    assert(_attached);
    --_attachments;
  }

  void _setChildProperties(
    double width,
    double height,
    double insetTop,
    double insetRight,
    double insetBottom,
    double insetLeft,
    bool focusable,
  ) {
    assert(_attached);
    assert(_attachments == 1);

    _sceneHost.setProperties(
        width, height, insetTop, insetRight, insetBottom, insetLeft, focusable);
  }
}

/// A |RenderBox| that allows hit-testing and focusing of a |ChildViewConnection|.
class RenderChildView extends RenderBox {
  ChildViewConnection _connection;

  bool _hitTestable;
  bool _focusable;

  double _width;
  double _height;

  /// Creates a child view render object.
  RenderChildView({
    ChildViewConnection connection,
    bool hitTestable = true,
    bool focusable = true,
  })  : _connection = connection,
        _hitTestable = hitTestable,
        _focusable = focusable,
        assert(hitTestable != null);

  /// The child to display.
  ChildViewConnection get connection => _connection;
  set connection(ChildViewConnection value) {
    if (value == _connection) {
      return;
    }
    if (attached && _connection != null) {
      _connection._detach();
      assert(_connection._onViewInfoAvailable != null);
      _connection._onViewInfoAvailable = null;
    }
    _connection = value;
    if (attached && _connection != null) {
      _connection._attach();
      assert(_connection._onViewInfoAvailable == null);
      _connection._onViewInfoAvailable = markNeedsPaint;
    }
    if (_connection == null) {
      markNeedsPaint();
    } else {
      markNeedsLayout();
    }
  }

  /// Whether this child should be able to recieve focus events
  bool get focusable => _focusable;

  set focusable(bool value) {
    assert(value != null);
    if (value == _focusable) {
      return;
    }
    _focusable = value;
    if (_connection != null) {
      markNeedsLayout();
    }
  }

  /// Whether this child should be included during hit testing.
  bool get hitTestable => _hitTestable;

  set hitTestable(bool value) {
    assert(value != null);
    if (value == _hitTestable) {
      return;
    }
    _hitTestable = value;
    if (_connection != null) {
      markNeedsLayout();
    }
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
      DiagnosticsProperty<ChildViewConnection>(
        'connection',
        connection,
      ),
    );
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_connection != null) {
      _connection._attach();
      assert(_connection._onViewInfoAvailable == null);
      _connection._onViewInfoAvailable = markNeedsPaint;
    }
  }

  @override
  void detach() {
    if (_connection != null) {
      _connection._detach();
      assert(_connection._onViewInfoAvailable != null);
      _connection._onViewInfoAvailable = null;
    }
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Ignore if we have no child view connection.
    assert(needsCompositing);
    if (_connection == null) {
      return;
    }

    context.addLayer(ChildSceneLayer(
      offset: offset,
      width: _width,
      height: _height,
      sceneHost: _connection._sceneHost,
      hitTestable: hitTestable,
    ));
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    // Ignore if we have no child view connection.
    if (_connection == null) {
      return;
    }

    if (_width != null && _height != null) {
      double deltaWidth = (_width - size.width).abs();
      double deltaHeight = (_height - size.height).abs();

      // Ignore insignificant changes in size that are likely rounding errors.
      if (deltaWidth < 0.0001 && deltaHeight < 0.0001) {
        return;
      }
    }

    _width = size.width;
    _height = size.height;
    _connection._setChildProperties(
        _width, _height, 0.0, 0.0, 0.0, 0.0, _focusable);
  }
}
