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
    runApp(_InspectExampleApp(Inspect(context)));
  }
}

class _InspectExampleApp extends StatelessWidget {
  static const _appColor = Colors.blue;

  final Inspect _inspect;

  _InspectExampleApp(this._inspect) {
    _initMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: _appColor);
  }

  /// Initializes the [Inspect] metrics for this widget.
  void _initMetrics() {
    _inspect.rootNode.createStringProperty('app-color').value = '$_appColor';
  }
}
