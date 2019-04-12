// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer' show Timeline;

import 'package:flutter/material.dart';
import 'package:fuchsia_logger/logger.dart';

import 'src/models/settings_model.dart';
import 'src/widgets/all_settings.dart';

/// Main function of settings.
Future<Null> main() async {
  setupLogger(name: 'settings');
  Timeline.instantSync('settings starting');

  SettingsModel settingsModel = SettingsModel();

  Widget app = MaterialApp(
    home: AllSettings(),
    routes: <String, WidgetBuilder>{
      '/wifi': (BuildContext context) => _buildModule(
            'Wi-Fi',
            () => settingsModel.wifiModule,
          ),
      '/datetime': (BuildContext context) => _buildModule(
            'Date & Time',
            () => settingsModel.datetimeModule,
          ),
      '/display': (BuildContext context) => _buildModule(
            'Display',
            () => settingsModel.displayModule,
          ),
      '/accessibility': (BuildContext context) => _buildModule(
            'Accessibility',
            () => settingsModel.accessibilitySettingsModule,
          ),
      '/experiments': (BuildContext context) => _buildModule(
            'Experiments',
            () => settingsModel.experimentsModule,
          ),
      '/system': (BuildContext context) => _buildModule(
            'System',
            () => settingsModel.deviceSettingsModule,
          ),
      '/licenses': (BuildContext context) => LicensePage()
    },
  );

  app = ScopedModel<SettingsModel>(
    model: settingsModel,
    child: app,
  );

  runApp(app);

  Timeline.instantSync('settings started');
}

// Returns the [Scaffold] widget for the root view of the module.
Widget _buildModule(String title, Widget getModView()) {
  return ScopedModelDescendant<SettingsModel>(
    builder: (
      BuildContext context,
      Widget child,
      SettingsModel settingsModel,
    ) =>
        Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: getModView(),
        ),
  );
}
