// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'sizer.dart';
import 'tile.dart';

/// Defines a widget to arrange tiles supplied in [model]. For tiles that are
/// leaf nodes in the [model], it calls the [chromeBuilder] to build their
/// widget. The [sizerBuilder] is called to display a sizing widget between
/// two tiles. If [sizerBuilder] returns null, no space is created between
/// the tiles. The supplied [sizerThickness] is used during layout calculations.
class Tiler extends StatelessWidget {
  final TilerModel model;
  final TileChromeBuilder chromeBuilder;
  final TileSizerBuilder sizerBuilder;
  final double sizerThickness;

  const Tiler({
    @required this.model,
    @required this.chromeBuilder,
    this.sizerBuilder,
    this.sizerThickness,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(5),
      child: AnimatedBuilder(
        animation: model,
        builder: (_, __) => Tile(
              model: model.root,
              chromeBuilder: chromeBuilder,
              sizerBuilder: sizerBuilder,
              sizerThickness: sizerThickness,
            ),
      ),
    );
  }
}

/// Defines a model to hold a tree of [TileModel]s. The leaf nodes are tiles
/// of type [TileType.content], branches can be [TileType.column] or
/// [TileType.row]. The member [root] holds the reference to the root tile.
class TilerModel extends ChangeNotifier {
  TileModel root;

  /// Initializes the [TilerModel] to start layout in supplied [direction].
  TilerModel({
    Axis direction = Axis.horizontal,
    this.root,
  }) {
    if (root == null) {
      root = TileModel(
        type: direction == Axis.horizontal ? TileType.column : TileType.row,
      );
    } else {
      _initialize(root);
    }
  }

  /// Returns the tile next to [tile] in the given [direction].
  TileModel navigate(AxisDirection direction, TileModel tile) {
    assert(tile != null);

    switch (direction) {
      case AxisDirection.left:
        return _last(_previous(tile, TileType.column));
      case AxisDirection.up:
        return _last(_previous(tile, TileType.row));
      case AxisDirection.right:
        return _first(_next(tile, TileType.column));
      case AxisDirection.down:
        return _first(_next(tile, TileType.row));
      default:
        return null;
    }
  }

  /// Returns a new tile after splitting the supplied [tile] in the [direction].
  TileModel split({
    @required TileModel tile,
    Object content,
    Axis direction,
  }) {
    assert(tile != null);

    TileModel src = tile;
    final parent = src.parent;
    int index = parent.tiles.indexOf(src);
    parent.tiles.remove(src);

    TileModel dst = TileModel(
      content: content,
      parent: parent,
      type: direction == Axis.horizontal ? TileType.column : TileType.row,
      tiles: [src, TileModel(type: TileType.content, content: content)],
    )..copy(src);
    src.reset();

    dst.tiles.first.parent = dst;
    dst.tiles.last.parent = dst;

    parent.tiles.insert(index, dst);

    notifyListeners();

    return dst.tiles.last;
  }

  /// Adds a new tile with [content] next to currently focused tile in the
  /// [direction] specified.
  TileModel add({
    TileModel nearTile,
    Object content,
    AxisDirection direction = AxisDirection.right,
  }) {
    assert(direction != null);

    final tile = TileModel(
      type: TileType.content,
      content: content,
    );

    if (nearTile == null) {
      tile.parent = root;
      root.tiles.add(tile);
    } else {
      _insert(nearTile, tile, direction);
    }

    notifyListeners();

    return tile;
  }

  /// Removes (deletes) currently focused tile. Focus switches to the tile
  /// preceding it.
  void remove(TileModel tile) {
    assert(tile != null);
    _remove(tile);

    notifyListeners();
  }

  void _initialize(TileModel tile, [TileModel parent]) {
    assert(tile != null);
    tile.parent = parent;
    for (final child in tile.tiles) {
      _initialize(child, tile);
    }
  }

  void _remove(TileModel tile) {
    if (tile == root) {
      return;
    } else {
      // If this tile is NOT the only tile, just remove it from it's parent.
      tile.parent.tiles.remove(tile);
      if (tile.parent.tiles.isEmpty) {
        _remove(tile.parent);
      }
      tile.parent = null;
    }
  }

  void _insert(TileModel focus, TileModel tile, AxisDirection direction) {
    if (focus == root) {
      root = TileModel(
        type: _isHorizontal(direction) ? TileType.column : TileType.row,
        tiles: [root],
      );
      root.tiles.first.parent = root;
      _insert(focus, tile, direction);
      return;
    }

    if ((focus.parent.type == TileType.column && _isHorizontal(direction)) ||
        (focus.parent.type == TileType.row && _isVertical(direction))) {
      int index = focus.parent.tiles.indexOf(focus);
      if (direction == AxisDirection.left || direction == AxisDirection.up) {
        focus.parent.tiles.insert(index, tile);
      } else {
        focus.parent.tiles.insert(index + 1, tile);
      }
      tile.parent = focus.parent;
      return;
    }
    _insert(focus.parent, tile, direction);
  }

  /// Returns the tile next to [tile] in a column or row. If [tile] is the last
  /// tile in the parent, it returns the next ancestor column or row. This is
  /// usefule for finding the tile to the right or below the given [tile].
  TileModel _next(TileModel tile, TileType type) {
    if (tile == null || tile.parent == null) {
      return null;
    }
    assert(tile.parent.tiles.contains(tile));

    final tiles = tile.parent.tiles;
    if (tile.parent.type == type && tile != tiles.last) {
      int index = tiles.indexOf(tile);
      return tiles[index + 1];
    }
    return _next(tile.parent, type);
  }

  /// Returns the tile previous to [tile] in a column or row. If [tile] is the
  /// last tile in the parent, it returns the previous ancestor column or row.
  /// This is useful for finding the tile to the left or above the given [tile].
  TileModel _previous(TileModel tile, TileType type) {
    if (tile == null || tile.parent == null) {
      return null;
    }
    assert(tile.parent.tiles.contains(tile));

    final tiles = tile.parent.tiles;
    if (tile.parent.type == type && tile != tiles.first) {
      int index = tiles.indexOf(tile);
      return tiles[index - 1];
    }
    return _previous(tile.parent, type);
  }

  /// Returns the leaf tile node given a [tile] using depth first search.
  TileModel _first(TileModel tile) {
    if (tile == null || tile.type == TileType.content) {
      return tile;
    }
    return _first(tile.tiles.first);
  }

  /// Returns the leaf tile node given a [tile] using depth last search.
  TileModel _last(TileModel tile) {
    if (tile == null || tile.type == TileType.content) {
      return tile;
    }
    return _last(tile.tiles.last);
  }

  bool _isHorizontal(AxisDirection direction) =>
      direction == AxisDirection.left || direction == AxisDirection.right;

  bool _isVertical(AxisDirection direction) =>
      direction == AxisDirection.up || direction == AxisDirection.down;
}
