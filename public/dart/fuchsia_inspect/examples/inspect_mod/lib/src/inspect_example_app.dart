// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_inspect/inspect.dart' as inspect;

/// A Flutter app that demonstrates usage of the [Inspect] API.
class InspectExampleApp extends StatelessWidget {
  static const _appColor = Colors.blue;

  final inspect.Node _inspectNode;

  InspectExampleApp(this._inspectNode) {
    _initMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspect Example',
      theme: ThemeData(
        primarySwatch: _appColor,
      ),
      home: _InspectHomePage(
          title: 'Hello Inspect!',
          inspectNode: _inspectNode.createChild('home-page')),
    );
  }

  /// Initializes the [Inspect] metrics for this widget.
  void _initMetrics() {
    _inspectNode.createStringProperty('app-color').value = '$_appColor';
  }
}

class _InspectHomePage extends StatefulWidget {
  final String title;
  final inspect.Node inspectNode;

  _InspectHomePage({Key key, this.title, this.inspectNode}) : super(key: key) {
    inspectNode.createStringProperty('title').value = title;
  }

  @override
  _InspectHomePageState createState() => _InspectHomePageState(inspectNode);
}

class _InspectHomePageState extends State<_InspectHomePage> {
  /// Possible background colors.
  static const _colors = [
    Colors.white,
    Colors.lime,
    Colors.orange,
  ];

  final inspect.Node _inspectNode;

  inspect.StringProperty _backgroundProperty;

  int _counter = 0;
  int _colorIndex = 0;

  _InspectHomePageState(this._inspectNode) {
    _backgroundProperty = _inspectNode.createStringProperty('background-color')
      ..value = '$_backgroundColor';
  }

  Color get _backgroundColor => _colors[_colorIndex];

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
    });
  }

  /// Increments through the possible [_colors].
  ///
  /// If we've reached the end, start over at the beginning.
  void _changeBackground() {
    setState(() {
      _colorIndex++;

      if (_colorIndex >= _colors.length) {
        _colorIndex = 0;

        // Contrived example of removing an Inspect property:
        // Once we've looped through the colors once, remove the property.
        //
        // A more realistic example would be if something were being removed
        // from the UI, but this is intended to be super simple.
        _backgroundProperty.remove();
        _backgroundProperty = null;
      }

      _backgroundProperty?.value = '$_backgroundColor';
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
      backgroundColor: _backgroundColor,
      body: Center(
        child: Text(
          'Counter: $_counter.',
        ),
      ),
      persistentFooterButtons: <Widget>[
        FlatButton(
          onPressed: _changeBackground,
          child: Text('Change background color'),
        ),
        FlatButton(
          onPressed: _incrementCounter,
          child: Text('Increment counter'),
        ),
        FlatButton(
          onPressed: _decrementCounter,
          child: Text('Decrement counter'),
        ),
      ],
    );
  }
}
