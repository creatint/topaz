// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'tile.dart';

typedef TileSizerBuilder = Widget Function(
  BuildContext context,
  Axis direction,
  TileModel tileBefore,
  TileModel tileAfter,
);

class Sizer extends StatelessWidget {
  final Axis direction;
  final TileSizerBuilder sizerBuilder;
  final TileModel tileBefore;
  final TileModel tileAfter;
  final bool horizontal;

  Sizer({
    this.direction,
    this.tileBefore,
    this.tileAfter,
    this.sizerBuilder,
  }) : horizontal = direction == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final sizer = sizerBuilder?.call(context, direction, tileBefore, tileAfter);
    if (sizer == null) {
      return SizedBox.shrink();
    } else {
      final hoverNotifier = ValueNotifier<bool>(false);
      return Listener(
        onPointerEnter: (_) => hoverNotifier.value = true,
        onPointerExit: (_) => hoverNotifier.value = false,
        onPointerCancel: (_) => hoverNotifier.value = false,
        onPointerDown: (_) => hoverNotifier.value = true,
        onPointerMove: _onPointerMove,
        child: AnimatedBuilder(
          animation: hoverNotifier,
          builder: (context, child) => AnimatedOpacity(
                opacity: hoverNotifier.value ? 1.0 : 0.0,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: child,
              ),
          child: Container(
            color: Colors.transparent,
            child: sizer,
          ),
        ),
      );
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    double delta =
        direction == Axis.horizontal ? event.delta.dy : event.delta.dx;
    tileBefore.offset = delta;
    tileAfter.offset = -delta;
  }
}
