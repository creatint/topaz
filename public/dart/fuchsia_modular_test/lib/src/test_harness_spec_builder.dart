// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8, json;

import 'package:fidl_fuchsia_mem/fidl_async.dart' as fuchsia_mem;
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart';
import 'package:zircon/zircon.dart';

/// A class which aids in the building of [TestHarnessSpec] objects.
///
/// This class is used to build up the spec and then pass that to the
/// run method of the test harness.
/// ```
/// final builder = TestHarnessBuilder()
///   ..addComponentToIntercept(componentUrl);
/// await harness.run(builder.build());
/// ```
class TestHarnessSpecBuilder {
  final _componentsToIntercept = <InterceptSpec>[];

  /// Registers the component url to be intercepted.
  ///
  /// When a component with the given [componentUrl] is launched inside the
  /// hermetic environment it will not be launched by the system but rather
  /// passed to the [TestHarness]'s onNewComponent stream.
  ///
  /// Optionally, additional [services] can be provided which will be added
  /// to the intercepted components cmx file.
  void addComponentToIntercept(String componentUrl, {List<String> services}) {
    ArgumentError.checkNotNull(componentUrl, 'componentUrl');

    // verify that we have unique component urls
    for (final spec in _componentsToIntercept) {
      if (spec.componentUrl == componentUrl) {
        throw Exception(
            'Attempting to add [$componentUrl] twice. Component urls must be unique');
      }
    }

    final extraContents = <String, dynamic>{};
    if (services != null) {
      extraContents['services'] = services;
    }
    _componentsToIntercept.add(InterceptSpec(
        componentUrl: componentUrl,
        extraCmxContents: _createCmxSandBox(extraContents)));
  }

  /// Returns the [TestHarnessSpec] object which can be passed to the [TestHarnessProxy]
  TestHarnessSpec build() {
    return TestHarnessSpec(componentsToIntercept: _componentsToIntercept);
  }

  fuchsia_mem.Buffer _createCmxSandBox(Map<String, dynamic> contents) {
    if (contents.isEmpty) {
      return null;
    }
    final encodedContents = utf8.encode(json.encode({'sandbox': contents}));

    final vmo = SizedVmo.fromUint8List(encodedContents);
    return fuchsia_mem.Buffer(vmo: vmo, size: encodedContents.length);
  }
}
