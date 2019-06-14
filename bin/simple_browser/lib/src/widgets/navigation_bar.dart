// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import '../blocs/browser_bloc.dart';
import '../models/browse_action.dart';

const _kBackgroundColor = Colors.black;
const _kBackgroundFocusedColor = Color(0xFFFF8BCB);

const _kTextColor = Colors.white;
const _kTextFocusedColor = Colors.black;

class NavigationBar extends StatefulWidget {
  final BrowserBloc bloc;

  const NavigationBar({this.bloc});

  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  FocusNode _focusNode;
  TextEditingController _controller;
  StreamSubscription _urlListener;

  @override
  void initState() {
    _focusNode = FocusNode();
    _controller = TextEditingController();
    _urlListener = widget.bloc.url.listen((url) {
      _controller.text = url;
    });
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _urlListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusNode,
      builder: (_, child) {
        final focused = _focusNode.hasFocus;
        final textColor = focused ? _kTextFocusedColor : _kTextColor;
        final bgColor = focused ? _kBackgroundFocusedColor : _kBackgroundColor;
        return AnimatedTheme(
          duration: Duration(milliseconds: 100),
          data: ThemeData(
            canvasColor: bgColor,
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: TextStyle(
                color: textColor,
              ),
            ),
            textTheme: TextTheme(
              subhead: TextStyle(
                color: textColor,
              ),
            ),
          ),
          child: child,
        );
      },
      child: Material(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: _buildWidgets(),
        ),
      ),
    );
  }

  Widget _buildWidgets() {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: StreamBuilder<bool>(
            stream: widget.bloc.backState,
            initialData: false,
            builder: (context, snapshot) => RaisedButton(
                  padding: EdgeInsets.all(4),
                  child: Text('BCK'),
                  color: Colors.grey[350],
                  disabledColor: Colors.grey[700],
                  onPressed: snapshot.data
                      ? () => widget.bloc.request.add(GoBackAction())
                      : null,
                ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: StreamBuilder<bool>(
            stream: widget.bloc.forwardState,
            initialData: false,
            builder: (context, snapshot) => RaisedButton(
                  padding: EdgeInsets.all(4),
                  child: Text('FWD'),
                  color: Colors.grey[350],
                  disabledColor: Colors.grey[700],
                  onPressed: snapshot.data
                      ? () => widget.bloc.request.add(GoForwardAction())
                      : null,
                ),
          ),
        ),
        _buildNavigationField(),
      ],
    );
  }

  Widget _buildNavigationField() {
    return Expanded(
      child: TextField(
        focusNode: _focusNode,
        controller: _controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          hintText: 'Enter an address...',
        ),
        onSubmitted: (value) =>
            widget.bloc.request.add(NavigateToAction(url: value)),
        textInputAction: TextInputAction.go,
      ),
    );
  }
}
