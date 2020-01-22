// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_examples_inspect/fidl_async.dart' as fidl_codelab;
import 'package:fuchsia_inspect/inspect.dart' as inspect;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_services/services.dart';
import 'package:inspect_dart_codelab_part_5_lib/reverser.dart';

void main(List<String> args) async {
  setupLogger(name: 'inspect_dart_codelab', globalTags: ['part_5']);

  log.info('Starting up...');

  final inspector = inspect.Inspect();

  inspector.health.setStartingUp();

  inspector.root.stringProperty('version').setValue('part5');

  final context = StartupContext.fromStartupInfo();

  context.outgoing.addPublicService<fidl_codelab.Reverser>(
    ReverserImpl.getDefaultBinder(inspector.root.child('reverser_service')),
    fidl_codelab.Reverser.$serviceName,
  );

  final fizzBuzz = fidl_codelab.FizzBuzzProxy();
  context.incoming.connectToService(fizzBuzz);

  try {
    final result = await fizzBuzz.execute(30);
    inspector.health.setOk();
    log.info('Got FizzBuzz: $result');
  } on Exception catch (e) {
    inspector.health.setUnhealthy('FizzBuzz connection closed: $e');
  }
}
