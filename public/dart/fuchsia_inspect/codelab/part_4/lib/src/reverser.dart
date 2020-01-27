// Copyright 2020 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_examples_inspect/fidl_async.dart' as fidl_codelab;
import 'package:fuchsia_inspect/inspect.dart' as inspect;
import 'package:meta/meta.dart';

typedef BindCallback = void Function(InterfaceRequest<fidl_codelab.Reverser>);
typedef VoidCallback = void Function();

class ReverserStats {
  inspect.Node node;
  inspect.IntProperty globalRequestCount;

  ReverserStats(this.node, this.globalRequestCount) {
    node.intProperty('request_count').setValue(0);
    node.intProperty('response_count').setValue(0);
  }

  ReverserStats.noop() {
    node = inspect.Node.deleted();
    globalRequestCount = inspect.IntProperty.deleted();
  }

  inspect.IntProperty get requestCount => node.intProperty('request_count');
  inspect.IntProperty get responseCount => node.intProperty('response_count');

  void dispose() {
    node.delete();
  }
}

class ReverserImpl extends fidl_codelab.Reverser {
  final _binding = fidl_codelab.ReverserBinding();
  final ReverserStats stats;

  ReverserImpl(this.stats);

  @override
  Future<String> reverse(String value) async {
    stats.globalRequestCount.add(1);
    stats.requestCount.add(1);
    final result = String.fromCharCodes(value.runes.toList().reversed);
    stats.responseCount.add(1);
    return result;
  }

  static final _reversers = HashMap<String, ReverserImpl>();
  static BindCallback getDefaultBinder(inspect.Node node) {
    final globalRequestCount = node.intProperty('total_requests')..setValue(0);
    final glabalConnectionCount = node.intProperty('connection_count')
      ..setValue(0);
    return (InterfaceRequest<fidl_codelab.Reverser> request) {
      glabalConnectionCount.add(1);
      final name = inspect.uniqueName('connection');
      final stats = ReverserStats(node.child(name), globalRequestCount);
      final reverser = ReverserImpl(stats)
        ..bind(request, onClose: () {
          _reversers.remove(name);
        });
      _reversers[name] = reverser;
    };
  }

  void bind(
    InterfaceRequest<fidl_codelab.Reverser> request, {
    @required VoidCallback onClose,
  }) {
    _binding.stateChanges.listen((state) {
      if (state == InterfaceState.closed) {
        dispose();
        onClose();
      }
    });
    _binding.bind(this, request);
  }

  void dispose() {
    stats.dispose();
  }
}
