// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:fidl_fuchsia_ui_views/fidl_async.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:lib.settings/device_info.dart';
import 'package:lib.widgets/model.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:fuchsia_scenic_flutter/child_view.dart' show ChildView;
import 'package:fuchsia_scenic_flutter/child_view_connection.dart';

import 'settings_status.dart';

export 'package:lib.widgets/model.dart'
    show ScopedModel, Model, ScopedModelDescendant;

/// Model for settings view.
class SettingsModel extends Model {
  String _networkAddresses;

  SettingsStatus _settingsStatus;

  // Wi-Fi module.
  _CachedModule _wifiModule;

  // Datetime module.
  _CachedModule _datetimeModule;

  // Display module.
  _CachedModule _displayModule;

  // Accessibility module.
  _CachedModule _accessibilityModule;

  // Experiments module.
  _CachedModule _experimentsModule;

  /// Module for general device settings, including update.
  _CachedModule _deviceSettingsModule;

  DateTime _testDeviceSourceDate;

  /// Constructor.
  SettingsModel() {
    initialize();
  }

  // Exposed for testing.
  void initialize() {
    // Explicitly ignore intents
    Module().registerIntentHandler(NoopIntentHandler());
    _settingsStatus = SettingsStatus()..addListener(notifyListeners);
    _setNetworkAddresses();
  }

  /// Fetches and sets the addresses of all network interfaces delimited by space.
  Future<void> _setNetworkAddresses() async {
    var interfaces = await NetworkInterface.list();
    _networkAddresses = interfaces
        .expand((NetworkInterface interface) => interface.addresses)
        .map((InternetAddress address) => address.address)
        .join(' ');
    notifyListeners();
  }

  /// Returns the addresses of all network interfaces delimited by space.
  String get networkAddresses {
    return _networkAddresses;
  }

  /// Returns the hostname of the running device.
  String get hostname => Platform.localHostname;

  /// Returns the build info, if build info file is found on the system image.
  String get buildInfo {
    final DateTime buildTimeStamp = _testDeviceSourceDate != null
        ? _testDeviceSourceDate
        : DeviceInfo.getSourceDate();

    if (buildTimeStamp != null) {
      final builtAt =
          DateFormat('H:mm', 'en_US').format(buildTimeStamp).toLowerCase();
      final builtOn =
          DateFormat('MMM dd, yyyy', 'en_US').format(buildTimeStamp);
      // The time zone is hardcoded because DateFormat and DateTime currently doesn't
      // support time zones.
      return 'Built at $builtAt UTC on $builtOn';
    } else {
      log.warning('Last built time doesn\'t exist!');
    }
    return null;
  }

  /// Returns the wifi status.
  String get wifiStatus => _settingsStatus.wifiStatus;

  /// Returns the [EmbeddedModule] for Wi-Fi.
  ChildView get wifiModule {
    if (_wifiModule == null) {
      _embedSetting(
        name: 'wifi_settings',
        title: 'Wi-Fi',
      ).then((_CachedModule module) {
        _wifiModule = module;
        notifyListeners();
      });
    }
    return _wifiModule?.childView;
  }

  /// Returns the datetime status.
  String get datetimeStatus => _settingsStatus.timezoneStatus;

  /// Returns the [EmbeddedModule] for Date & Time.
  ChildView get datetimeModule {
    if (_datetimeModule == null) {
      _embedSetting(
        name: 'datetime_settings',
        title: 'Date & Time',
      ).then((_CachedModule module) {
        _datetimeModule = module;
        notifyListeners();
      });
    }
    return _datetimeModule?.childView;
  }

  /// Returns the [EmbeddedModule] for Experiments.
  ChildView get experimentsModule {
    if (_experimentsModule == null) {
      _embedSetting(
        name: 'experiments_setting',
        title: 'Experiments',
      ).then((_CachedModule module) {
        _experimentsModule = module;
        notifyListeners();
      });
    }
    return _experimentsModule?.childView;
  }

  /// Returns the [EmbeddedModule] for Display.
  ChildView get displayModule {
    if (_displayModule == null) {
      _embedSetting(
        name: 'display_settings',
        title: 'Display',
      ).then((_CachedModule module) {
        _displayModule = module;
        notifyListeners();
      });
    }
    return _displayModule?.childView;
  }

  /// Returns the [EmbeddedModule] for accessibility settings.
  ChildView get accessibilitySettingsModule {
    if (_accessibilityModule == null) {
      _embedSetting(
        name: 'accessibility_settings',
        title: 'Accessibility',
      ).then((_CachedModule module) {
        _accessibilityModule = module;
        notifyListeners();
      });
    }
    return _accessibilityModule?.childView;
  }

  /// Returns the [EmbeddedModule] for device settings.
  ChildView get deviceSettingsModule {
    if (_deviceSettingsModule == null) {
      _embedSetting(
        name: 'device_settings',
        title: 'System',
      ).then((_CachedModule module) {
        _deviceSettingsModule = module;
        notifyListeners();
      });
    }
    return _deviceSettingsModule?.childView;
  }

  Future<_CachedModule> _embedSetting({
    String name,
    String title,
  }) {
    final intent = Intent(
      action: '',
      handler: 'fuchsia-pkg://fuchsia.com/$name#meta/$name.cmx',
    );
    return Module()
        .embedModule(name: title, intent: intent)
        .then((m) => _CachedModule(m));
  }

  set testDeviceSourceDate(DateTime testDeviceSourceDate) =>
      _testDeviceSourceDate = testDeviceSourceDate;
}

/// A helper class which holds a reference to the [EmbeddedModule]
/// and creates the [childView] on demand.
class _CachedModule {
  final EmbeddedModule _embeddedModule;
  ChildView _childView;

  /// Returns an instance of the [ChildView] for this module.
  ChildView get childView {
    return _childView ??= _makeChildView();
  }

  _CachedModule(this._embeddedModule);

  ChildView _makeChildView() => ChildView(
      connection: ChildViewConnection(
          ViewHolderToken(value: _embeddedModule.viewHolderToken.value)));
}
