// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

typedef void OnQuickSettingsProgressChange(double quickSettingsProgress);

/// Fraction of the minimization animation which should be used for falling away
/// and sliding in of the user context and battery icon.
const double _kFallAwayDurationFraction = 0.35;

/// The distance above the lowest point we can scroll down to when
/// [scrollOffset] is 0.0.
const double _kRestingDistanceAboveLowestPoint = 40.0;

/// Shows the user, the user's context, and important settings.  When minimized
/// also shows an affordance for seeing missed interruptions.
class Now extends StatefulWidget {
  final double minHeight;
  final double maxHeight;

  /// [scrolloffset] effects the bottom padding of the user and text elements
  /// as well as the overall height of [Now] while maximized.
  final double scrollOffset;
  final double quickSettingsHeightBump;
  final OnQuickSettingsProgressChange onQuickSettingsProgressChange;
  final VoidCallback onButtonTap;
  final Widget user;
  final Widget userContextMaximized;
  final Widget userContextMinimized;
  final Widget importantInfoMaximized;
  final Widget importantInfoMinimized;
  final Widget quickSettings;

  Now(
      {Key key,
      this.minHeight,
      this.maxHeight,
      this.scrollOffset,
      this.quickSettingsHeightBump,
      this.onQuickSettingsProgressChange,
      this.onButtonTap,
      this.user,
      this.userContextMaximized,
      this.userContextMinimized,
      this.importantInfoMaximized,
      this.importantInfoMinimized,
      this.quickSettings})
      : super(key: key);

  @override
  NowState createState() => new NowState();
}

/// Spring description used by the minimization and quick settings reveal
/// simulations.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

const double _kMinimizationSimulationTarget = 100.0;
const double _kQuickSettingsSimulationTarget = 100.0;

class NowState extends TickingState<Now> {
  /// The simulation for the minimization to a bar.
  final RK4SpringSimulation _minimizationSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kSimulationDesc);

  /// The simulation for the inline quick settings reveal.
  final RK4SpringSimulation _quickSettingsSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kSimulationDesc);

  /// As [Now] minimizes the user image goes from bottom center aligned to
  /// center aligned as it shrinks.
  final Tween<FractionalOffset> _userImageAlignment =
      new Tween<FractionalOffset>(
          begin: FractionalOffset.bottomCenter, end: FractionalOffset.center);

  @override
  Widget build(BuildContext context) => new GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!_minimizing) {
          if (!_revealingQuickSettings) {
            showQuickSettings();
          } else {
            hideQuickSettings();
          }
        }
      },
      child: new ConstrainedBox(
          constraints: new BoxConstraints.tightFor(
              height: _nowHeight + math.max(0.0, _scrollOffsetDelta)),
          child: new Padding(
              padding: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new Stack(children: [
                // Quick Settings background.
                new Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: _quickSettingsBackgroundBottomOffset,
                    child: new Center(child: new Container(
                        height: _quickSettingsBackgroundHeight,
                        width: _quickSettingsBackgroundWidth,
                        decoration: new BoxDecoration(
                            backgroundColor: new Color(0xFFFFFFFF),
                            borderRadius: new BorderRadius.circular(
                                _quickSettingsBackgroundBorderRadius))))),

                // Quick Settings.
                new Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: _quickSettingsBottomOffset,
                    child: new ConstrainedBox(
                        constraints: new BoxConstraints.tightFor(
                            width: _quickSettingsWidth,
                            height: _quickSettingsHeight),
                        child: new Opacity(
                            opacity: _quickSettingsSlideUpProgress,
                            child: config.quickSettings))),

                // User's Image.
                new Positioned(
                    left: 0.0,
                    right: 0.0,
                    top: 0.0,
                    bottom: _userImageBottomOffset,
                    child: new Align(
                        alignment:
                            _userImageAlignment.lerp(_minimizationProgress),
                        child: new Stack(children: [
                          new Opacity(
                              opacity: _quickSettingsProgress,
                              child: new Container(
                                  width: _userImageSize,
                                  height: _userImageSize,
                                  decoration: new BoxDecoration(
                                      boxShadow: kElevationToShadow[12],
                                      shape: BoxShape.circle))),
                          new ClipOval(child: new Container(
                              width: _userImageSize,
                              height: _userImageSize,
                              foregroundDecoration: new BoxDecoration(
                                  border: new Border.all(
                                      color: new Color(0xFFFFFFFF),
                                      width: _userImageBorderWidth),
                                  shape: BoxShape.circle),
                              child: config.user))
                        ]))),

                // User Context Text when maximized.
                new Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: _contextTextBottomOffset,
                    child: new Center(child: new Opacity(
                        opacity: _fallAwayOpacity,
                        child: config.userContextMaximized))),

                // Important Information when maximized.
                new Positioned(
                    left: 0.0,
                    right: 0.0,
                    bottom: _batteryBottomOffset,
                    child: new Center(child: new Opacity(
                        opacity: _fallAwayOpacity,
                        child: config.importantInfoMaximized))),

                // User Context Text when minimized.
                new Positioned(
                    bottom: 0.0,
                    left: _slideInDistance,
                    right: 0.0,
                    height: config.minHeight,
                    child: new Align(
                        alignment: FractionalOffset.centerLeft,
                        child: new Opacity(
                            opacity: _slideInProgress,
                            child: config.userContextMinimized))),

                // Important Information when minimized.
                new Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: _slideInDistance,
                    height: config.minHeight,
                    child: new Align(
                        alignment: FractionalOffset.centerRight,
                        child: new Opacity(
                            opacity: _slideInProgress,
                            child: config.importantInfoMinimized))),

                // Return To Origin Button.  This button is only enabled
                // when we're nearly fully minimized.
                new OffStage(
                    offstage: _buttonTapDisabled,
                    child: new Center(child: new GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: config.onButtonTap,
                        child: new Container(
                            width: config.minHeight,
                            height: config.minHeight))))
              ]))));

  @override
  bool handleTick(double elapsedSeconds) {
    bool continueTicking = false;

    // Tick the minimization simulation.
    _minimizationSimulation.elapseTime(elapsedSeconds);
    if (!_minimizationSimulation.isDone) {
      continueTicking = true;
    }

    // Tick the quick settings simulation.
    if (!_quickSettingsSimulation.isDone) {
      _quickSettingsSimulation.elapseTime(elapsedSeconds);
      if (!_quickSettingsSimulation.isDone) {
        continueTicking = true;
      }
      if (config.onQuickSettingsProgressChange != null) {
        config.onQuickSettingsProgressChange(_quickSettingsProgress);
      }
    }

    return continueTicking;
  }

  void minimize() {
    if (!_minimizing) {
      _minimizationSimulation.target = _kMinimizationSimulationTarget;
      startTicking();
    }
  }

  void maximize() {
    if (_minimizing) {
      _minimizationSimulation.target = 0.0;
      startTicking();
    }
  }

  void showQuickSettings() {
    if (!_revealingQuickSettings) {
      _quickSettingsSimulation.target = _kQuickSettingsSimulationTarget;
      startTicking();
    }
  }

  void hideQuickSettings() {
    if (_revealingQuickSettings) {
      _quickSettingsSimulation.target = 0.0;
      startTicking();
    }
  }

  double get _quickSettingsProgress =>
      _quickSettingsSimulation.value / _kQuickSettingsSimulationTarget;

  double get _minimizationProgress =>
      _minimizationSimulation.value / _kMinimizationSimulationTarget;

  bool get _minimizing =>
      _minimizationSimulation.target == _kMinimizationSimulationTarget;

  bool get _revealingQuickSettings =>
      _quickSettingsSimulation.target == _kQuickSettingsSimulationTarget;

  bool get _buttonTapDisabled =>
      _minimizationProgress < (1.0 - _kFallAwayDurationFraction);

  double get _nowHeight =>
      config.minHeight +
      ((config.maxHeight - config.minHeight) * (1.0 - _minimizationProgress)) +
      config.quickSettingsHeightBump * _quickSettingsProgress;

  double get _userImageSize => 100.0 - (88.0 * _minimizationProgress);

  double get _userImageBorderWidth => 2.0 + (4.0 * _minimizationProgress);

  double get _userImageBottomOffset =>
      160.0 * (1.0 - _minimizationProgress) +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _contextTextBottomOffset =>
      110.0 +
      _fallAwayDistance +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _batteryBottomOffset =>
      70.0 +
      _fallAwayDistance +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _quickSettingsBackgroundBorderRadius =>
      50.0 - 46.0 * _quickSettingsProgress;

  double get _quickSettingsBackgroundWidth =>
      424.0 * _quickSettingsProgress * (1.0 - _minimizationProgress);

  double get _quickSettingsBackgroundHeight =>
      (config.quickSettingsHeightBump + 80.0) *
      _quickSettingsProgress *
      (1.0 - _minimizationProgress);

  double get _restingDistanceAboveLowestPoint =>
      _kRestingDistanceAboveLowestPoint *
      (1.0 - _quickSettingsProgress) *
      (1.0 - _minimizationProgress);

  // TODO(apwilson): Make this calculation sane.  It appears it should depend
  // upon config.quickSettingsHeightBump.
  double get _quickSettingsBackgroundBottomOffset =>
      _userImageBottomOffset +
      (_userImageSize / 2.0) -
      _quickSettingsBackgroundHeight +
      (_userImageSize / 3.0) * (1.0 - _quickSettingsProgress) +
      (5.0 / 3.0 * _userImageSize * _minimizationProgress);

  double get _quickSettingsWidth => 400.0 - 32.0;
  double get _quickSettingsHeight =>
      config.quickSettingsHeightBump + 80.0 - 32.0;
  double get _quickSettingsBottomOffset =>
      136.0 + (16.0 * _quickSettingsSlideUpProgress);

  double get _fallAwayDistance => 10.0 * (1.0 - _fallAwayProgress);

  double get _fallAwayOpacity => (1.0 - _fallAwayProgress);

  double get _slideInDistance => 10.0 * (1.0 - _slideInProgress);

  double get _quickSettingsRaiseDistance =>
      config.quickSettingsHeightBump * _quickSettingsProgress;

  double get _scrollOffsetDelta =>
      (math.max(
                  -_kRestingDistanceAboveLowestPoint,
                  (-1.0 * config.scrollOffset / 3.0) *
                      (1.0 - _minimizationProgress) *
                      (1.0 - _quickSettingsProgress)) *
              1000.0)
          .truncateToDouble() /
      1000.0;

  /// We fall away the context text and important information for the initial
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _fallAwayProgress =>
      math.min(1.0, (_minimizationProgress / _kFallAwayDurationFraction));

  /// We slide in the context text and important information for the final
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _slideInProgress => math.max(
      0.0,
      ((_minimizationProgress - (1.0 - _kFallAwayDurationFraction)) /
          _kFallAwayDurationFraction));

  /// We slide up and fade in the quick settings for the final portion of the
  /// quick settings animation as determined by [_kFallAwayDurationFraction].
  double get _quickSettingsSlideUpProgress => math.max(
      0.0,
      ((_quickSettingsProgress - (1.0 - _kFallAwayDurationFraction)) /
          _kFallAwayDurationFraction));
}
