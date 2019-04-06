// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

/// A version of app.dart built on the new async bindings.

import 'dart:async';
import 'package:fidl/fidl.dart';
import 'package:fuchsia/fuchsia.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:zircon/zircon.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';

import 'app.dart' as sync_app;
import 'src/outgoing.dart';

export 'src/outgoing.dart';

/// Deprecated! Use package:fuchsia_services/services.dart instead
class StartupContext {
  static StartupContext _context;

  StartupContext();

  final EnvironmentProxy environment = EnvironmentProxy();
  final LauncherProxy launcher = LauncherProxy();
  final ServiceProviderProxy environmentServices = ServiceProviderProxy();
  final Outgoing outgoingServices = Outgoing();

  factory StartupContext.fromStartupInfo() {
    if (_context != null) {
      return _context;
    }

    if (sync_app.StartupContext.initialTrace != null) {
      print(
          "WARNING: app.dart's StartupContext was created at:\n${sync_app.StartupContext.initialTrace}");
    }

    final StartupContext context = StartupContext();

    final Handle environmentHandle = MxStartupInfo.takeEnvironment();
    if (environmentHandle != null) {
      context.environment
        ..ctrl.bind(
            InterfaceHandle<Environment>(Channel(environmentHandle)))
        ..getLauncher(context.launcher.ctrl.request())
        ..getServices(context.environmentServices.ctrl.request());
    }

    final Handle outgoingServicesHandle = MxStartupInfo.takeOutgoingServices();
    if (outgoingServicesHandle != null) {
      context.outgoingServices
          .serve(InterfaceRequest<Node>(Channel(outgoingServicesHandle)));
    }

    _context = context;

    return context;
  }

  /// Provide an alternative startup context that will then be provided on
  /// through [StartupContext.fromStartupInfo].
  ///
  /// This is primarily used to provide alternative environment services for
  /// testing purposes.
  static void provideStartupContext(StartupContext context) {
    assert(_context != null, 'StartupContext should never be overwritten.');
    _context = context;
  }

  void close() {
    environment.ctrl.close();
    launcher.ctrl.close();
    environmentServices.ctrl.close();
    outgoingServices.close();
  }
}

/// Deprecated! Use package:fuchsia_services/services.dart instead
Future<void> connectToService<T>(
    ServiceProvider serviceProvider, AsyncProxyController<T> controller) async {
  final String serviceName = controller.$serviceName;
  if (serviceName == null) {
    throw Exception(
        "${controller.$interfaceName}'s controller.\$serviceName"
        ' must not be null. Check the FIDL file for a missing [Discoverable]');
  }
  await serviceProvider.connectToService(
      serviceName, controller.request().passChannel());
}

/// Deprecated! Use package:fuchsia_services/services.dart instead
InterfaceHandle<T> connectToServiceByName<T>(
    ServiceProvider serviceProvider, String serviceName) {
  final ChannelPair pair = ChannelPair();
  serviceProvider.connectToService(serviceName, pair.first);
  return InterfaceHandle<T>(pair.second);
}

typedef ServiceConnector<T> = void Function(InterfaceRequest<T> request);
typedef DefaultServiceConnector<T> = void Function(
    String serviceName, InterfaceRequest<T> request);

typedef _ServiceConnectorThunk = void Function(Channel channel);

/// Deprecated! Use package:fuchsia_services/services.dart instead
class ServiceProviderImpl extends ServiceProvider {
  final ServiceProviderBinding _binding = ServiceProviderBinding();

  void bind(InterfaceRequest<ServiceProvider> interfaceRequest) {
    _binding.bind(this, interfaceRequest);
  }

  void close() {
    _binding.close();
  }

  DefaultServiceConnector<dynamic> defaultConnector;

  final Map<String, _ServiceConnectorThunk> _connectorThunks =
      <String, _ServiceConnectorThunk>{};

  void addServiceForName<T>(ServiceConnector<T> connector, String serviceName) {
    _connectorThunks[serviceName] = (Channel channel) {
      connector(InterfaceRequest<T>(channel));
    };
  }

  @override
  Future<Null> connectToService(String serviceName, Channel channel) {
    final _ServiceConnectorThunk connectorThunk = _connectorThunks[serviceName];
    if (connectorThunk != null) {
      connectorThunk(channel);
    } else if (defaultConnector != null) {
      defaultConnector(serviceName, InterfaceRequest<dynamic>(channel));
    } else {
      channel.close();
    }
    return null;
  }
}

/// Deprecated! Use package:fuchsia_services/services.dart instead
class Services {
  DirectoryProxy _proxy;
  static const int _openFlags =
      openRightReadable | openRightWritable; // connect flags for service
  static const int _openMode = 0x1ED; // 0755

  Services();

  Channel request() {
    _proxy = DirectoryProxy();
    return _proxy.ctrl.request().passChannel();
  }

  Future<void> connectToService<T>(AsyncProxyController<T> controller) async {
    final String serviceName = controller.$serviceName;
    if (serviceName == null) {
      throw Exception(
          "${controller.$interfaceName}'s controller.\$serviceName"
          ' must not be null. Check the FIDL file for a missing [Discoverable]');
    }
    await _proxy.open(_openFlags, _openMode, serviceName,
        InterfaceRequest<Node>(controller.request().passChannel()));
  }

  Future<InterfaceHandle<T>> connectToServiceByName<T>(
      String serviceName) async {
    final ChannelPair pair = ChannelPair();

    await _proxy.open(
        _openFlags, _openMode, serviceName, InterfaceRequest<Node>(pair.first));
    return InterfaceHandle<T>(pair.second);
  }

  Future<void> close() async {
    await _proxy.close();
  }
}
