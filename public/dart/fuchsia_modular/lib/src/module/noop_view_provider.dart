// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;
import 'package:zircon/zircon.dart';

import 'view_provider.dart';

/// A concrete implementation of the [ViewProvider] class. This class
/// is intended to be used to create a module that explicitly does not
/// provide a view. This is typically only the case in tests.
///
/// ```
/// void main() {
///   ModuleWithViewProviderImpl()
///    ..registerViewProvider(NoopViewProvider());
/// }
/// ```
class NoopViewProvider extends ViewProvider {
  @override
  Future<void> createView(
      EventPair token,
      InterfaceRequest<fidl_sys.ServiceProvider> incomingServices,
      InterfaceHandle<fidl_sys.ServiceProvider> outgoingServices) async {}
}
