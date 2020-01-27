// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fuchsia_inspect/inspect.dart' as inspect;
import 'package:fuchsia_inspect/testing.dart';
import 'package:test/test.dart';
import 'package:inspect_dart_codelab_part_5_lib/reverser.dart';

void main() {
  ReverserImpl openReverser(
    inspect.Node node,
    inspect.IntProperty globalRequestCount,
  ) {
    return ReverserImpl(ReverserStats(node, globalRequestCount));
  }

  test('reverser', () async {
    final vmo = FakeVmoHolder(256 * 1024);
    final inspector = inspect.Inspect.forTesting(vmo, 'root.inspect');
    final node = inspector.root.child('reverser_service');
    final globalRequestCount = node.intProperty('total_requests')..setValue(0);

    final reverser0 =
        openReverser(node.child('connection0'), globalRequestCount);
    final reverser1 =
        openReverser(node.child('connection1'), globalRequestCount);

    final result1 = await reverser0.reverse('hello');
    expect(result1, equals('olleh'));

    final result2 = await reverser0.reverse('world');
    expect(result2, equals('dlrow'));

    final result3 = await reverser1.reverse('another');
    expect(result3, equals('rehtona'));

    final matcher = VmoMatcher(vmo);

    var reverserServiceNode = matcher.node().at(['reverser_service']);
    expect(
        reverserServiceNode.propertyEquals('total_requests', 3), hasNoErrors);
    expect(
        reverserServiceNode.at(['connection0'])
          ..propertyEquals('request_count', 2)
          ..propertyEquals('response_count', 2),
        hasNoErrors);
    expect(
        reverserServiceNode.at(['connection1'])
          ..propertyEquals('request_count', 1)
          ..propertyEquals('response_count', 1),
        hasNoErrors);

    reverser0.dispose();

    reverserServiceNode = matcher.node().at(['reverser_service']);
    expect(
        reverserServiceNode.propertyEquals('total_requests', 3), hasNoErrors);
    expect(reverserServiceNode..missingChild('connection0'), hasNoErrors);
    expect(
        reverserServiceNode.at(['connection1'])
          ..propertyEquals('request_count', 1)
          ..propertyEquals('response_count', 1),
        hasNoErrors);
  });
}
