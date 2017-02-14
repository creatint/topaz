// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'nothing.dart';
import 'optional_wrapper.dart';
import 'panel.dart';
import 'simulated_fractionally_sized_box.dart';
import 'simulated_padding.dart';
import 'simulated_transform.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';
import 'story_full_size_simulated_sized_box.dart';
import 'story_model.dart';
import 'story_positioned.dart';

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Set to true to give the focused tab twice the space as an unfocused tab.
const bool _kGrowFocusedTab = false;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatefulWidget {
  final StoryCluster storyCluster;
  final double focusProgress;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Map<StoryId, Widget> storyWidgets;
  final bool paintShadows;
  final Size currentSize;

  StoryPanels({
    Key key,
    this.storyCluster,
    this.focusProgress,
    this.overlayKey,
    this.storyWidgets,
    this.paintShadows: false,
    this.currentSize,
  })
      : super(key: key) {
    assert(() {
      Panel.haveFullCoverage(
        storyCluster.stories
            .map(
              (Story story) => story.panel,
            )
            .toList(),
      );
      return true;
    });
  }

  @override
  StoryPanelsState createState() => new StoryPanelsState();
}

class StoryPanelsState extends State<StoryPanels> {
  @override
  void initState() {
    super.initState();
    config.storyCluster.addPanelListener(_onPanelsChanged);
  }

  @override
  void didUpdateConfig(StoryPanels oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      oldConfig.storyCluster.removePanelListener(_onPanelsChanged);
      config.storyCluster.addPanelListener(_onPanelsChanged);
    }
  }

  @override
  void dispose() {
    config.storyCluster.removePanelListener(_onPanelsChanged);
    super.dispose();
  }

  void _onPanelsChanged() => scheduleMicrotask(
        () {
          if (mounted) {
            setState(() {});
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    /// Move placeholders to the beginning of the list when putting them in
    /// the stack to ensure they are behind the real stories in paint order.
    List<Story> sortedStories =
        new List<Story>.from(config.storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.isPlaceHolder && !b.isPlaceHolder
          ? -1
          : !a.isPlaceHolder && b.isPlaceHolder ? 1 : 0,
    );

    List<Widget> stackChildren = <Widget>[];

    if (config.paintShadows) {
      stackChildren.addAll(
        config.storyCluster.realStories.map(
          (Story story) => new StoryPositioned(
                storyBarMaximizedHeight: _kStoryBarMaximizedHeight,
                focusProgress: config.focusProgress,
                displayMode: config.storyCluster.displayMode,
                isFocused: (config.storyCluster.focusedStoryId == story.id),
                panel: story.panel,
                currentSize: config.currentSize,
                clip: false,
                childContainerKey: story.shadowPositionedKey,
                child: new SimulatedTransform(
                  initOpacity: 0.0,
                  targetOpacity: 1.0,
                  child: new Container(
                    decoration: new BoxDecoration(
                      boxShadow: kElevationToShadow[12],
                      borderRadius: new BorderRadius.all(
                        new Radius.circular(
                          lerpDouble(
                            _kUnfocusedCornerRadius,
                            _kFocusedCornerRadius,
                            config.focusProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
    }

    stackChildren.addAll(
      sortedStories.map(
        (Story story) {
          List<double> fractionalPadding = _getStoryBarPadding(
            story: story,
            width: config.currentSize.width,
          );

          return new StoryPositioned(
            storyBarMaximizedHeight: _kStoryBarMaximizedHeight,
            focusProgress: config.focusProgress,
            displayMode: config.storyCluster.displayMode,
            isFocused: (config.storyCluster.focusedStoryId == story.id),
            panel: story.panel,
            currentSize: config.currentSize,
            childContainerKey: story.positionedKey,
            child: _getStory(
              context,
              story,
              fractionalPadding[0],
              fractionalPadding[1],
              config.currentSize,
            ),
          );
        },
      ),
    );

    return new Stack(overflow: Overflow.visible, children: stackChildren);
  }

  Widget _getStoryBarDraggableWrapper({
    BuildContext context,
    Story story,
    Widget child,
  }) {
    final Widget storyWidget = config.storyWidgets[story.id];
    Rect initialBoundsOnDrag;
    double initialDxOnDrag;
    return new OptionalWrapper(
      // Don't allow dragging if we're the only story.
      useWrapper: config.storyCluster.realStories.length > 1,
      builder: (BuildContext context, Widget child) =>
          new ArmadilloLongPressDraggable<StoryClusterId>(
            key: story.clusterDraggableKey,
            overlayKey: config.overlayKey,
            data: story.clusterId,
            onDragStarted: () {
              RenderBox box =
                  story.positionedKey.currentContext.findRenderObject();
              Point boxTopLeft = box.localToGlobal(Point.origin);
              Point boxBottomRight = box.localToGlobal(
                new Point(box.size.width, box.size.height),
              );
              initialBoundsOnDrag = new Rect.fromLTRB(
                boxTopLeft.x,
                boxTopLeft.y,
                boxBottomRight.x,
                boxBottomRight.y,
              );

              RenderBox storyBarBox =
                  story.storyBarKey.currentContext.findRenderObject();
              Point storyBarBoxTopLeft =
                  storyBarBox.localToGlobal(Point.origin);
              initialDxOnDrag =
                  (config.storyCluster.displayMode == DisplayMode.tabs)
                      ? -storyBarBoxTopLeft.x
                      : 0.0;

              StoryModel.of(context).split(
                    storyToSplit: story,
                    from: config.storyCluster,
                  );
              story.storyBarKey.currentState?.minimize();
              StoryClusterDragStateModel.of(context).addDragging(
                    story.clusterId,
                  );
            },
            onDragEnded: () {
              StoryClusterDragStateModel.of(context).removeDragging(
                    story.clusterId,
                  );
            },
            childWhenDragging: Nothing.widget,
            feedbackBuilder: (Point localDragStartPoint) {
              StoryCluster storyCluster =
                  StoryModel.of(context).getStoryCluster(story.clusterId);

              return new StoryClusterDragFeedback(
                key: storyCluster.dragFeedbackKey,
                storyCluster: storyCluster,
                storyWidgets: <StoryId, Widget>{story.id: storyWidget},
                localDragStartPoint: localDragStartPoint,
                initialBounds: initialBoundsOnDrag,
                focusProgress: config.focusProgress,
                initDx: initialDxOnDrag,
              );
            },
            child: child,
          ),
      child: child,
    );
  }

  Widget _getStory(
    BuildContext context,
    Story story,
    double fractionalLeftPadding,
    double fractionalRightPadding,
    Size currentSize,
  ) =>
      story.isPlaceHolder
          ? story.builder(context)
          : new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // The story bar that pushes down the story.
                new SimulatedPadding(
                  key: story.storyBarPaddingKey,
                  fractionalLeftPadding: fractionalLeftPadding,
                  fractionalRightPadding: fractionalRightPadding,
                  width: currentSize.width,
                  child: new GestureDetector(
                    onTap: () {
                      config.storyCluster.focusedStoryId = story.id;
                      _onPanelsChanged();
                      // If we're in tabbed mode we want to jump the newly
                      // focused story's size to full size instead of animating
                      // it.
                      if (config.storyCluster.displayMode == DisplayMode.tabs) {
                        config.storyCluster.stories.forEach((Story story) {
                          bool storyFocused =
                              (config.storyCluster.focusedStoryId == story.id);
                          story.tabSizerKey.currentState
                              .jump(heightFactor: storyFocused ? 1.0 : 0.0);
                          if (storyFocused) {
                            story.positionedKey.currentState
                                .jumpFractionalHeight(1.0);
                          }
                        });
                      }
                    },
                    child: new ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: _kStoryBarMaximizedHeight,
                      ),
                      child: _getStoryBarDraggableWrapper(
                        context: context,
                        story: story,
                        child: new StoryBar(
                          key: story.storyBarKey,
                          story: story,
                          minimizedHeight: _kStoryBarMinimizedHeight,
                          maximizedHeight: _kStoryBarMaximizedHeight,
                          focused: (config.storyCluster.displayMode ==
                                  DisplayMode.panels) ||
                              (config.storyCluster.focusedStoryId == story.id),
                        ),
                      ),
                    ),
                  ),
                ),

                // The story itself.
                new Expanded(
                  child: new SimulatedFractionallySizedBox(
                    key: story.tabSizerKey,
                    alignment: FractionalOffset.topCenter,
                    heightFactor:
                        (config.storyCluster.focusedStoryId == story.id ||
                                config.storyCluster.displayMode ==
                                    DisplayMode.panels)
                            ? 1.0
                            : 0.0,
                    child: new Container(
                      decoration: new BoxDecoration(
                        backgroundColor: story.themeColor,
                      ),
                      child: _getStoryContents(context, story),
                    ),
                  ),
                ),
              ],
            );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story) => new FittedBox(
        fit: ImageFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new StoryFullSizeSimulatedSizedBox(
          displayMode: config.storyCluster.displayMode,
          panel: story.panel,
          containerKey: story.containerKey,
          storyBarMaximizedHeight: _kStoryBarMaximizedHeight,
          child: config.storyWidgets[story.id] ?? story.builder(context),
        ),
      );

  /// Returns the fractionalLeftPadding [0] and fractionalRightPadding [1] for
  /// the [story].  If [growFocused] is true, the focused story is given double
  /// the width of the other stories.
  List<double> _getStoryBarPadding({
    Story story,
    double width,
    bool growFocused: _kGrowFocusedTab,
  }) {
    if (config.storyCluster.displayMode == DisplayMode.panels) {
      return <double>[0.0, 0.0];
    }
    int storyBarGaps = config.storyCluster.stories.length - 1;
    int spaces = _kGrowFocusedTab
        ? config.storyCluster.stories.length + 1
        : config.storyCluster.stories.length;
    double gapFractionalWidth = 4.0 / width;
    double fractionalWidthPerSpace =
        (1.0 - (storyBarGaps * gapFractionalWidth)) / spaces;

    int index = config.storyCluster.stories.indexOf(story);
    double left = 0.0;
    for (int i = 0; i < config.storyCluster.stories.length; i++) {
      if (i == index) {
        break;
      }
      left += fractionalWidthPerSpace + gapFractionalWidth;
      if (growFocused &&
          config.storyCluster.stories[i].id ==
              config.storyCluster.focusedStoryId) {
        left += fractionalWidthPerSpace;
      }
    }
    double fractionalWidth =
        growFocused && (story.id == config.storyCluster.focusedStoryId)
            ? 2.0 * fractionalWidthPerSpace
            : fractionalWidthPerSpace;
    double right = 1.0 - left - fractionalWidth;
    return <double>[left, right];
  }
}
