// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' show min;

import 'package:meta/meta.dart';

import 'block.dart';
import 'heap.dart' show Heap;
import 'vmo_fields.dart';
import 'vmo_holder.dart';
import 'vmo_writer.dart';

// TODO(fmil): Remove the duplication here.
const int _pageSizeBytes = 4096;

/// Implements a two-level slab allocator over a VMO object.
///
/// Please see README.md for implementation details.  Main ideas are taken from
/// the Slab32 which is the original heap allocator implementation.
class LittleBigSlab implements Heap {
  /// Size in bytes of the touched / visited subset of the VMO incorporated in
  /// the data structure.
  int _currentSizeBytes;
  // The underlying VMO which is sub-allocated.
  final VmoHolder _vmo;
  // The size of the small slabs in bytes.
  final int _smallSizeBytes;
  // The size of the big slabs, in bytes.
  final int _bigSizeBytes;
  // The order of the big slabs.
  final int _bigOrder;
  // The order of the small slabs.
  final int _smallOrder;
  // The index of the first big slab that is free.  invalidIndex if not
  // available.
  int _freelistBig = invalidIndex;
  // The index of the first small slab that is free.  invalidIndex if not
  // available.
  int _freelistSmall = invalidIndex;

  /// Creates a new slab allocator with big and small slabs.
  ///
  /// The orders of the big and small blocks are configurable, as long as a few
  /// constraints are respected.  Small order must be smaller than the big order.
  /// The big order slabs must divide evenly into the available space in the VMO.
  /// If either of these two constraints are not met, [ArgumentError] is thrown.
  ///
  /// See the inspect documentation for an explanation of the block orders.
  LittleBigSlab(this._vmo, {int smallOrder = 1, int bigOrder = 2})
      : _bigOrder = bigOrder,
        _smallOrder = smallOrder,
        _smallSizeBytes = 1 << (4 + smallOrder),
        _bigSizeBytes = 1 << (4 + bigOrder) {
    if (_bigSizeBytes <= _smallSizeBytes) {
      throw ArgumentError(
          'smallOrder must be smaller than bigOrder (smallOrder was: $smallOrder, bigOrder was: $bigOrder) ');
    }
    if (_bigSizeBytes % _smallSizeBytes != 0) {
      throw ArgumentError(
          'small blocks must fit into big blocks (smallOrder was: $smallOrder, bigOrder was: $bigOrder) ');
    }
    if (_pageSizeBytes % _bigSizeBytes != 0) {
      throw ArgumentError('Big size does not fit on a page: '
          '$_pageSizeBytes % $_bigSizeBytes != 0');
    }
    _currentSizeBytes = min(_pageSizeBytes, _vmo.size);
    _addFreelistBlocks(
        fromBytes: heapStartIndex * bytesPerIndex, toBytes: _currentSizeBytes);
  }

  /// Creates a new Heap over the supplied VMO holder.
  static Heap create(VmoHolder vmo) => LittleBigSlab(vmo);

  /// Allocates a block using the bytes size hint. The allocated block size may
  /// be smaller than the provided byte size hint, which means that repeated
  /// allocations are needed if more space is required.
  ///
  /// Returns [null] if space could not be allocated.
  @override
  Block allocateBlock(int bytesHint, {bool required = false}) {
    // First, check whether a big block or a small one would be a best fit.
    //
    // If no big blocks available, try to grow the heap.
    // If growing the heap was a success, allocate a big block.
    //
    // If after growing the heap we failed to get something on the big
    // freelist, try to allocate a block from the pool of small blocks even if
    // it is less efficient.
    //
    // If there are no available blocks on the small freelist, check if
    // there is a convertible free big block.  If we actually wanted a big block
    // but got here, then we skip the conversion attempt as we know it will fail.
    //
    // If in the end there are no small blocks to allocate, then give up.
    // Otherwise, allocate.
    final bool big = _isBig(bytesHint, required);
    if (big) {
      if (_freelistBig == invalidIndex) {
        _growHeap(_currentSizeBytes + _pageSizeBytes);
      }
      if (_freelistBig != invalidIndex) {
        var block = Block.read(_vmo, _freelistBig);
        _freelistBig = block.nextFree;
        block.becomeReserved();
        return block;
      }
      assert(_freelistBig == invalidIndex);
    }
    if (!big && _freelistSmall == invalidIndex) {
      _tryConvertBig();
    }
    if (_freelistSmall == invalidIndex) {
      return null;
    }
    var block = Block.read(_vmo, _freelistSmall);
    _freelistSmall = block.nextFree;
    block.becomeReserved();
    return block;
  }

  // Converts a big block into a bunch of small blocks.
  void _tryConvertBig() {
    // If no big blocks are available, try to grow the heap first.
    // If even after attempted heap grow there are no big blocks to use, give up.
    //
    // Else, convert a big block into a bunch of free small blocks.  Unhook the
    // big block from the freelist.  Convert the space obtained this way into a
    // bunch of free blocks.  Hook the blocks up into the small freelist.
    if (_freelistBig == invalidIndex) {
      _growHeap(_currentSizeBytes + _pageSizeBytes);
    }
    if (_freelistBig == invalidIndex) {
      return;
    }
    final int bigIndex = _freelistBig;
    final bigBlock = Block.read(_vmo, _freelistBig);
    _freelistBig = bigBlock.nextFree;
    bigBlock.becomeReserved();

    _markSmallFree(
      startIndex: bigIndex,
      endIndex: bigIndex + _bigSizeBytes ~/ bytesPerIndex,
      stepIndex: _smallSizeBytes ~/ bytesPerIndex,
    );
  }

  /// Frees a previously allocated block.
  ///
  /// Throws [ArgumentError] if a block has been passed in which was not
  /// allocated.
  @override
  void freeBlock(Block block) {
    if (block.type == BlockType.header || block.type == BlockType.free) {
      throw ArgumentError("I shouldn't be trying to free this type "
          '(index ${block.index}, type ${block.type})');
    }
    if (block.index < heapStartIndex ||
        block.index * bytesPerIndex >= _currentSizeBytes) {
      throw ArgumentError('Tried to free bad index ${block.index}');
    }
    final bool big = _isBig(block.size, false);
    if (big) {
      // When freeing a big block, just mark it as free and done.
      block.becomeFree(_freelistBig);
      _freelistBig = block.index;
      return;
    }
    // TODO(fmil): Do we want to merge adjacent smaller blocks together?  This
    // will require an O(n) list traversal, so perhaps we don't want to?
    block.becomeFree(_freelistSmall);
    _freelistSmall = block.index;
  }

  // Returns true if a big slab needs to be allocated, based on the size hint
  // provided by the user.
  bool _isBig(int size, bool required) {
    // If the size is more than the size of a big block, or if a big block is
    // required, recommend a big block.
    if (required || size >= _bigSizeBytes - headerSizeBytes) {
      return true;
    }
    // If the size is somewhere in between, recommend a block based on the
    // amount of space that would be wasted if one block size would be chosen
    // over the other.  For small blocks, we throw away 8 bytes per block.  For
    // large blocks we throw away 8 bytes per block plus slack space at end.
    final int smallSlack =
        (size ~/ _smallSizeBytes + 1) * headerSizeBytes; // Ignore slack.
    assert(size < _bigSizeBytes - headerSizeBytes);
    final int bigSlack = _bigSizeBytes - 8 - size;
    final bool bigWastesLess = bigSlack < smallSlack;
    return bigWastesLess;
  }

  void _growHeap(int desiredSizeBytes) {
    if (_currentSizeBytes == _vmo.size) {
      return; // Fail silently.
    }
    int newSize = desiredSizeBytes;
    if (newSize > _vmo.size) {
      newSize = _vmo.size;
    }
    _addFreelistBlocks(fromBytes: _currentSizeBytes, toBytes: newSize);
    _currentSizeBytes = newSize;
  }

  // Adds blocks between bytes [fromBytes] and [toBytes] to the respective
  // freelists.
  // TODO(fmil): This could probably be recast in terms of indexes.
  void _addFreelistBlocks({@required int fromBytes, @required int toBytes}) {
    // From index 4 to the first index that can be a valid big block, add small
    // blocks.  Beyond that, add only big blocks.

    // Final index past which there are no more small blocks to allocate.
    final int endSmallBytesIndex = _bigSizeBytes ~/ bytesPerIndex;
    final int lastSmallIndex =
        min(toBytes ~/ bytesPerIndex, endSmallBytesIndex);

    _markSmallFree(
        startIndex: fromBytes ~/ bytesPerIndex,
        endIndex: lastSmallIndex,
        stepIndex: _smallSizeBytes ~/ bytesPerIndex);

    // The rest are all big blocks.
    _markBigFree(
      startIndex: endSmallBytesIndex,
      endIndex: toBytes ~/ bytesPerIndex,
      stepIndex: endSmallBytesIndex,
    );
  }

  // Marks successive small blocks as free, starting from startIndex, ending before
  // endIndex, and skipping as many indices as is occupied by the small block.
  void _markSmallFree(
      {@required int startIndex,
      @required int endIndex,
      @required int stepIndex}) {
    for (int i = startIndex; i < endIndex; i += stepIndex) {
      Block.create(_vmo, i, order: _smallOrder).becomeFree(_freelistSmall);
      _freelistSmall = i;
    }
  }

  // Marks successive big blocks as free.  Similar to above.
  void _markBigFree(
      {@required int startIndex,
      @required int endIndex,
      @required int stepIndex}) {
    for (int i = startIndex; i < endIndex; i += stepIndex) {
      Block.create(_vmo, i, order: _bigOrder).becomeFree(_freelistBig);
      _freelistBig = i;
    }
  }
}
