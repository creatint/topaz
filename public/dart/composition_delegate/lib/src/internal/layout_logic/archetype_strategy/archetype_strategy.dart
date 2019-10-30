// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show pow;
import 'package:composition_delegate/src/internal/layout_logic/copresent_strategy/copresent_strategy.dart';
import 'package:meta/meta.dart' show required;
import 'package:composition_delegate/composition_delegate.dart';
import 'package:composition_delegate/src/internal/layout_logic/_layout_strategy.dart';
import 'package:composition_delegate/src/internal/tree/_surface_node.dart';

/// Strategy for laying out Surfaces that have been identified as being part
/// of an archetype.
///
/// Currently implemented archetypes: workspace.

class ArchetypeStrategy extends LayoutStrategy {
  /// The snapshot of ordered set of focused Surfaces in the Story provided to
  /// the layout strategy
  LinkedHashSet focusedSurfaces;

  /// The snapshot of the set of hidden Surfaces in the Story provided to the
  /// layout strategy
  Set<String> hiddenSurfaces;

  /// The snapshot of the current layoutContext e.g. viewport size provided to
  /// the layout strategy
  LayoutContext layoutContext;

  /// The previously determined layout (not necessarily by this strategy)
  List<Layer> previousLayout;

  /// The snapshot of the surface tree describing relationships between
  /// surfaces in the story.
  SurfaceTree surfaceTree;

  @override
  List<Layer> getLayout(
      {LinkedHashSet<String> focusedSurfaces,
      Set<String> hiddenSurfaces,
      LayoutContext layoutContext,
      List<Layer> previousLayout,
      SurfaceTree surfaceTree}) {
    // Check if the node is part of an archetype
    SurfaceNode focusedNode =
        surfaceTree.findNode(surfaceId: focusedSurfaces.first);
    Map<String, String> metadata = focusedNode.surface.metadata;
    if (metadata.keys.contains('archetype')) {
      switch (metadata['archetype']) {
        case 'workspace':
          return [
            // NOTE: to start this returns just a single layer. We'll need to
            // finesse how this mixes with other layouts.
            getWorkspaceLayout(
              focusedSurfaces: focusedSurfaces,
              hiddenSurfaces: hiddenSurfaces,
              layoutContext: layoutContext,
              previousLayout: previousLayout,
              surfaceTree: surfaceTree,
            )
          ];
        default:
          log.warning(
              "archetype ${metadata['workspace']} not found, defaulting}");
          return null;
      }
    }
    return null;
  }

  /// The layout for the workspace archetype
  Layer getWorkspaceLayout(
      {LinkedHashSet<String> focusedSurfaces,
      Set<String> hiddenSurfaces,
      LayoutContext layoutContext,
      List<Layer> previousLayout,
      SurfaceTree surfaceTree}) {
    Layer layout = Layer();
    SurfaceTree workspaceTree = surfaceTree.spanningTree(
        startNodeId: focusedSurfaces.first,
        condition: (SurfaceNode s) =>
            s.surface.metadata.containsKey('archetype') &&
            s.surface.metadata['archetype'] == 'workspace');
    if (workspaceTree.length == 1) {
      // either it's primary and can be shown by itself, or it's auxiliary
      // which is invalid
      if (workspaceTree.first.metadata['archetype_role'] == 'primary') {
        layout.add(
          SurfaceLayout.fullSize(
              layoutContext: layoutContext,
              surfaceId: workspaceTree.first.surfaceId),
        );
      }
      // If the role was not primary, return null and default to another layout
      // strategy
      return layout;
    } else {
      Map<String, List<Surface>> surfaces = {};
      for (Surface s in workspaceTree) {
        surfaces[s.metadata['archetype_role']] == null
            ? surfaces[s.metadata['archetype_role']] = [s]
            : surfaces[s.metadata['archetype_role']].add(s);
      }
      // TODO: make the archetype layout spec come from structured data
      double primaryXStart = 0.0;
      double primaryYStart = 0.0;
      double headerHeightFactor = 0.1;
      double footerHeightFactor = 0.1;
      double primaryWidthFactor = 1.0;
      double primaryHeightFactor = 1.0;
      double auxHeightFactor = 1.0;
      const double auxLeftWidthFactor = 0.2;
      const double auxRightWidthFactor = 0.2;

      List<String> auxiliaryLeftSurfaceIds = [];
      List<String> auxiliaryRightSurfaceIds = [];
      String auxiliaryLeftGrouping = 'copresent';
      String auxiliaryRightGrouping = 'copresent';
      String primaryGrouping = 'copresent';

      // Check if there are headers
      List<Surface> headerSurfaces =
          surfaces.keys.contains('header') ? List.from(surfaces['header']) : [];
      if (headerSurfaces.isNotEmpty) {
        primaryHeightFactor -= headerHeightFactor;
        primaryYStart += headerHeightFactor;
        auxHeightFactor -= headerHeightFactor;
      }

      // Check if there are footers
      List<Surface> footerSurfaces =
          surfaces.keys.contains('footer') ? List.from(surfaces['footer']) : [];
      if (footerSurfaces.isNotEmpty) {
        primaryHeightFactor -= footerHeightFactor;
      }
      // Get the list of Primaries, and sort them by focus in case we need to
      // Stack them.
      List<Surface> primarySurfaces = List.from(surfaces['primary']);
      List<String> primarySurfaceIds =
          surfaces['primary'].map((s) => s.surfaceId).toList();
      List focusedSurfaceList = focusedSurfaces.toList();
      primarySurfaceIds
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;

      /// primary Surface grouping
      primarySurfaces
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;
      // TODO(djmurphy): this list comprehension is ungainly, refactor to
      // make it easier to get primaryGrouping
      primaryGrouping = primarySurfaces
          .firstWhere((s) => s.metadata.containsKey('grouping'),
              orElse: () => Surface(metadata: {'grouping': primaryGrouping}))
          .metadata['grouping'];

      List<Surface> auxLeftSurfaces = [];
      List<Surface> auxRightSurfaces = [];

      List<Surface> auxiliarySurfaces = surfaces.keys.contains('auxiliary')
          ? List.from(surfaces['auxiliary'])
          : [];

      for (Surface s in auxiliarySurfaces) {
        if (s.metadata['hierarchy'] == 'parent') {
          auxLeftSurfaces.add(s);
          auxiliaryLeftSurfaceIds.add(s.surfaceId);
        } else {
          // default hierarchy is 'child'
          auxRightSurfaces.add(s);
          auxiliaryRightSurfaceIds.add(s.surfaceId);
        }
      }
      if (auxiliaryLeftSurfaceIds.isNotEmpty) {
        primaryWidthFactor -= auxLeftWidthFactor;
        primaryXStart = auxLeftWidthFactor;
      }
      if (auxiliaryRightSurfaceIds.isNotEmpty) {
        primaryWidthFactor -= auxRightWidthFactor;
      }

      // Sort by focus order in case we need to stack
      auxiliaryLeftSurfaceIds
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;
      auxLeftSurfaces
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;

      auxiliaryLeftGrouping = auxLeftSurfaces
          .firstWhere((s) => s.metadata.containsKey('grouping'),
              orElse: () =>
                  Surface(metadata: {'grouping': auxiliaryLeftGrouping}))
          .metadata['grouping'];

      // Sort by focus order in case we need to stack
      auxiliaryRightSurfaceIds
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;

      auxRightSurfaces
        ..sort(
          (a, b) => focusedSurfaceList.indexOf(a).compareTo(
                focusedSurfaceList.indexOf(b),
              ),
        )
        ..reversed;

      auxiliaryRightGrouping = auxRightSurfaces
          .firstWhere((s) => s.metadata.containsKey('grouping'),
              orElse: () =>
                  Surface(metadata: {'grouping': auxiliaryRightGrouping}))
          .metadata['grouping'];

      // Prepare the LayoutElements
      // Header
      layout.add(
        _createElement(
          x: 0.0,
          y: 0.0,
          width: layoutContext.size.width,
          height: headerHeightFactor * layoutContext.size.height,
          surfaces: headerSurfaces.map((s) => s.surfaceId).toList(),
        ),
      );

      double _scaledXStart = primaryXStart * layoutContext.size.width;
      double _scaledYStart = primaryYStart * layoutContext.size.height;
      // Left Secondaries
      if (auxiliaryLeftSurfaceIds.length == 1 ||
          auxiliaryLeftGrouping != 'copresent') {
        layout.add(
          _createElement(
            y: _scaledYStart, // header
            width: auxLeftWidthFactor * layoutContext.size.width,
            height: auxHeightFactor * layoutContext.size.height,
            surfaces: auxiliaryLeftSurfaceIds,
            grouping: auxiliaryLeftGrouping,
          ),
        );
      } else {
        layout.addAll(
          _createCopresent(
            y: _scaledYStart, //header
            width: auxLeftWidthFactor * layoutContext.size.width,
            height: auxHeightFactor * layoutContext.size.height,
            surfaces: auxiliaryLeftSurfaceIds,
            tree: surfaceTree, //TODO: make this just the primary limb?
          ),
        );
      }

      // Primary
      if (primarySurfaceIds.length == 1 || primaryGrouping != 'copresent') {
        layout.add(
          _createElement(
            x: _scaledXStart,
            y: _scaledYStart,
            width: primaryWidthFactor * layoutContext.size.width,
            height: primaryHeightFactor * layoutContext.size.height,
            surfaces: primarySurfaceIds,
            grouping: primaryGrouping,
          ),
        );
      } else {
        layout.addAll(
          _createCopresent(
            x: _scaledXStart,
            y: _scaledYStart,
            width: primaryWidthFactor * layoutContext.size.width,
            surfaces: primarySurfaceIds,
            height: layoutContext.size.height,
            tree: surfaceTree,
          ),
        );
      }

      // Footer
      layout.add(_createElement(
        x: _scaledXStart,
        y: (1 - footerHeightFactor) * layoutContext.size.height,
        width: primaryWidthFactor * layoutContext.size.width,
        height: footerHeightFactor * layoutContext.size.height,
        surfaces: footerSurfaces.map((s) => s.surfaceId).toList(),
      ));

      // Right Secondaries
      if (auxiliaryRightSurfaceIds.length == 1 ||
          auxiliaryRightGrouping != 'copresent') {
        layout.add(
          _createElement(
            x: (primaryXStart + primaryWidthFactor) * layoutContext.size.width,
            y: _scaledYStart, // is there a header
            width: auxRightWidthFactor * layoutContext.size.width,
            height: auxHeightFactor * layoutContext.size.height,
            surfaces: auxiliaryRightSurfaceIds,
            grouping: auxiliaryRightGrouping,
          ),
        );
      } else {
        layout.addAll(
          _createCopresent(
            x: (primaryXStart + primaryWidthFactor) * layoutContext.size.width,
            y: _scaledYStart, // is there a header
            width: auxRightWidthFactor * layoutContext.size.width,
            height: auxHeightFactor * layoutContext.size.height,
            surfaces: auxiliaryRightSurfaceIds,
            tree: surfaceTree,
          ),
        );
      }
      // Remove all instances of null from the layout
      while (layout.remove(null)) {}
      return layout;
    }
  }
}

/// For cases where there are multiple Surfaces associated with a given slot,
/// create a co-presentation of SurfaceLayout elements.
///
/// Current definition is that, if all the Surfaces cannot fit in a slot, then
/// a vertically scrollable arrangement is returned. To achieve this, we
/// specify surfaces outside of the bounds of the given layout context in the
/// y dimension.

List<SurfaceLayout> _createCopresent({
  @required double width,
  @required double height,
  @required List<String> surfaces,
  @required SurfaceTree tree,
  double x = 0.0, // x offset
  double y = 0.0, // y offset
}) {
  List<SurfaceLayout> layout = <SurfaceLayout>[];
  // Apply the co-present layout strategy
  CopresentStrategy copres = CopresentStrategy();
  List<Layer> layers = copres.getLayout(
      focusedSurfaces: surfaces.toSet(),
      // TODO(djmurphy): pass the context for minWidth here
      layoutContext: LayoutContext(
        size: Size(width, height),
        minSurfaceWidth: 100.0,
        minSurfaceHeight: 320.0,
      ),
      surfaceTree: tree);
  for (int i = 0; i < layers.length; i++) {
    for (LayoutElement element in layers[i]) {
      layout.add(
        SurfaceLayout(
          x: element.x + x,
          y: element.y + y + (height * i),
          w: element.w,
          h: element.h,
          surfaceId: element.element,
        ),
      );
    }
  }
  return layout;
}

// create a stack layout element
LayoutElement _createElement({
  @required double width,
  @required double height,
  @required List<String> surfaces,
  String grouping = 'single',
  double x = 0.0,
  double y = 0.0,
}) {
  if (surfaces.isEmpty) {
    return null;
  }

  if (surfaces.length == 1) {
    return SurfaceLayout(
      x: _roundToPrecision(x),
      y: _roundToPrecision(y),
      w: _roundToPrecision(width),
      h: _roundToPrecision(height),
      surfaceId: surfaces.first,
    );
  }

  if (grouping == 'single') {
    // Stack multiple surfaces on top of each other
    return StackLayout(
      x: _roundToPrecision(x),
      y: _roundToPrecision(y),
      w: _roundToPrecision(width),
      h: _roundToPrecision(height),
      surfaceStack: surfaces,
    );
  }

  if (grouping == 'toggle') {
    return ToggleableLayout(
      x: _roundToPrecision(x),
      y: _roundToPrecision(y),
      w: _roundToPrecision(width),
      h: _roundToPrecision(height),
      toggleStack: surfaces,
    );
  }
  return SurfaceLayout();
}

// Rounding to precision to pass tests, assuming 1/100th of a viewport
// dimension is enough precision for laying out something.
double _roundToPrecision(double number, {int precision = 2}) {
  int factor = pow(10, precision);
  return (number * factor).round() / factor;
}
