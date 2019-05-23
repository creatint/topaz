// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

// ignore_for_file: implementation_imports
import 'package:fidl_fuchsia_modular_testing/fidl_async.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_modular_test/src/test_harness_fixtures.dart';
import 'package:fuchsia_modular_test/src/test_harness_spec_builder.dart';
import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  setupLogger();

  group('spec builder', () {
    TestHarnessSpecBuilder builder;

    setUp(() {
      builder = TestHarnessSpecBuilder();
    });

    group('adding components', () {
      test('addComponentToIntercept fails on null component url', () {
        expect(
            () => builder.addComponentToIntercept(null), throwsArgumentError);
      });

      test('addComponentToIntercept fails on empty component url', () {
        expect(() => builder.addComponentToIntercept(''), throwsArgumentError);
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
        builder.addComponentToIntercept(generateComponentUrl(),
            services: [service]);

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

      test('can add additional components_to_intercept after build', () {
        expect(() => builder.build().componentsToIntercept.add(InterceptSpec()),
            returnsNormally);
      });
    });

    group('adding environment services to inherit', () {
      test('can add additional env_services_to_inherit after build', () {
        expect(() => builder.build().envServicesToInherit.add('foo'),
            returnsNormally);
      });

      test('automatically inherits logger service', () {
        expect(builder.build().envServicesToInherit,
            contains('fuchsia.logger.LogSink'));
      });

      test('throws argument error for null service', () {
        expect(() => builder.addEnvironmentServiceToInherit(null),
            throwsArgumentError);
      });

      test('throws argument error for empty service', () {
        expect(() => builder.addEnvironmentServiceToInherit(''),
            throwsArgumentError);
      });

      test('throws exception for duplicate service', () {
        builder.addEnvironmentServiceToInherit('service');
        expect(() => builder.addEnvironmentServiceToInherit('service'),
            throwsException);
      });

      test('addEnvServiceToInherit adds the service to the inherited services',
          () {
        builder.addEnvironmentServiceToInherit('fuchsia.my.Service');
        expect(builder.build().envServicesToInherit,
            contains('fuchsia.my.Service'));
      });
    });

    group('adding environment services to inject', () {
      test('can add additional env_services_to_inject after build', () {
        expect(
            () => builder
                .build()
                .envServicesToInject
                .add(InjectedService(name: 'foo', url: generateComponentUrl())),
            returnsNormally);
      });

      test('throws argument error for null input values', () {
        expect(
            () => builder.addEnvironmentServiceToInject(
                null, generateComponentUrl()),
            throwsArgumentError);
        expect(() => builder.addEnvironmentServiceToInject('name', null),
            throwsArgumentError);
      });

      test('throws argument error for empty name and component url', () {
        expect(
            () => builder.addEnvironmentServiceToInject(
                '', generateComponentUrl()),
            throwsArgumentError);
        expect(() => builder.addEnvironmentServiceToInject('name', ''),
            throwsArgumentError);
      });

      test('throws exception for duplicate service', () {
        const name = 'myService';
        final url = generateComponentUrl();

        builder.addEnvironmentServiceToInject(name, url);
        expect(() => builder.addEnvironmentServiceToInject(name, url),
            throwsException);
      });

      test('addEnvServiceToInject adds the service to the injected services',
          () {
        final url = generateComponentUrl();
        builder.addEnvironmentServiceToInject('fuchsia.my.Service', url);
        expect(builder.build().envServicesToInject,
            contains(InjectedService(name: 'fuchsia.my.Service', url: url)));
      });
    });
  });
}
