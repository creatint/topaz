// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// import 'hover.dart';
import 'tile.dart';

typedef TileSizerBuilder = Widget Function(
    BuildContext context, Axis direction);

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
    final sizer = sizerBuilder?.call(context, direction);
    if (sizer == null) {
      return SizedBox.shrink();
    } else {
      final hoverNotifier = ValueNotifier<bool>(true);
      return /*Hover(
        notifier: hoverNotifier,
        child: */
          GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragUpdate: _onDragUpdate,
        onVerticalDragUpdate: _onDragUpdate,
        child: AnimatedBuilder(
          animation: hoverNotifier,
          builder: (context, child) => AnimatedOpacity(
                opacity: hoverNotifier.value ? 1.0 : 0.0,
                duration: Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: child,
              ),
          child: sizerBuilder(context, direction),
        ),
        //),
      );
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    tileBefore.offset = details.primaryDelta;
    tileAfter.offset = -details.primaryDelta;
  }
}
