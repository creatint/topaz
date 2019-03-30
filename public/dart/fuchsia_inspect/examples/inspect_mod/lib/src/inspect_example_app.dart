// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_inspect/inspect.dart';

/// A Flutter app that demonstrates usage of the [Inspect] API.
class InspectExampleApp extends StatelessWidget {
  static const _appColor = Colors.blue;

  final Inspect _inspect;

  InspectExampleApp(this._inspect) {
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
