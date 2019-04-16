// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import '../models/settings_model.dart';

/// Main view that shows all settings.
class AllSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<SettingsModel>(
      builder: (
        BuildContext context,
        Widget child,
        SettingsModel settingsModel,
      ) =>
          Scaffold(
            appBar: AppBar(
              title: Text('All Settings'),
            ),
            body: ListView(
              physics: BouncingScrollPhysics(),
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.wifi),
                  title: Text('Wi-Fi'),
                  subtitle: Text(settingsModel.wifiStatus),
                  onTap: () => Navigator.of(context).pushNamed('/wifi'),
                ),
                ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('Date & time'),
                  subtitle: Text(settingsModel.datetimeStatus),
                  onTap: () => Navigator.of(context).pushNamed('/datetime'),
                ),
                ListTile(
                  leading: Icon(Icons.settings_brightness),
                  title: Text('Display'),
                  onTap: () => Navigator.of(context).pushNamed('/display'),
                ),
                ListTile(
                  leading: Icon(Icons.accessibility),
                  title: Text('Accessibility'),
                  onTap: () =>
                      Navigator.of(context).pushNamed('/accessibility'),
                ),
                ListTile(
                  leading: Icon(Icons.touch_app),
                  title: Text('Experiments'),
                  onTap: () => Navigator.of(context).pushNamed('/experiments'),
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('System'),
                  subtitle: Text(
                    '${settingsModel.hostname} '
                        '${settingsModel.networkAddresses} '
                        '${settingsModel.buildInfo}',
                  ),
                  onTap: () => Navigator.of(context).pushNamed('/system'),
                ),
                ListTile(
                  leading: Icon(Icons.copyright),
                  title: Text('Show Open Source Licenses'),
                  onTap: () => Navigator.of(context).pushNamed('/licenses'),
                ),
              ],
            ),
          ),
    );
  }
}
