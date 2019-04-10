// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_inspect/inspect.dart' as inspect;

/// A Flutter app that demonstrates usage of the [Inspect] API.
class InspectExampleApp extends StatelessWidget {
  static const _appColor = Colors.blue;

  final inspect.Node _inspect;

  InspectExampleApp(this._inspect) {
    _initMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspect Example',
      theme: ThemeData(
        primarySwatch: _appColor,
      ),
      home: _InspectHomePage(title: 'Hello Inspect!'),
    );
  }

  /// Initializes the [Inspect] metrics for this widget.
  void _initMetrics() {
    _inspect.createStringProperty('app-color').value = '$_appColor';
  }
}

class _InspectHomePage extends StatefulWidget {
  final String title;

  _InspectHomePage({Key key, this.title}) : super(key: key);

  @override
  _InspectHomePageState createState() => _InspectHomePageState();
}

class _InspectHomePageState extends State<_InspectHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
      ),
      body: Center(
        child: Text(
          'Button tapped $_counter time${_counter == 1 ? '' : 's'}.',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
