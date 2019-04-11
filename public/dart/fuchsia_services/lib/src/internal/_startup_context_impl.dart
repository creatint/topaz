// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart' as fidl_io;
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;
import 'package:fuchsia/fuchsia.dart';
import 'package:meta/meta.dart';
import 'package:zircon/zircon.dart';

import '../incoming.dart';
import '../outgoing.dart';
import '../startup_context.dart';

/// A concrete implementation of the [StartupContext] interface.
///
/// This class is not intended to be used directly by authors but instead
/// should be used by the [StartupContext] factory constructor.
class StartupContextImpl implements StartupContext {
  static const String _serviceRootPath = '/svc';

  /// The connection to the [fidl_sys.Launcher] proxy.
  ///
  /// Deprecated! instead connect to [fidl_sys.Launcher] via [incoming]
  // TODO(MS-2334): remove launcher from this class
  @override
  final fidl_sys.Launcher launcher;

  /// The [fidl_sys.ServiceProvider] which can be used to connect to the
  /// services exposed to the component on launch.
  //  TODO(MF-167): Remove from this class
  @override
  final fidl_sys.ServiceProvider environmentServices;

  /// Services that are available to this component.
  ///
  /// These services have been offered to this component by its parent or are
  /// ambiently offered by the Component Framework.
  @override
  final Incoming incoming;

  /// Services and data exposed to other components.
  ///
  /// Use [outgoing] to publish services and data to the component manager and
  /// other components.
  @override
  final Outgoing outgoing;

  /// Creates a new instance of [StartupContext].
  ///
  /// This constructor is rarely used directly. Instead, most clients create a
  /// startup context using [StartupContext.fromStartupInfo].
  StartupContextImpl(
      {@required this.incoming,
      @required this.outgoing,
      this.launcher,
      this.environmentServices})
      : assert(incoming != null),
        assert(outgoing != null);

  /// Creates a startup context from the process startup info.
  ///
  /// Returns a cached [StartupContext] instance associated with the currently
  /// running component if one was already created.
  ///
  /// Authors should use this method of obtaining the [StartupContext] instead
  /// of instantiating one on their own as it will bind and connect to all the
  /// underlying services for them.
  factory StartupContextImpl.fromStartupInfo() {
    final directoryProxy = fidl_io.DirectoryProxy();

    if (Directory(_serviceRootPath).existsSync()) {
      final channel = Channel.fromFile(_serviceRootPath);
      final directoryProxy = fidl_io.DirectoryProxy()
        ..ctrl.bind(InterfaceHandle<fidl_io.Directory>(channel));

      // Note takeOutgoingServices shouldn't be called more than once per pid
      final outgoingServicesHandle = MxStartupInfo.takeOutgoingServices();

      final incomingServices = Incoming(directoryProxy);
      return StartupContextImpl(
        incoming: incomingServices,
        outgoing: _getOutgoingFromHandle(outgoingServicesHandle),
        environmentServices: _getServiceProvider(incomingServices),
        launcher: _getLauncher(incomingServices),
      );
    }

    // The following is required to enable host side tests.
    return StartupContextImpl(
      incoming: Incoming(directoryProxy),
      outgoing: Outgoing(),
      environmentServices: fidl_sys.ServiceProviderProxy(),
      launcher: fidl_sys.LauncherProxy(),
    );
  }

  /// Creates a startup context from [fidl_sys.StartupInfo].
  ///
  /// Typically used for testing or by implementations of [fidl_sys.Runner] to
  /// obtain the [StartupContext] for components being run by the runner.
  factory StartupContextImpl.from(fidl_sys.StartupInfo startupInfo) {
    if (startupInfo == null) {
      throw ArgumentError.notNull('startupInfo');
    }

    final flat = startupInfo.flatNamespace;
    if (flat.paths.length != flat.directories.length) {
      throw Exception('The flat namespace in the given fuchsia.sys.StartupInfo '
          '[$startupInfo] is misconfigured');
    }
    Channel serviceRoot;
    for (var i = 0; i < flat.paths.length; ++i) {
      if (flat.paths[i] == _serviceRootPath) {
        serviceRoot = flat.directories[i];
        break;
      }
    }

    final dirProxy = fidl_io.DirectoryProxy();
    dirProxy.ctrl.bind(InterfaceHandle(serviceRoot));
    final incomingSvc = Incoming(dirProxy);

    Channel dirRequestChannel = startupInfo.launchInfo.directoryRequest;

    return StartupContextImpl(
      incoming: incomingSvc,
      outgoing: _getOutgoingFromChannel(dirRequestChannel),
      environmentServices: _getServiceProvider(incomingSvc),
      launcher: _getLauncher(incomingSvc),
    );
  }

  static Outgoing _getOutgoingFromHandle(Handle outgoingServicesHandle) {
    if (outgoingServicesHandle == null) {
      throw ArgumentError.notNull('outgoingServicesHandle');
    }
    final outgoingServices = Outgoing()
      ..serve(InterfaceRequest<fidl_io.Node>(Channel(outgoingServicesHandle)));
    return outgoingServices;
  }

  static Outgoing _getOutgoingFromChannel(Channel directoryRequestChannel) {
    if (directoryRequestChannel == null) {
      throw ArgumentError.notNull('directoryRequestChannel');
    }
    final outgoingServices = Outgoing()
      ..serve(InterfaceRequest<fidl_io.Node>(directoryRequestChannel));
    return outgoingServices;
  }

  //  TODO(MF-167): Remove from this class
  static fidl_sys.ServiceProviderProxy _getServiceProvider(
      Incoming incomingServices) {
    final environmentProxy = _getEnvironment(incomingServices);

    final serviceProviderProxy = fidl_sys.ServiceProviderProxy();
    environmentProxy.getServices(serviceProviderProxy.ctrl.request());
    return serviceProviderProxy;
  }

  static fidl_sys.Launcher _getLauncher(Incoming incomingServices) {
    final launcherProxy = fidl_sys.LauncherProxy();

    // TODO(MS-2334): Use launcher from incoming instead of env
    // incomingServices.connectToService(
    //  launcherProxy.ctrl.$serviceName, launcherProxy.ctrl.request().passChannel());

    _getEnvironment(incomingServices).getLauncher(launcherProxy.ctrl.request());
    return launcherProxy;
  }

  static fidl_sys.EnvironmentProxy _getEnvironment(Incoming incomingServices) {
    if (incomingServices == null) {
      throw ArgumentError.notNull('incomingServices');
    }
    final environmentProxy = fidl_sys.EnvironmentProxy();
    incomingServices.connectToService(environmentProxy);
    return environmentProxy;
  }
}
