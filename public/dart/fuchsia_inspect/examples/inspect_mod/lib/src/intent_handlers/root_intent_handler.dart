// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:fuchsia_services/services.dart';

class RootIntentHandler extends IntentHandler {
  @override
  void handleIntent(Intent intent) {
    var context = StartupContext.fromStartupInfo();

    // TODO(CF-602): Actually use this to track app attributes.
    Inspect(context);

    runApp(Container(color: Colors.blue));
  }
}
