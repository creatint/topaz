// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:zircon/zircon.dart';

import 'incoming.dart';

/// Deprecated - Facilitate the ability to connect to services outside of the
/// Modular Framework, for example via a command-line tool.
///
/// The user is responsible to launch a component and wire up a connection
/// between the new launched component and the request returned from this
/// [ServicesConnection.request()]. This is typically done using
/// [StartupContext#launcher].
///
/// For Module Framework APIs see `package:fuchsia_modular`
///
/// Deprecated, instead use
/// `StartupContext.fromStartupInfo().incoming.connectToService`
// TODO(MS-2335) remove this class
class ServicesConnector {
  Incoming _incoming;

  /// Creates a interface request, binds one of the channels to this object, and
  /// returns the other channel.
  ///
  /// Note: previously returned [Channel] will no longer be associate with this
  /// object.
  Channel request() {
    final _dirProxy = DirectoryProxy();
    _incoming = Incoming(_dirProxy);
    return _dirProxy.ctrl.request().passChannel();
  }

  /// Connects the most recently returned [Channel] from [request()] with the
  /// provided services represented by its [controller].
  // TODO(MS-2335) remove this class
  Future<void> connectToService<T>(AsyncProxyController<T> controller) async {
    final String serviceName = controller.$serviceName;
    if (serviceName == null) {
      throw Exception(
          "${controller.$interfaceName}'s controller.\$serviceName must "
          'not be null. Check the FIDL file for a missing [Discoverable]');
    }
    _incoming.connectToServiceByNameWithChannel(
        controller.$serviceName, controller.request().passChannel());
  }

  /// Terminates connection and return Zircon status.
  Future<int> close() async {
    return _incoming.close();
  }
}
