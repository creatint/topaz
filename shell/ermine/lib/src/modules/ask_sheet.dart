// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show max, min;

import 'package:flutter/material.dart';

import 'ask_model.dart';
import 'ask_suggestion_list.dart';
import 'ask_text_field.dart';

const _kDefaultListHeight = 320.0;
const _kAskFieldHeight = 88.0;

class AskSheet extends StatefulWidget {
  final AskModel model;

  const AskSheet({@required this.model});

  @override
  _AskSheetState createState() => _AskSheetState();
}

enum _ExpandStatus { expanded, expanding, collapsed, collapsing }
_ExpandStatus _expandStatusForAnimationStatus(AnimationStatus status) {
  switch (status) {
    case AnimationStatus.completed:
      return _ExpandStatus.expanded;
    case AnimationStatus.dismissed:
      return _ExpandStatus.collapsed;
    case AnimationStatus.forward:
      return _ExpandStatus.expanding;
    case AnimationStatus.reverse:
      return _ExpandStatus.collapsing;
    default:
      return null;
  }
}

class _AskSheetState extends State<AskSheet> with TickerProviderStateMixin {
  ScrollController _scrollController;
  _ExpandStatus _expandedState;

  bool get _expanded =>
      _expandedState == _ExpandStatus.expanded ||
      _expandedState == _ExpandStatus.expanding;

  /// The initial velocity for the next fling animation.
  /// This is changed by [_DismissablePhysics] when starting the ballistics simulation,
  /// and return to default when the animation starts.
  double _dismissVelocity = 1.0;

  AnimationController _expandedAnimationController;
  Animation<double> _translateAnimation;
  final _translateTween = Tween<double>(
    // TODO(ahetzroni): update begin value based on number of items
    begin: -(_kDefaultListHeight + _kAskFieldHeight),
    end: 0,
  );

  @override
  void initState() {
    _expandedState = widget.model.isVisible
        ? _ExpandStatus.expanded
        : _ExpandStatus.collapsed;

    _scrollController = ScrollController();

    _expandedAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
      value: _expanded ? 1 : 0,
    )..addStatusListener((status) {
        setState(() {
          _expandedState = _expandStatusForAnimationStatus(status);
        });
        _updateFocus();
        if (_expandedState == _ExpandStatus.collapsed) {
          // currently invisible, reset ui and update model that hide animation is complete
          _reset();
          widget.model.hideAnimationCompleted();
        }
      });

    _translateAnimation = _translateTween.animate(_expandedAnimationController);

    widget.model.visibility.addListener(_visibilityListener);

    super.initState();
  }

  void _updateFocus() {
    if (_expanded) {
      widget.model.focus(context);
    } else {
      widget.model.unfocus();
    }
  }

  void _reset() {
    _scrollController.jumpTo(0);
  }

  void _runAnimationController(bool expand) {
    double dismissVelocity = _dismissVelocity;
    _dismissVelocity = 1;
    _expandedAnimationController.fling(
      // Set a minimum velocity above zero so the animation will not go in the
      // wrong direction when collpasing but being flung slightly towards the expand direction.
      // This is needed due to the implementation of fling that doesn't offer a distinction
      // between initial velocity and animation direction
      velocity: max(dismissVelocity, 0.01) * (expand ? 1 : -1),
    );
  }

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0.0;
  double get _maxScrollExtent => _scrollController.hasClients
      ? _scrollController.position.maxScrollExtent
      : 0.0;

  /// Sets dismiss velocity before beginning collapse.
  /// velocity is in aboslute pixels and is converted here.
  void _close({double velocity}) {
    _dismissVelocity = velocity == null
        ? 1
        : velocity / (_translateTween.begin - _translateTween.end);
    widget.model.hide();
  }

  void _visibilityListener() {
    _runAnimationController(widget.model.isVisible);
  }

  @override
  void dispose() {
    _expandedAnimationController.dispose();
    _scrollController.dispose();
    widget.model.visibility.removeListener(_visibilityListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Offstage(
        offstage: _expandedState == _ExpandStatus.collapsed,
        child: IgnorePointer(
          ignoring: !_expanded,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildExpandAnimationWidget(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AskTextField(model: widget.model),
                      _buildBody(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildBody() => Material(
        color: Colors.white,
        elevation: widget.model.elevation,
        child: Container(
          color: Colors.black,
          margin: const EdgeInsets.all(2.0),
          child: AnimatedSize(
            vsync: this,
            curve: Curves.easeOutExpo,
            alignment: Alignment.topRight,
            duration: Duration(milliseconds: 300),
            child: AnimatedBuilder(
              animation: widget.model.suggestions,
              builder: (_, child) => SizedBox(
                    height: min(
                      _kDefaultListHeight,
                      AskSuggestionList.kListItemHeight *
                          widget.model.suggestions.value.length,
                    ),
                    child: child,
                  ),
              child: CustomScrollView(
                controller: _scrollController,
                physics: _DismissablePhysics(onDismiss: _close),
                slivers: <Widget>[AskSuggestionList(model: widget.model)],
              ),
            ),
          ),
        ),
      );

  Widget _buildExpandAnimationWidget({Widget child}) => AnimatedBuilder(
        animation: Listenable.merge([
          _translateAnimation,
          _scrollController,
        ]),
        builder: (_, child) {
          // any negative scroll offset is added here to make up for shrinkWrap
          // absorbing negative bounce in the scrollview.
          final dy = _translateAnimation.value +
              -min(_scrollOffset, 0.0) +
              -max(
                _scrollOffset - _maxScrollExtent,
                0,
              );
          return Transform.translate(
            offset: Offset(0, dy),
            child: child,
          );
        },
        child: child,
      );
}

/// [_DismissablePhysics] is an extension of [ScrollPhysics] that is parented with
/// both an [AlwaysScrollableScrollPhysics], [BouncingScrollPhysics].
///
/// [onDismiss] is called when the user flings the scrollview out of bounds, downwards
/// but only if the gesture was released while beyond those bounds.
///
/// This behavior means that a when a previously scrolled scrollview is flung towards it's
/// starting offset, it will first come to a stop at that position, and a second swipe will
/// be needed before it is dismissed.
class _DismissablePhysics extends ScrollPhysics {
  final void Function({double velocity}) onDismiss;

  _DismissablePhysics({
    @required this.onDismiss,
  })  : assert(onDismiss != null),
        super(
          parent: BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        );

  @override
  _DismissablePhysics applyTo(ScrollPhysics ancestor) {
    return _DismissablePhysics(onDismiss: onDismiss);
  }

  @override
  Simulation createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final estimatedTarget = position.pixels + velocity * 2.0;

    if (position.pixels > position.maxScrollExtent &&
        estimatedTarget > position.maxScrollExtent) {
      onDismiss(velocity: velocity);
      return null;
    } else {
      return parent.createBallisticSimulation(position, velocity);
    }
  }
}
