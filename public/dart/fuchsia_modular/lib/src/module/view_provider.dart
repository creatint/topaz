// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: one_member_abstracts

import 'package:fidl/fidl.dart';
import 'package:zircon/zircon.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;

/// An interface that allows clients to embed the view of a graphical
/// component, such as a [Module].
abstract class ViewProvider {
  /// Creates a new View under the control of the ViewProvider.
  ///
  /// `token` is one half of the shared eventpair which will bind the new View
  /// to its associated ViewHolder.  The ViewProvider will use `token` to
  /// create its internal View representation.  The caller is expected to use
  /// its half to create corresponding ViewHolder object.
  ///
  /// `incoming_services` allows clients to request services from the
  /// ViewProvider implementation.  `outgoing_services` allows clients to
  /// provide services of their own to the ViewProvider implementation.
  Future<void> createView(
      EventPair token,
      InterfaceRequest<fidl_sys.ServiceProvider> incomingServices,
      InterfaceHandle<fidl_sys.ServiceProvider> outgoingServices);
}
