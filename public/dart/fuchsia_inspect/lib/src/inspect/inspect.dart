// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library topaz.public.dart.fuchsia_inspect.inspect.inspect;

import 'dart:typed_data';

import 'package:fuchsia_services/services.dart';
import 'package:meta/meta.dart';

import '../vmo/vmo_writer.dart';
import 'internal/_inspect_impl.dart';

part 'node.dart';
part 'metric.dart';
part 'property.dart';

const int _defaultVmoSizeBytes = 256 * 1024;

/// Inspect exposes a structured tree of internal component state in a VMO.
abstract class Inspect {
  /// Initializes an [Inspect] instance backed by a VMO of size [vmoSize] in
  /// bytes.
  factory Inspect([int vmoSize = _defaultVmoSizeBytes]) {
    var context = StartupContext.fromStartupInfo();
    var writer = VmoWriter.withSize(vmoSize);
    return InspectImpl(context, writer);
  }

  /// The root [Node] of this Inspect tree.
  Node get root;
}
