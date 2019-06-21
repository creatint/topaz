// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:fuchsia_inspect/inspect.dart' as inspect;
import 'package:fuchsia_modular/module.dart';
import 'package:flutter/material.dart';
import 'roachGame.dart';

class RootIntentHandler extends IntentHandler {
  @override
  void handleIntent(Intent intent) {
    var inspectNode = inspect.Inspect().root;
    runApp(RoachGame(inspectNode: inspectNode));
  }
}
