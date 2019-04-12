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
    this.sizerThickness = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (_, __) => model.root != null
          ? Tile(
              model: model.root,
              chromeBuilder: chromeBuilder,
              sizerBuilder: sizerBuilder,
              sizerThickness: sizerThickness,
            )
          : Offstage(),
    );
  }
}

/// Defines a model to hold a tree of [TileModel]s. The leaf nodes are tiles
/// of type [TileType.content], branches can be [TileType.column] or
/// [TileType.row]. The member [root] holds the reference to the root tile.
class TilerModel<T> extends ChangeNotifier {
  TileModel<T> root;

  /// Initializes the [TilerModel] to start layout in supplied [direction].
  TilerModel({this.root}) {
    if (root != null) {
      _initialize(root);
    }
  }

  /// Returns the tile next to [tile] in the given [direction].
  TileModel<T> navigate(AxisDirection direction, TileModel<T> tile) {
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
  /// The [tile] is split such that new tile has supplied [flex].
  TileModel<T> split({
    @required TileModel tile,
    T content,
    AxisDirection direction = AxisDirection.right,
    double flex = 0.5,
  }) {
    assert(tile != null);
    assert(flex > 0 && flex < 1);

    final parent = tile.parent;

    final newTile = TileModel<T>(
      type: TileType.content,
      content: content,
      flex: flex,
    );

    final newParent = TileModel<T>(
      type: _isHorizontal(direction) ? TileType.column : TileType.row,
      tiles: axisDirectionIsReversed(direction)
          ? [newTile, tile]
          : [tile, newTile],
    );

    // If parent is null, tile should be the root tile.
    if (parent == null) {
      assert(tile == root);
      root = newParent;
    } else {
      int index = parent?.tiles?.indexOf(tile) ?? 0;
      parent?.tiles?.remove(tile);
      // Copy existing flex and resize offsets from tile.
      newParent.copy(tile);
      tile.reset();
      newParent.parent = parent;
      parent.tiles.insert(index, newParent);
    }

    newTile.parent = newParent;
    tile
      ..parent = newParent
      ..flex = 1 - flex;

    notifyListeners();

    return newTile;
  }

  /// Adds a new tile with [content] next to currently focused tile in the
  /// [direction] specified.
  TileModel<T> add({
    TileModel<T> nearTile,
    T content,
    AxisDirection direction = AxisDirection.right,
  }) {
    assert(direction != null);

    final tile = TileModel<T>(
      type: TileType.content,
      content: content,
    );

    if (root == null) {
      root = tile;
    } else {
      nearTile ??= root;
      _insert(nearTile, tile, direction);
    }

    notifyListeners();

    return tile;
  }

  /// Removes (deletes) currently focused tile. Focus switches to the tile
  /// preceding it.
  void remove(TileModel<T> tile) {
    assert(tile != null);
    _remove(tile);

    notifyListeners();
  }

  void _initialize(TileModel<T> tile, [TileModel<T> parent]) {
    assert(tile != null);
    tile.parent = parent;
    for (final child in tile.tiles) {
      _initialize(child, tile);
    }
  }

  void _remove(TileModel<T> tile) {
    if (tile == root) {
      root = null;
    } else {
      assert(tile.parent != null);
      final parent = tile.parent;
      parent.tiles.remove(tile);
      if (parent.tiles.isEmpty) {
        // Remove empty parent.
        _remove(parent);
      } else if (parent.tiles.length == 1) {
        // For parent with only one child, move the child to it's grand parent.
        // and remove the parent.
        final grandParent = parent.parent;
        if (grandParent != null) {
          final index = grandParent.tiles.indexOf(parent);
          var child = parent.tiles.first;
          parent.tiles.remove(child);
          grandParent.tiles.remove(parent);

          child.parent = grandParent;
          grandParent.tiles.insert(index, child);
        } else {
          assert(parent == root);
          root = parent.tiles.first..parent = null;
        }
      }
      tile.parent = null;
    }
  }

  void _insert(TileModel<T> focus, TileModel<T> tile, AxisDirection direction) {
    if (focus == root) {
      root = TileModel<T>(
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
  TileModel<T> _next(TileModel<T> tile, TileType type) {
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
  TileModel<T> _previous(TileModel<T> tile, TileType type) {
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
  TileModel<T> _first(TileModel<T> tile) {
    if (tile == null || tile.type == TileType.content) {
      return tile;
    }
    return _first(tile.tiles.first);
  }

  /// Returns the leaf tile node given a [tile] using depth last search.
  TileModel<T> _last(TileModel<T> tile) {
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
