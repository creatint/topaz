// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler/tiler.dart';

void main() {
  group('init', () {
    test('should create an instance of tiler', () {
      expect(
          Tiler(
            model: null,
            chromeBuilder: null,
            sizerBuilder: null,
          ),
          isNotNull);
    });
    test('should create an instance of TilerModel with null root', () {
      final tiler = TilerModel();
      expect(tiler, isNotNull);
      expect(tiler.root, isNull);
    });
    test('should create an instance of TilerModel with content tile', () {
      final tiler = TilerModel()..add(content: 'x');
      expect(tiler.root.type, TileType.content);
      expect(tiler.root.content, 'x');
    });
    test('should allow initializing with empty row or column', () {
      final tiler = TilerModel(root: TileModel(type: TileType.row));
      expect(tiler.root.type, TileType.row);
      expect(tiler.root.tiles.isEmpty, true);
    });
  });

  group('add tile', () {
    test('should allow specifying nearTile = null with non-null root', () {
      final tiler =
          TilerModel(root: TileModel(type: TileType.content, content: 'root'))
            ..add(content: 'new');
      expect(tiler.root.type, TileType.column);
      expect(tiler.root.tiles.length, 2);
      expect(tiler.root.tiles.first.content, 'root');
      expect(tiler.root.tiles.last.content, 'new');
    });
    test('should allow specifying nearTile = null with null root', () {
      final tiler = TilerModel()..add(content: 'new');
      expect(tiler.root.type, TileType.content);
      expect(tiler.root.tiles.length, 0);
      expect(tiler.root.content, 'new');
    });
    test('should add to the right of given tile in a column', () {
      final tiler = TilerModel(
        root: TileModel(type: TileType.column, tiles: [
          TileModel(
            type: TileType.content,
            content: 'near',
          ),
        ]),
      );
      final nearTile = tiler.root.tiles.first;
      tiler.add(
        nearTile: nearTile,
        direction: AxisDirection.right,
        content: 'right',
      );

      expect(tiler.root.tiles.first.content, 'near');
      expect(tiler.root.tiles.last.content, 'right');
    });
    test('should add to the left of given tile in a column', () {
      final tiler = TilerModel(
        root: TileModel(type: TileType.column, tiles: [
          TileModel(
            type: TileType.content,
            content: 'near',
          ),
        ]),
      );
      final nearTile = tiler.root.tiles.first;
      tiler.add(
        nearTile: nearTile,
        direction: AxisDirection.left,
        content: 'left',
      );

      expect(tiler.root.tiles.last.content, 'near');
      expect(tiler.root.tiles.first.content, 'left');
    });
    test('should add to the top of given tile in a column', () {
      final tiler = TilerModel(
        root: TileModel(type: TileType.column, tiles: [
          TileModel(
            type: TileType.content,
            content: 'near',
          ),
        ]),
      );
      final nearTile = tiler.root.tiles.first;
      tiler.add(
        nearTile: nearTile,
        direction: AxisDirection.up,
        content: 'up',
      );

      // Expected layout:
      // TileType.row [
      //   TileType.content('up'),
      //   TileType.column [
      //     TileType.content('near')
      //   ]
      // ]
      expect(tiler.root.tiles.last.tiles.first.content, 'near');
      expect(tiler.root.tiles.first.content, 'up');
    });
    test('should add to the bottom of given tile in a column', () {
      final tiler = TilerModel(
        root: TileModel(type: TileType.column, tiles: [
          TileModel(
            type: TileType.content,
            content: 'near',
          ),
        ]),
      );
      final nearTile = tiler.root.tiles.first;
      tiler.add(
        nearTile: nearTile,
        direction: AxisDirection.down,
        content: 'down',
      );

      // Expected layout:
      // TileType.row [
      //   TileType.column [
      //     TileType.content('near')
      //   ],
      //   TileType.content('down')
      // ]
      expect(tiler.root.tiles.first.tiles.first.content, 'near');
      expect(tiler.root.tiles.last.content, 'down');
    });
  });

  group('split tile', () {
    test('should not allow splitting a null tile', () {
      expect(() => TilerModel()..split(tile: null), throwsAssertionError);
    });
    test('should reparent a tile being split', () {
      final tiler = TilerModel(
          root: TileModel(
        type: TileType.content,
        content: 'root',
      ));
      tiler.split(tile: tiler.root, content: 'new');
      expect(tiler.root.type, TileType.column);
      expect(tiler.root.tiles.length, 2);
      expect(tiler.root.tiles.first.content, 'root');
      expect(tiler.root.tiles.last.content, 'new');
    });
    test('should reparent tile if split in same direction', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.column,
          tiles: [
            TileModel(
              type: TileType.content,
              content: 'first',
            )
          ],
        ),
      );
      tiler.split(
        tile: tiler.root.tiles.first,
        content: 'new',
        direction: AxisDirection.right,
      );
      // Expected layout:
      // column [column [(first), (new)]]
      expect(tiler.root.type, TileType.column);
      expect(tiler.root.tiles.length, 1);
      expect(tiler.root.tiles.first.type, TileType.column);
      expect(tiler.root.tiles.first.tiles.length, 2);
      expect(tiler.root.tiles.first.tiles.first.content, 'first');
      expect(tiler.root.tiles.first.tiles.last.content, 'new');
    });
    test('should reparent tile if split in cross direction(up)', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.column,
          tiles: [
            TileModel(
              type: TileType.content,
              content: 'first',
            )
          ],
        ),
      );
      tiler.split(
        tile: tiler.root.tiles.first,
        content: 'new',
        direction: AxisDirection.up,
      );
      // Expected layout:
      // column [row [content(new), content(first)]]
      expect(tiler.root.type, TileType.column);
      expect(tiler.root.tiles.length, 1);
      expect(tiler.root.tiles.first.type, TileType.row);
      expect(tiler.root.tiles.first.tiles.length, 2);
      expect(tiler.root.tiles.first.tiles.first.content, 'new');
      expect(tiler.root.tiles.first.tiles.last.content, 'first');
    });
    test('should reparent tile if split in cross direction(down)', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.column,
          tiles: [
            TileModel(
              type: TileType.content,
              content: 'first',
            )
          ],
        ),
      );
      tiler.split(
        tile: tiler.root.tiles.first,
        content: 'new',
        direction: AxisDirection.down,
      );
      // Expected layout:
      // column [row [content(first), content(new)]]
      expect(tiler.root.type, TileType.column);
      expect(tiler.root.tiles.length, 1);
      expect(tiler.root.tiles.first.type, TileType.row);
      expect(tiler.root.tiles.first.tiles.length, 2);
      expect(tiler.root.tiles.first.tiles.first.content, 'first');
      expect(tiler.root.tiles.first.tiles.last.content, 'new');
    });
  });

  group('remove tile', () {
    test('should not allow removing a null tile', () {
      expect(() => TilerModel()..remove(null), throwsAssertionError);
    });
    test('should allow removing the root', () {
      final tiler = TilerModel(
          root: TileModel(
        type: TileType.content,
        content: 'root',
      ));
      tiler.remove(tiler.root);
      expect(tiler.root, isNull);
    });
    test('should remove empty parent, including root', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.row,
          tiles: [
            TileModel(type: TileType.content),
          ],
        ),
      );

      tiler.remove(tiler.root.tiles.first);
      expect(tiler.root, isNull);
    });
    test('should set root to last remaining tile', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.row,
          tiles: [
            TileModel(type: TileType.content, content: 'first'),
            TileModel(type: TileType.content, content: 'second'),
          ],
        ),
      );

      tiler.remove(tiler.root.tiles.last);
      expect(tiler.root.type, TileType.content);
      expect(tiler.root.content, 'first');
    });
    test('should remove parent if left with one tile', () {
      final tiler = TilerModel(
        root: TileModel(
          type: TileType.row,
          tiles: [
            TileModel(type: TileType.content, content: 'first'),
            TileModel(
              type: TileType.row,
              tiles: [
                TileModel(type: TileType.content, content: 'second'),
                TileModel(type: TileType.content, content: 'third'),
              ],
            ),
          ],
        ),
      );

      tiler.remove(tiler.root.tiles.last.tiles.last);
      expect(tiler.root.type, TileType.row);
      expect(tiler.root.tiles.length, 2);
      expect(tiler.root.tiles.first.content, 'first');
      expect(tiler.root.tiles.last.content, 'second');
    });
  });
}
