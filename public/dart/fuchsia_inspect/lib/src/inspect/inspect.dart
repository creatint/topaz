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
part 'property.dart';

/// Unless reconfigured, the VMO will be this size.
/// @nodoc
@visibleForTesting
const int defaultVmoSizeBytes = 256 * 1024;

/// Thrown when the programmer misuses Inspect.
class InspectStateError extends StateError {
  /// Constructor
  InspectStateError(String message) : super(message);
}

/// [Inspect] exposes a structured tree of internal component state.
///
/// The [Inspect] object maintains a hierarchy of [Node] objects whose data are
/// exposed for reading by specialized tools such as iquery.
///
/// The classes exposed by this library do not support reading.
abstract class Inspect {
  /// Size of the VMO that was / will be created.
  /// @nodoc
  static int vmoSize = defaultVmoSizeBytes;
  static InspectImpl _singleton;

  /// Maps an inspect instance name to the number of instantiations
  /// of that inspector. Used to deduplicate requests for
  /// similarly named inspectors.
  static Map<String, int> nameToInstanceCount;

  /// Returns a singleton [Inspect] instance at root.inspect
  factory Inspect() {
    if (_singleton == null) {
      var context = StartupContext.fromStartupInfo();
      var writer = VmoWriter.withSize(vmoSize);
      _singleton =
          InspectImpl(context.outgoing.debugDir(), 'root.inspect', writer);
    }
    return _singleton;
  }

  /// Returns a new Inspect object at <name>.inspect
  /// If it is called multiple times with the same name then
  /// a unique number will be appended after it
  ///
  /// Example:
  /// Inspect.named('test');
  /// Inspect.named('test');
  /// Results in "test.inspect" and "test_2.inspect"
  factory Inspect.named(String name) {
    nameToInstanceCount ??= <String, int>{};
    var context = StartupContext.fromStartupInfo();
    var writer = VmoWriter.withSize(vmoSize);
    if (!nameToInstanceCount.containsKey('$name')) {
      nameToInstanceCount['$name'] = 1;
      return InspectImpl(context.outgoing.debugDir(), '$name.inspect', writer);
    } else {
      int val = nameToInstanceCount['$name'] + 1;
      nameToInstanceCount['$name'] = val;
      return InspectImpl(
          context.outgoing.debugDir(), '${name}_$val.inspect', writer);
    }
  }

  /// Optionally configure global settings for inspection.
  ///
  /// This may not be called after the first call to Inspect().
  ///
  /// [vmoSizeBytes]: Sets the maximum size of the virtual memory object (VMO)
  /// used to store inspection data for this program.
  /// Must be at least 64 bytes.
  ///
  /// Throws [InspectStateError] if called after Inspect(), or [ArgumentError]
  /// if called with an invalid vmoSizeBytes.
  static void configure({int vmoSizeBytes}) {
    if (_singleton != null) {
      throw InspectStateError(
          'configureInspect cannot be called after factory runs');
    }
    if (vmoSizeBytes != null) {
      if (vmoSizeBytes < 64) {
        throw ArgumentError('VMO size must be at least 64 bytes.');
      }
      vmoSize = vmoSizeBytes;
    }
  }

  /// The root [Node] of this Inspect tree.
  ///
  /// This node can't be deleted; trying to delete it is a NOP.
  Node get root => _singleton.root;
}
