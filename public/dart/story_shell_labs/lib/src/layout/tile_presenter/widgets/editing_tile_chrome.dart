// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:tiler/tiler.dart';
import 'drop_target_widget.dart';

const _kHighlightedBorderWidth = 3.0;
const _kBorderWidth = 1.0;
const _kBorderWidthDiff = _kHighlightedBorderWidth - _kBorderWidth;

/// Chrome for a tiling layout presenter.
class EditingTileChrome extends StatefulWidget {
  /// Constructor for a tiling layout presenter.
  const EditingTileChrome({
    @required this.focusedMod,
    @required this.parameterColors,
    @required this.tilerModel,
    @required this.tile,
    @required this.childView,
    @required this.modName,
    @required this.editingSize,
    @required this.willStartDrag,
    @required this.didCancelDrag,
  });

  /// Currently focused mod.
  final ValueNotifier<String> focusedMod;

  /// Intent parameter circle colors.
  final Iterable<Color> parameterColors;

  /// The model currently being displayed.
  final TilerModel tilerModel;

  /// The tile being showed on this chrome.
  final TileModel tile;

  /// Content of the chrome.
  final Widget childView;

  /// Surface id of the view displayed here.
  final String modName;

  /// Editing size
  final Size editingSize;

  /// Called before user starts dragging this tile.
  final VoidCallback willStartDrag;

  /// Called after drag was cancelled, either by dropping outside of an accepting target, or because the action was interrupted.
  final VoidCallback didCancelDrag;

  @override
  _EditingTileChromeState createState() => _EditingTileChromeState();
}

class _EditingTileChromeState extends State<EditingTileChrome> {
  final _isDragging = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Draggable(
            onDragStarted: () {
              widget.willStartDrag();
              widget.focusedMod.value = widget.modName;
              _isDragging.value = true;
              widget.tilerModel.remove(widget.tile);
            },
            onDragEnd: (_) {
              _isDragging.value = false;
            },
            onDraggableCanceled: (_, __) {
              widget.didCancelDrag();
            },
            key: Key(widget.modName),
            data: widget.tile,
            feedback: _buildFeedback(),
            childWhenDragging: const Offstage(),
            child: AnimatedBuilder(
              animation: widget.focusedMod,
              builder: (_, child) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.focusedMod.value == widget.modName
                            ? Color(0xFFFF8BCB)
                            : Colors.black,
                        width: _kBorderWidth,
                      ),
                    ),
                    child: child,
                  ),
              child: Stack(
                children: [widget.childView]
                  ..addAll(_buildSplitTargets(widget.editingSize)),
              ),
            ),
          ),
        ),
        _buildCornerItems(),
      ],
    );
  }

  Widget _buildFeedback() {
    final borderWidthDifference =
        Offset(-_kBorderWidthDiff, -_kBorderWidthDiff);

    return Transform.translate(
      offset: borderWidthDifference,
      child: SizedBox.fromSize(
        size: widget.editingSize +
            Offset(_kBorderWidthDiff, _kBorderWidthDiff) * 2,
        child: Center(
          child: Material(
            elevation: 16.0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFFFF8BCB),
                  width: _kHighlightedBorderWidth,
                ),
              ),
              child: widget.childView,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCornerItems() {
    final parameterIndicators = Row(
      children: widget.parameterColors
          .expand((color) => [
                Material(
                  elevation: 4.0,
                  clipBehavior: Clip.antiAlias,
                  shape: CircleBorder(),
                  color: color,
                  child: SizedBox(width: 24, height: 24),
                ),
                SizedBox(width: 8.0),
              ])
          .toList(),
    );

    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedBuilder(
        animation: _isDragging,
        builder: (_, child) =>
            Offstage(offstage: _isDragging.value, child: child),
        child: Row(
          children: <Widget>[
            parameterIndicators,
            Material(
              elevation: 4.0,
              clipBehavior: Clip.antiAlias,
              shape: CircleBorder(),
              child: InkWell(
                onTap: () {
                  widget.tilerModel.remove(widget.tile);
                },
                child: Icon(Icons.close),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSplitTargets(Size size) => <Widget>[
        _splitTarget(
          nearTile: widget.tile,
          direction: AxisDirection.up,
          parentSizeOnAxis: size.height,
        ),
        _splitTarget(
          nearTile: widget.tile,
          direction: AxisDirection.down,
          parentSizeOnAxis: size.height,
        ),
        _splitTarget(
          nearTile: widget.tile,
          direction: AxisDirection.left,
          parentSizeOnAxis: size.width,
        ),
        _splitTarget(
          nearTile: widget.tile,
          direction: AxisDirection.right,
          parentSizeOnAxis: size.width,
        ),
      ];

  Widget _splitTarget({
    TileModel nearTile,
    AxisDirection direction,
    double parentSizeOnAxis,
  }) =>
      Positioned(
        top: direction == AxisDirection.down ? null : 0,
        bottom: direction == AxisDirection.up ? null : 0,
        left: direction == AxisDirection.right ? null : 0,
        right: direction == AxisDirection.left ? null : 0,
        child: DropTargetWidget(
          onAccept: (tile) {
            widget.tilerModel.remove(tile);
            widget.tilerModel.split(
              content: tile.content,
              direction: direction,
              tile: nearTile,
            );
          },
          onWillAccept: (tile) => tile != nearTile,
          axis: axisDirectionToAxis(direction),
          baseSize: 50.0,
          hoverSize: parentSizeOnAxis * .33,
        ),
      );
}
