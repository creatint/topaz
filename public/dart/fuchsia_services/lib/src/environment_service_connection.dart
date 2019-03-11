// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';

import 'startup_context.dart';

/// Deprecated: Connects to the environment service specified by [serviceProxy].
///
/// Environment services are services that are implemented by the framework
/// itself.
///
/// Deprecated, instead use
/// `StartupContext.fromStartupInfo().incoming.connectToService`
// TODO(MS-2335) remove this class
void connectToEnvironmentService<T>(AsyncProxy<T> serviceProxy) {
  StartupContext.fromStartupInfo().incoming.connectToService(serviceProxy);
}
