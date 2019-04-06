// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_ledger/fidl.dart' as ledger;

import '../document/change.dart';
import '../ledger_helpers.dart';

/// changes to Ledger.
class Subscription extends ledger.PageWatcher {
  final ledger.PageProxy _pageProxy;
  final ledger.PageSnapshotProxy _snapshotProxy;
  final ledger.PageWatcherBinding _pageWatcherBinding;
  final void Function(Change change) _applyChangeCallback;
  final Change _currentChange = Change();

  /// Register a watcher for Ledger page, which pass all changes to
  /// _applyChangeCallback.
  Subscription(this._pageProxy, LedgerObjectsFactory ledgerObjectsFactory,
      this._applyChangeCallback)
      : _snapshotProxy = ledgerObjectsFactory.newPageSnapshotProxy(),
        _pageWatcherBinding = ledgerObjectsFactory.newPageWatcherBinding() {
    _pageProxy.getSnapshotNew(
      _snapshotProxy.ctrl.request(),
      Uint8List(0),
      _pageWatcherBinding.wrap(this),
    );
  }

  @override
  void onChange(ledger.PageChange pageChange, ledger.ResultState resultState,
      void callback(InterfaceRequest<ledger.PageSnapshot> snapshotRequest)) {
    _currentChange.addAll(getChangeFromPageChange(pageChange));

    // For a given change, [onChange] can be called multiple times.
    if (resultState == ledger.ResultState.completed ||
        resultState == ledger.ResultState.partialCompleted) {
      _applyChangeCallback(_currentChange);
      _currentChange.clear();
    }

    callback(null);
  }

  /// Ends subscription.
  void unsubscribe() {
    _pageWatcherBinding?.close();
    _snapshotProxy.ctrl.close();
  }
}
