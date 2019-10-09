// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO: investigate whether we can get rid of the implementation_imports.
// ignore_for_file: implementation_imports
import 'package:fuchsia_logger/logger.dart';
import 'package:sledge/sledge.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  setupLogger();

  test('Verify that onChangeCallback is called.', () async {
    // Create schema.
    Map<String, BaseType> schemaDescription = <String, BaseType>{
      'someInteger': Integer()
    };
    Schema schema = Schema(schemaDescription);

    Sledge sledge = newSledgeForTesting();
    int callsToCallback = 0;
    sledge.onChangeCallback = () {
      callsToCallback++;
    };

    // Create a new Sledge document. Verify that the callback is called.
    final id = DocumentId(schema);
    await sledge.runInTransaction(() async {
      await sledge.getDocument(id);
    });
    expect(callsToCallback, equals(1));

    // Run a transaction that does nothing. Verify that the callback is *not* called.
    await sledge.runInTransaction(() async {});
    expect(callsToCallback, equals(1));

    // Write to the document. Verify that the callback is called.
    await sledge.runInTransaction(() async {
      final doc = await sledge.getDocument(id);
      doc['someInteger'].value = 3;
    });
    expect(callsToCallback, equals(2));
  });
}
