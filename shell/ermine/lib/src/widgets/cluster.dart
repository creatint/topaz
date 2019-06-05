// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:tiler/tiler.dart' show Tiler, TileModel;
import 'package:fuchsia_scenic_flutter/child_view.dart' show ChildView;

import '../models/cluster_model.dart';
import '../models/ermine_story.dart';

import 'tile_chrome.dart';
import 'tile_sizer.dart';
import 'tile_tab.dart';

/// Defines a widget to cluster [Story] widgets built by the [Tiler] widget.
class Cluster extends StatelessWidget {
  final ClusterModel model;

  const Cluster({this.model});

  @override
  Widget build(BuildContext context) {
    return Tiler<ErmineStory>(
      model: model.tilerModel,
      chromeBuilder: _chromeBuilder,
      customTilesBuilder: (context, tiles) => TabbedTiles(
            tiles: tiles,
            chromeBuilder: (context, tile) => _chromeBuilder(
                  context,
                  tile,
                  custom: true,
                ),
            onSelect: (index) => tiles[index].content.focus(),
            initialIndex: _focusedIndex(tiles),
          ),
      sizerBuilder: (context, direction, _, __) => GestureDetector(
            // Disable listview scrolling on top of sizer.
            onHorizontalDragStart: (_) {},
            behavior: HitTestBehavior.translucent,
            child: TileSizer(
              direction: direction,
            ),
          ),
      sizerThickness: TileSizer.kThickness,
    );
  }

  Widget _chromeBuilder(BuildContext context, TileModel<ErmineStory> tile,
      {bool custom = false}) {
    final story = tile.content;
    return AnimatedBuilder(
      animation: story.childViewConnectionNotifier,
      builder: (context, child) {
        return story.childViewConnection != null
            ? AnimatedBuilder(
                animation: story.focusedNotifier,
                builder: (context, child) => TileChrome(
                      name: story.id ?? '<title>',
                      showTitle: !custom,
                      focused: story.focused,
                      child: AnimatedBuilder(
                        animation: story.visibilityStateNotifier,
                        builder: (context, child) => story.isImmersive
                            ? Offstage()
                            : GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                // Disable listview scrolling on top of cluster.
                                onHorizontalDragStart: (_) {},
                                onTap: story.focus,
                                child: ChildView(
                                  connection: story.childViewConnection,
                                ),
                              ),
                      ),
                      onDelete: story.delete,
                      onFullscreen: story.maximize,
                      onMinimize: story.restore,
                    ),
              )
            : Offstage();
      },
    );
  }

  int _focusedIndex(List<TileModel<ErmineStory>> tiles) {
    final focusedTile = tiles.firstWhere(
      (t) => t.content.focused,
      orElse: () => null,
    );
    return focusedTile == null ? 0 : tiles.indexOf(focusedTile);
  }
}
