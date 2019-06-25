// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import '../blocs/tabs_bloc.dart';
import '../models/tabs_action.dart';

const double _kTabBarHeight = 24.0;
const double _kPageTabWidth = 144.0;
const double _kAddTabWidth = 36.0;

class TabsWidget extends StatelessWidget {
  final TabsBloc bloc;
  const TabsWidget({@required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kTabBarHeight,
      color: Colors.black,
      child: AnimatedBuilder(
        animation: Listenable.merge([bloc.tabs, bloc.currentTab]),
        builder: (_, __) => Row(
          children: <Widget>[..._buildPageTabs(), _buildPlusTab()],
        ),
      ),
    );
  }

  Iterable<Widget> _buildPageTabs() => bloc.tabs.value.asMap().entries.map(
        (entry) => _buildTab(
          // TODO(MS-2371): get page title from webpage_bloc
          title: 'TAB ${entry.key}',
          selected: entry.value == bloc.currentTab.value,
          onSelect: () {
            bloc.request.add(FocusTabAction(tab: entry.value));
          },
        ),
      );

  Widget _buildPlusTab() => _buildTab(
      title: '+',
      selected: false,
      width: _kAddTabWidth,
      onSelect: () {
        bloc.request.add(NewTabAction());
      });

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
