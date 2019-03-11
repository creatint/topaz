// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

import 'dart:async';
import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:zircon/zircon.dart';

/// Helper class to connect to incoming services.
///
/// These services have been offered to this component by its parent or are
/// ambiently offered by the Component Framework.
class Incoming {
  Directory _dirProxy;

  /// Initializes [Incoming] with a [Directory] that should be bound to `/svc`
  /// of this component.
  Incoming(Directory dir)
      : assert(dir != null),
        _dirProxy = dir;

  /// Connects to the incoming service specified by [serviceProxy].
  void connectToService<T>(AsyncProxy<T> serviceProxy) {
    if (serviceProxy == null) {
      throw ArgumentError.notNull('serviceProxy');
    }
    final String serviceName = serviceProxy.ctrl.$serviceName;
    if (serviceName == null) {
      throw Exception(
          "${serviceProxy.ctrl.$interfaceName}'s controller.\$serviceName must "
          'not be null. Check the FIDL file for a missing [Discoverable]');
    }

    // Creates an interface request and binds one of the channels. Binding this
    // channel prior to connecting to the agent allows the developer to make
    // proxy calls without awaiting for the connection to actually establish.
    final serviceProxyRequest = serviceProxy.ctrl.request();

    connectToServiceByNameWithChannel(
        serviceName, serviceProxyRequest.passChannel());
  }

  /// Connects to the incoming service specified by [serviceProxy] through the
  /// [channel] endpoint supplied by the caller.
  ///
  /// If the service provider is not willing or able to provide the requested
  /// service, it should close the [channel].
  void connectToServiceWithChannel<T>(
      AsyncProxy<T> serviceProxy, Channel channel) {
    if (serviceProxy == null) {
      throw ArgumentError.notNull('serviceProxy');
    }
    if (channel == null) {
      throw ArgumentError.notNull('channel');
    }
    final String serviceName = serviceProxy.ctrl.$serviceName;
    if (serviceName == null) {
      throw Exception(
          "${serviceProxy.ctrl.$interfaceName}'s controller.\$serviceName must "
          'not be null. Check the FIDL file for a missing [Discoverable]');
    }
    connectToServiceByNameWithChannel(serviceName, channel);
  }

  /// Connects to the incoming service specified by [serviceName] through the
  /// [channel] endpoint supplied by the caller.
  ///
  /// If the service provider is not willing or able to provide the requested
  /// service, it should close the [channel].
  void connectToServiceByNameWithChannel(String serviceName, Channel channel) {
    if (serviceName == null) {
      throw Exception(
          'serviceName must not be null. Check the FIDL file for a missing '
          '[Discoverable]');
    }
    if (channel == null) {
      throw ArgumentError.notNull('channel');
    }

    // connection flags for service: can read & write from target object.
    const int _openFlags = openRightReadable | openRightWritable;
    // 0755
    const int _openMode = 0x1ED;

    _dirProxy.open(
        _openFlags, _openMode, serviceName, InterfaceRequest<Node>(channel));
  }

  /// Terminates connection and return Zircon status.
  Future<int> close() async {
    return _dirProxy.close();
  }
}
