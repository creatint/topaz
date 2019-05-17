// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

// ignore_for_file: implementation_imports
import 'package:test/test.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_modular_test/src/test_harness_spec_builder.dart';
import 'package:fuchsia_modular_test/src/test_harness_fixtures.dart';
import 'package:zircon/zircon.dart';

void main() {
  setupLogger();

  group('spec builder', () {
    TestHarnessSpecBuilder builder;

    setUp(() {
      builder = TestHarnessSpecBuilder();
    });

    test('addComponentToIntercept fails on null component url', () {
      expect(() => builder.addComponentToIntercept(null), throwsArgumentError);
    });

    test('addComponentToIntercept adds to the spec', () {
      final url = generateComponentUrl();
      builder.addComponentToIntercept(url);

      final spec = builder.build();
      expect(spec.componentsToIntercept,
          contains(predicate((ispec) => ispec.componentUrl == url)));
    });

    test('able to add many components', () {
      builder
        ..addComponentToIntercept(generateComponentUrl())
        ..addComponentToIntercept(generateComponentUrl());

      expect(builder.build().componentsToIntercept.length, 2);
    });

    test('componentUrl can only be added once', () {
      final url = generateComponentUrl();
      builder.addComponentToIntercept(url);
      expect(() => builder.addComponentToIntercept(url), throwsException);
    });

    test('can add services to the components cmx file', () {
      const service = 'fuchsia.sys.Launcher';
      builder
          .addComponentToIntercept(generateComponentUrl(), services: [service]);

      final spec = builder.build();
      final interceptSpec = spec.componentsToIntercept.first;
      final contents = interceptSpec.extraCmxContents;
      final vmo = SizedVmo(contents.vmo.handle, contents.size);
      final bytes = vmo.read(contents.size).bytesAsUint8List();

      final expectedSandbox = {
        'sandbox': {
          'services': [service]
        }
      };

      expect(expectedSandbox, json.decode(utf8.decode(bytes)));
    });
  });
}
