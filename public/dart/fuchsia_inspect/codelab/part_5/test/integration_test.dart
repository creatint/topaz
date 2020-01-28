// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:fidl_fuchsia_diagnostics/fidl_async.dart';
import 'package:fidl_fuchsia_examples_inspect/fidl_async.dart' as fidl_codelab;
import 'package:fidl_fuchsia_mem/fidl_async.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';
import 'package:inspect_codelab_shared/codelab_environment.dart';
import 'package:zircon/zircon.dart';

void main() {
  CodelabEnvironment env;

  Future<fidl_codelab.ReverserProxy> startComponentAndConnect({
    bool includeFizzbuzz = false,
  }) async {
    if (includeFizzbuzz) {
      await env.startFizzBuzz();
    }

    const serverName = 'inspect_dart_codelab_part_5';
    const reverserUrl =
        'fuchsia-pkg://fuchsia.com/$serverName#meta/$serverName.cmx';
    return await env.startReverser(reverserUrl);
  }

  String readBuffer(Buffer buffer) {
    final dataVmo = SizedVmo(buffer.vmo.handle, buffer.size);
    final data = dataVmo.read(buffer.size);
    return utf8.decode(data.bytesAsUint8List());
  }

  Future<Map<String, dynamic>> getInspectHierarchy() async {
    final archive = ArchiveProxy();
    StartupContext.fromStartupInfo().incoming.connectToService(archive);

    final reader = ReaderProxy();
    final List<SelectorArgument> selectors = [];
    await archive.readInspect(reader.ctrl.request(), selectors);

    // ignore: literal_only_boolean_expressions
    while (true) {
      final iterator = BatchIteratorProxy();
      await reader.getSnapshot(Format.json, iterator.ctrl.request());
      final batch = await iterator.getNext();
      for (final entry in batch) {
        final jsonData = readBuffer(entry.formattedJsonHierarchy);
        if (jsonData.contains('inspect_dart_codelab_part_5') &&
            jsonData.contains('fuchsia.inspect.Health') &&
            !jsonData.contains('STARTING_UP')) {
          return json.decode(jsonData);
        }
      }
      iterator.ctrl.close();
      await Future.delayed(Duration(milliseconds: 150));
    }
  }

  setUp(() async {
    env = CodelabEnvironment();
    await env.create();
  });

  tearDown(() async {
    env.dispose();
  });

  test('start with fizzbuzz', () async {
    final reverser = await startComponentAndConnect(includeFizzbuzz: true);
    final result = await reverser.reverse('hello');
    reverser.ctrl.close();
    expect(result, equals('olleh'));

    final inspectData = await getInspectHierarchy();
    expect(inspectData['contents']['root']['fuchsia.inspect.Health']['status'],
        'OK');
  });

  test('start without fizzbuzz', () async {
    final reverser = await startComponentAndConnect(includeFizzbuzz: false);
    final result = await reverser.reverse('hello');
    reverser.ctrl.close();
    expect(result, equals('olleh'));

    final inspectData = await getInspectHierarchy();
    final healthNode =
        inspectData['contents']['root']['fuchsia.inspect.Health'];
    expect(healthNode['status'], 'UNHEALTHY');
    expect(healthNode['message'], 'FizzBuzz connection closed');
  });
}
