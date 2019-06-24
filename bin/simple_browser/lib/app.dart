// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_scenic_flutter/child_view.dart' show ChildView;
import 'src/blocs/browser_bloc.dart';
import 'src/widgets/navigation_bar.dart';

const double _kTabBarHeight = 24.0;
const double _kPageTabWidth = 144.0;
const double _kAddTabWidth = 36.0;

class App extends StatefulWidget {
  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final _browserTabs = <BrowserBloc>[];
  int _currentTab = 0;

  AppState() {
    _browserTabs.add(BrowserBloc());
  }

  @override
  void dispose() {
    for (final tab in _browserTabs) {
      tab.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Column(
            children: <Widget>[
              _buildTabs(),
              NavigationBar(bloc: _browserTabs[_currentTab]),
              Expanded(
                child: ChildView(
                  connection: _browserTabs[_currentTab].childViewConnection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: _kTabBarHeight,
      color: Colors.black,
      child: Row(
        children: <Widget>[..._buildPageTabs(), _buildPlusTab()],
      ),
    );
  }

  Iterable<Widget> _buildPageTabs() => _browserTabs.asMap().entries.map(
        (entry) => _buildTab(
            // TODO(MS-2371): get page title from browser_bloc
            title: 'TAB ${entry.key}',
            selected: entry.key == _currentTab,
            onSelect: () {
              setState(() {
                _currentTab = entry.key;
              });
            }),
      );

  Widget _buildPlusTab() => _buildTab(
        title: '+',
        selected: false,
        width: _kAddTabWidth,
        onSelect: () {
          setState(() {
            _browserTabs.add(
              BrowserBloc(),
            );
            _currentTab = _browserTabs.length - 1;
          });
        },
      );

  Widget _buildTab({
    String title,
    bool selected,
    VoidCallback onSelect,
    double width = _kPageTabWidth,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: width,
        color: selected ? Colors.white : Colors.black,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.black : Color(0xFF8A8A8A),
            ),
          ),
        ),
      ),
    );
  }
}
