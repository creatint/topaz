// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';

// Builds bar visualization given a value, fill amount, and maximum amount.
class StatusBarVisualizer extends StatelessWidget {
  // Descriptive text displayed to the right of bar visualization.
  final String _barValue;
  // Amount the bar visualization will be filled.
  final double _barFill;
  // Maximum amount the bar visualization can be filled.
  final double _barMax;
  // Maximum amount of tick marks allowed to be in row.
  final int _barSize;

  const StatusBarVisualizer(
      {@required String barValue,
      @required double barFill,
      @required double barMax,
      @required int barSize})
      : _barValue = barValue,
        _barFill = barFill,
        _barMax = barMax,
        _barSize = barSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          _drawTicks(_activeTicks()),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: -4,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          _drawTicks(_inactiveTicks()),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            letterSpacing: -4,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: _barSpace()),
        Text(
          _barValue,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'RobotoMono',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Determines how many active ticks to be drawn.
  int _activeTicks() => ((_barFill / _barMax) * _maxTicks()).toInt();

  // Determines how many inactive ticks to be drawn.
  int _inactiveTicks() => (_maxTicks() - _activeTicks());

  // Determines how many ticks can fit in row.
  int _maxTicks() => _barSize - _barValue.length;

  // Builds string of ticks.
  String _drawTicks(int numTicks) => List.filled(numTicks + 1, '').join('| ');

  // Adds space to align bar visualizations.
  double _barSpace() => _barValue.length % 2 == 0 ? 9 : 6;
}
