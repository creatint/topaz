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
    _initValues();
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
          inspectNode: _inspectNode.child('home-page')),
    );
  }

  /// Initializes the [Inspect] values for this widget.
  void _initValues() {
    _inspectNode.stringValue('app-color').setValue('$_appColor');
  }
}

class _InspectHomePage extends StatefulWidget {
  final String title;
  final inspect.Node inspectNode;

  _InspectHomePage({Key key, this.title, this.inspectNode}) : super(key: key) {
    inspectNode.stringValue('title').setValue(title);
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

  /// A value that tracks [_counter].
  final inspect.IntValue _counterValue;

  inspect.StringValue _backgroundValue;

  int _counter = 0;
  int _colorIndex = 0;

  _InspectHomePageState(this._inspectNode)
      : _counterValue = _inspectNode.intValue('counter') {
    _backgroundValue = _inspectNode.stringValue('background-color')
      ..setValue('$_backgroundColor');
  }

  Color get _backgroundColor => _colors[_colorIndex];

  void _incrementCounter() {
    setState(() {
      _counter++;

      // Note: an alternate approach that is also valid is to set the value to
      // the new value:
      //
      //     _counterValue.value = _counter;
      _counterValue.add(1);
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
      _counterValue.subtract(1);
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

        // Contrived example of removing an Inspect value:
        // Once we've looped through the colors once, delete the value.
        //
        // A more realistic example would be if something were being removed
        // from the UI, but this is intended to be super simple.
        _backgroundValue.delete();
        _backgroundValue = null;
      }

      _backgroundValue?.setValue('$_backgroundColor');
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
