// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:inspect_dart_codelab_part_3_lib/reverser.dart';
// CODELAB: Include the inspect test module.

void main() {
  ReverserImpl openReverser() {
    // [START open_reverser]
    return ReverserImpl(ReverserStats.noop());
    // [END open_reverser]
  }

  test('reverser', () async {
    final reverser = openReverser();
    final result = await reverser.reverse('hello');
    expect(result, equals('olleh'));
    // CODELAB: assert that the inspect data is correct.
  });
}
