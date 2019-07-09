// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:fuchsia_inspect/src/vmo/block.dart';
import 'package:fuchsia_inspect/src/vmo/heap.dart';
import 'package:fuchsia_inspect/src/vmo/little_big_slab.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_fields.dart';
import 'package:test/test.dart';

import '../util.dart';

// In the VMO data structure, indexes 0..3 are reserved for VMO HEADER block,
// root-node block, and root-node's name.
//
// A 128-byte heap holds indexes 0..7 (at 16 bytes per index).
// Since allocated blocks are 32 bytes, the first allocated block will be at
// index 4, and the second will be at index 6.
//
// Two allocated blocks should be enough to test the data structure
// algorithms, so the heap will be conveniently small at 128 bytes, and
// we'll expect to see 4 and 6 as valid allocated indexes.
const int _heapSizeBytes = 128;

void main() {
  group('Tests inherited from Slab32 allocator:', () {
    test('the initial free state is correct in the VMO', () {
      var vmo = FakeVmo(_heapSizeBytes);
      LittleBigSlab(vmo, smallOrder: 1, bigOrder: 3);
      var f = hexChar(BlockType.free.value);
      compare(vmo, 0x00, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x10, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x20, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x30, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x40, '$f 1 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x50, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x60, '$f 1 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x70, '0  0 000000 00000000  00000000 00000000');
    });

    test('allocate changes VMO contents correctly', () {
      const List<int> _allocatedIndexes = [4, 6];

      var vmo = FakeVmo(_heapSizeBytes);
      var heap = LittleBigSlab(vmo, smallOrder: 1, bigOrder: 3);
      var blocks =
          _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(2));
      var r = hexChar(BlockType.reserved.value);
      compare(vmo, 0x40, '$r 1 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x50, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x60, '$r 1 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x70, '0  0 000000 00000000  00000000 00000000');
    });

    test('free and re-allocate work correctly', () {
      const List<int> _allocatedIndexes = [4, 6];

      var vmo = FakeVmo(_heapSizeBytes);
      var heap = LittleBigSlab(vmo, smallOrder: 1, bigOrder: 5);
      var blocks =
          _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(_allocatedIndexes.length));
      // Free one, get it back
      heap.freeBlock(blocks.removeLast());
      var lastBlock =
          _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      expect(lastBlock, hasLength(1));
      // Free in reverse order to mix up the list
      heap..freeBlock(blocks.removeLast())..freeBlock(lastBlock.removeLast());
      blocks = _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      // Should get two blocks again
      expect(blocks, hasLength(_allocatedIndexes.length));

      // At this point, it is not possible to allocate a continuous big block
      // anymore, until (or if) merging blocks is implemented.
    });
  });
  group('Tests specific to the little big slab allocator:', () {
    test('Allocate a big slab', () {
      const List<int> _allocatedIndexes = [4, 6];

      var vmo = FakeVmo(_heapSizeBytes);
      var heap = LittleBigSlab(vmo, smallOrder: 1, bigOrder: 2);
      var blocks = _allocateEverything(heap,
          sizeHint: 128, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(1));
      var r = hexChar(BlockType.reserved.value);
      compare(vmo, 0x40, '$r 2 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x50, '0  0 000000 00000000  00000000 00000000');
      compare(vmo, 0x60, '0  0 0_0000 00000000  00000000 00000000');
      compare(vmo, 0x70, '0  0 000000 00000000  00000000 00000000');
    });

    test('free and re-allocate work correctly', () {
      List<int> _allocatedIndexes = [4];

      var vmo = FakeVmo(_heapSizeBytes);
      var heap = LittleBigSlab(vmo, smallOrder: 1, bigOrder: 2);
      var blocks = _allocateEverything(heap,
          sizeHint: 128, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(_allocatedIndexes.length));

      // Frees the only block, now the heap is all free.
      heap.freeBlock(blocks.removeLast());

      // Allocate a smaller block now: it will convert the one big block into
      // two smaller ones.
      _allocatedIndexes = [4, 6];
      blocks = _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(_allocatedIndexes.length));
      // Free in reverse order to mix up the list
      heap..freeBlock(blocks.removeLast())..freeBlock(blocks.removeLast());
      // Should get two blocks again
      blocks = _allocateEverything(heap, allocatedIndexes: _allocatedIndexes);
      expect(blocks, hasLength(_allocatedIndexes.length));
    });
  });
}

List<Block> _allocateEverything(Heap heap,
    {int sizeHint = 16, List<int> allocatedIndexes = const []}) {
  var blocks = <Block>[];
  for (Block block = heap.allocateBlock(sizeHint);
      block != null;
      block = heap.allocateBlock(sizeHint)) {
    blocks.add(block);
  }
  // Make sure we're actually getting unique blocks
  expect(Set.of(blocks.map((block) => block.index)), hasLength(blocks.length));
  // With a heapSize-byte VMO, valid indexes are only 4 and 6 (see comment above).
  for (var block in blocks) {
    expect(block.index, isIn(allocatedIndexes));
  }
  return blocks;
}