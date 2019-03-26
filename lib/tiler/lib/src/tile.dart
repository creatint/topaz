// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'sizer.dart';

typedef TileChromeBuilder = Widget Function(
    BuildContext context, TileModel tile);

/// A [Widget] that renders a tile give its [TileModel]. If the tile type is
/// [TileType.content], it calls [chromeBuilder] to build a widget to render
/// the tile. Otherwise, it renders the [tiles] children in row or column
/// order. It calls [sizerBuilder] to get a sizing widget to display between
/// rows or columns of tiles.
class Tile extends StatelessWidget {
  final TileModel model;
  final TileChromeBuilder chromeBuilder;
  final TileSizerBuilder sizerBuilder;
  final double sizerThickness;

  const Tile({
    @required this.model,
    @required this.chromeBuilder,
    this.sizerBuilder,
    this.sizerThickness = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (model.type == TileType.content) {
      return chromeBuilder(context, model);
    } else if (model.tiles.isEmpty) {
      return SizedBox.shrink();
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          /// Compute individual tile width and height.
          final type = model.type;
          final width = constraints.minWidth;
          final height = constraints.minHeight;

          final numTiles = model.tiles.length;
          final numSizers = numTiles - 1;

          final tileWidth = type == TileType.column
              ? (width - sizerThickness * numSizers) / numTiles
              : width;
          final tileHeight = type == TileType.row
              ? (height - sizerThickness * numSizers) / numTiles
              : height;

          // Normalize the flex on each tile.
          final flex =
              model.tiles.map((t) => t.flex).reduce((f1, f2) => f1 + f2);
          for (var tile in model.tiles) {
            tile
              ..flex = tile.flex * (numTiles / flex)
              ..width = tileWidth
              ..height = tileHeight;
          }

          final tiles = model.tiles
              .map<List<Widget>>((t) => t == model.tiles.first
                  ? [
                      AnimatedBuilder(
                        animation: t,
                        child: Tile(
                          model: t,
                          chromeBuilder: chromeBuilder,
                          sizerBuilder: sizerBuilder,
                          sizerThickness: sizerThickness,
                        ),
                        builder: (context, child) => SizedBox(
                              width: t.width,
                              height: t.height,
                              child: child,
                            ),
                      ),
                    ]
                  : [
                      Sizer(
                        direction: model.type == TileType.row
                            ? Axis.horizontal
                            : Axis.vertical,
                        tileBefore: model.tiles[model.tiles.indexOf(t) - 1],
                        tileAfter: t,
                        sizerBuilder: sizerBuilder,
                      ),
                      AnimatedBuilder(
                        animation: t,
                        child: Tile(
                          model: t,
                          chromeBuilder: chromeBuilder,
                          sizerBuilder: sizerBuilder,
                          sizerThickness: sizerThickness,
                        ),
                        builder: (context, child) => SizedBox(
                              width: t.width,
                              height: t.height,
                              child: child,
                            ),
                      ),
                    ])
              .expand((e) => e)
              .toList();
          return model.type == TileType.row
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tiles,
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tiles,
                );
        },
      );
    }
  }
}

enum TileType { content, row, column }

/// Defines a model for a tile. It is a tree data structure where each tile
/// model holds a reference to its parent and a list of children. If the type
/// of tile, [TileType] is [TileType.content], it is a leaf node tile.
///
/// The [content] of tile holds a reference to an arbitrary object, that is
/// passed to the caller during the construction of the tile's chrome widget.
class TileModel extends ChangeNotifier {
  TileModel parent;
  TileType type;
  Object content;
  List<TileModel> tiles;

  TileModel({
    @required this.type,
    this.parent,
    this.content,
    this.tiles,
  }) {
    tiles ??= <TileModel>[];
  }

  // Defines the flex factor on how the tile is sized.
  double _flex = 1;
  double get flex => _flex;
  set flex(double value) {
    _flex = value;
    if (parent.type == TileType.column) {
      _offset = -(_width - (_width * _flex));
    } else {
      _offset = -(_height - (_height * _flex));
    }
  }

  double _width = 0;
  double get width =>
      parent.type == TileType.column ? _width + _offset : _width;
  set width(double value) => _width = value;

  double _height = 0;
  double get height =>
      parent.type == TileType.row ? _height + _offset : _height;
  set height(double value) => _height = value;

  double _offset = 0;
  double get offset => _offset;
  set offset(double value) {
    _offset += value;
    _flex = parent.type == TileType.column
        ? (_width + _offset) / _width
        : (_height + _offset) / _height;

    notifyListeners();
  }

  void copy(TileModel other) {
    _offset = other._offset;
    _flex = other._flex;
    _width = other._width;
    _height = other._height;
  }

  void reset() {
    _flex = 1;
    _offset = 0;
    _width = 0;
    _height = 0;
  }

  void notify() => notifyListeners();

  @override
  String toString() => type == TileType.content ? '$type' : '$type $tiles';
}
