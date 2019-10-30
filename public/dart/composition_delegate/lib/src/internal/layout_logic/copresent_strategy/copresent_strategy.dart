// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:collection' show Queue;
import 'dart:math';

import 'package:composition_delegate/composition_delegate.dart';
import 'package:composition_delegate/src/internal/layout_logic/_layout_strategy.dart';
import 'package:composition_delegate/src/internal/tree/_surface_node.dart';

/// Strategy for splitting the space according to the co-presentation
/// determination between adjacent Surfaces, and their Surface order
class CopresentStrategy extends LayoutStrategy {
  /// Split a List of <T> into List of Lists of <T> of [chunkSize], working from
  /// the back of the list. (Newly focused surfaces are pushed to the end of the
  /// list)
  List<List<T>> _chunkRightToLeft<T>({List<T> list, int chunkSize}) =>
      list.length <= chunkSize
          ? [list]
          : ([
              list.sublist(list.length - chunkSize, list.length),
              ..._chunkRightToLeft(
                  list: list.sublist(0, list.length - chunkSize),
                  chunkSize: chunkSize)
            ]);

  /// Returns the layout for copresent strategy given the current context. The
  /// co-present strategy tries to layout Surfaces that have co-present
  /// relationship
  ///
  /// [grouping] is the optional parameter that dictates what should happen
  /// if the Surfaces cannot all fit in the space provided.
  @override
  List<Layer> getLayout({
    LinkedHashSet<String> focusedSurfaces,
    Set<String> hiddenSurfaces,
    LayoutContext layoutContext,
    List<Layer> previousLayout,
    SurfaceTree surfaceTree,
  }) {
    // Get the groups of Surfaces that we should try to lay out together
    List<List<String>> layoutGroups = _getLayoutGroups(
        focusedSurfaces: focusedSurfaces, surfaceTree: surfaceTree);
    // Split the groups across layers according to how they fit into the
    // current [layoutContext]
    List<Layer> layout = [];
    for (List<String> layoutGroup in layoutGroups) {
      // If there's only one Surface in the group: a sequential etc:
      if (layoutGroup.length == 1) {
        layout.add(
          Layer(
            element: SurfaceLayout.fullSize(
                layoutContext: layoutContext, surfaceId: layoutGroup.first),
          ),
        );
      } else if (layoutContext.size.width >= layoutContext.size.height) {
        // TODO (djmurphy): add or deprecate emphasis
        // In a naive left-to-right co-present layout, horizontally
        int maxSurfacesPerLayer =
            layoutContext.size.width ~/ layoutContext.minSurfaceWidth;
        // Chop the layoutGroup into sets that will fit in a layer, starting
        // from the most focused (at the end of the list) of Surfaces to be laid
        // out.
        List<List<String>> layerLists = _chunkRightToLeft(
            list: layoutGroup, chunkSize: maxSurfacesPerLayer);
        // And turn those into layers of SurfaceLayouts
        for (List<String> layerList in layerLists) {
          // TODO (djmurphy): add emphasis
          double width = max(layoutContext.size.width / layerList.length,
              layoutContext.minSurfaceWidth);
          layout.add(
            Layer.fromList(
              elements: layerList
                  .asMap()
                  .map(
                    (index, value) => MapEntry(
                      index,
                      SurfaceLayout(
                          x: index * width,
                          y: 0.0,
                          w: width,
                          h: layoutContext.size.height,
                          surfaceId: value),
                    ),
                  )
                  .values
                  .toList(),
            ),
          );
        }
      } else {
        // In a naive top-to-bottom co-present layout, vertically
        int maxSurfacesPerLayer =
            layoutContext.size.height ~/ layoutContext.minSurfaceHeight;
        // Chop the layoutGroup into sets that will fit in a layer, starting
        // from the most focused (at the end of the list) of Surfaces to be laid
        // out.
        List<List<String>> layerLists = _chunkRightToLeft(
            list: layoutGroup, chunkSize: maxSurfacesPerLayer);
        // And turn those into layers of SurfaceLayouts
        for (List<String> layerList in layerLists) {
          // TODO (djmurphy): add emphasis
          double height = max(layoutContext.size.height / layerList.length,
              layoutContext.minSurfaceHeight);
          layout.add(
            Layer.fromList(
              elements: layerList
                  .asMap()
                  .map(
                    (index, value) => MapEntry(
                      index,
                      SurfaceLayout(
                          x: 0.0,
                          y: index * height,
                          w: layoutContext.size.width,
                          h: height,
                          surfaceId: value),
                    ),
                  )
                  .values
                  .toList(),
            ),
          );
        }
      }
    }
    return layout;
  }

  /// For a collection of [focusedSurfaces] and the description of the
  /// relationships between them in the surfaceTree, return a [List] of groups
  /// of Surfaces that we should try to lay out together.
  List<List<String>> _getLayoutGroups(
      {LinkedHashSet<String> focusedSurfaces, SurfaceTree surfaceTree}) {
    Queue<String> surfacesToLayout = Queue.of(focusedSurfaces);
    List<List<String>> layoutGroups = [];
    // Create layout groups starting with the most focused Surface
    // Focusing on co-presentation for now.

    while (surfacesToLayout.isNotEmpty) {
      String firstSurface = surfacesToLayout.removeFirst();
      // The sub-tree of Surfaces that have co-presentation relationship with
      // this Surface. If there are no related Surfaces, the copresentTree will
      // consist only of the firstSurface node.
      SurfaceTree copresentTree = surfaceTree.spanningTree(
        startNodeId: firstSurface,
        condition: (SurfaceNode s) =>
            s.relationToParent?.arrangement == SurfaceArrangement.copresent,
      );
      List<String> group = [];
      for (Surface s in copresentTree) {
        if (focusedSurfaces.contains(s.surfaceId)) {
          // remove Surfaces from the surfacesToLayout as we add them to layout
          // groups
          group.add(s.surfaceId);
          surfacesToLayout.remove(s.surfaceId);
        }
      }
      layoutGroups.add(group);
    }
    return layoutGroups;
  }
}
