// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_examples_inspect/fidl_async.dart' as fidl_codelab;
import 'package:fuchsia_inspect/inspect.dart' as inspect;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_services/services.dart';
import 'package:inspect_dart_codelab_part_2_lib/reverser.dart';

void main(List<String> args) async {
  setupLogger(name: 'inspect_dart_codelab', globalTags: ['part_2']);

  log.info('Starting up...');

  final inspector = inspect.Inspect();

  inspector.root.stringProperty('version').setValue('part2');

  final context = StartupContext.fromStartupInfo();

  context.outgoing.addPublicService<fidl_codelab.Reverser>(
    ReverserImpl.getDefaultBinder(inspector.root.child('reverser_service')),
    fidl_codelab.Reverser.$serviceName,
  );

  final fizzBuzz = fidl_codelab.FizzBuzzProxy();
  context.incoming.connectToService(fizzBuzz);

  // CODELAB: Instrument our connection to FizzBuzz using Inspect. Is there an error?
  try {
    final result = await fizzBuzz.execute(30);
    // CODELAB: Add Inspect here to see if there is a response.
    log.info('Got FizzBuzz: $result');
  } on Exception {
    // CODELAB: Add Inspect here to see if there is an error
  }
}
