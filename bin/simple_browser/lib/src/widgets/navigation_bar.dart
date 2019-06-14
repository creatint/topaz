// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import '../blocs/browser_bloc.dart';
import '../models/browse_action.dart';

class NavigationBar extends StatefulWidget {
  final BrowserBloc bloc;

  const NavigationBar({this.bloc});

  @override
  _NavigationBarState createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  TextEditingController _controller;
  StreamSubscription _urlListener;

  @override
  void initState() {
    _controller = TextEditingController();
    _urlListener = widget.bloc.url.listen((url) {
      _controller.text = url;
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
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
        ));
  }

  Widget _buildNavigationField() {
    return Expanded(
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          filled: true,
          border: InputBorder.none,
          fillColor: Colors.white,
          hintText: 'Enter an address...',
        ),
        onSubmitted: (value) =>
            widget.bloc.request.add(NavigateToAction(url: value)),
        textInputAction: TextInputAction.go,
      ),
    );
  }
}
