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

enum _LayoutId { historyButtons, url }

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
            fontFamily: 'RobotoMono',
            textSelectionColor: textColor.withOpacity(0.38),
            textSelectionHandleColor: textColor,
            hintColor: textColor,
            cursorColor: textColor,
            canvasColor: bgColor,
            textTheme: TextTheme(
              body1: TextStyle(color: textColor),
              subhead: TextStyle(color: textColor),
            ),
          ),
          child: child,
        );
      },
      child: Material(
        child: SizedBox(
          height: 26.0,
          child: _buildWidgets(),
        ),
      ),
    );
  }

  Widget _buildWidgets() {
    return CustomMultiChildLayout(
      delegate: _LayoutDelegate(),
      children: [
        LayoutId(
          id: _LayoutId.historyButtons,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHistoryButton(
                title: 'BCK',
                onTap: () => widget.bloc.request.add(GoBackAction()),
                enabledStateStream: widget.bloc.backState,
              ),
              SizedBox(width: 8.0),
              _buildHistoryButton(
                title: 'FWD',
                onTap: () => widget.bloc.request.add(GoForwardAction()),
                enabledStateStream: widget.bloc.forwardState,
              ),
            ],
          ),
        ),
        LayoutId(id: _LayoutId.url, child: _buildNavigationField()),
      ],
    );
  }

  Widget _buildHistoryButton({
    @required String title,
    @required VoidCallback onTap,
    @required Stream<bool> enabledStateStream,
  }) {
    return StreamBuilder<bool>(
      stream: enabledStateStream,
      initialData: false,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data;
        return GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Opacity(
                opacity: isEnabled ? 1.0 : 0.54,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationField() {
    return TextField(
      focusNode: _focusNode,
      controller: _controller,
      cursorWidth: 7,
      cursorRadius: Radius.zero,
      cursorColor: Colors.black,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.url,
      style: TextStyle(fontSize: 14.0),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        hintText: '<search>',
        border: InputBorder.none,
        isDense: true,
      ),
      onSubmitted: (value) =>
          widget.bloc.request.add(NavigateToAction(url: value)),
      textInputAction: TextInputAction.go,
    );
  }
}

class _LayoutDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final buttonsSize = layoutChild(
      _LayoutId.historyButtons,
      BoxConstraints.tightFor(height: size.height),
    );
    positionChild(_LayoutId.historyButtons, Offset.zero);

    final urlSize = layoutChild(
      _LayoutId.url,
      BoxConstraints.tightFor(width: size.width - buttonsSize.width * 2),
    );
    positionChild(
      _LayoutId.url,
      Offset(
        (size.width - urlSize.width) * 0.5,
        (size.height - urlSize.height) * 0.5,
      ),
    );
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => false;
}
