// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Names and numbers from the VMO spec.
///
/// Defines BlockType enum.
///
/// Defines BitRange's for all the header and payload fields.

// ignore_for_file: prefer_constructors_over_static_methods

import 'bitfield64.dart';

/// Index of the one-and-only header block (16 bytes).
const int headerIndex = 0;

/// 'INSP' utf8 string for HEADER block magic value.
const int headerMagicNumber = 0x50534e49;

/// Each increment of [index] is 16 bytes in the VMO.
const int bytesPerIndex = 16;

/// Version for HEADER block.
const int headerVersionNumber = 0;

/// Index of the one-and-only root node (16 bytes).
const int rootNodeIndex = 1;

/// Each Node needs a parent; Root's parent is 0, which is never a real node.
const int rootParentIndex = 0;

/// Index of the NAME of the one-and-only root node (32 bytes).
const int rootNameIndex = 2;

/// Name of the root node.
const String rootName = 'root';

/// First index availalbe for the heap.
const int heapStartIndex = 4;

/// Size of VMO-block's header bitfield in bytes.
const int headerSizeBytes = 8;

/// Types of VMO blocks.
///
/// Basically an enum with conversion to/from specified numeric values.
class BlockType {
  /// Gets the numeric [value] of this member.
  final int value;

  /// Printable [name] of the element.
  final String name;

  /// Contains all elements.
  static const List<BlockType> values = [
    free,
    reserved,
    header,
    nodeValue,
    intValue,
    uintValue,
    doubleValue,
    propertyValue,
    extent,
    nameUtf8,
    tombstone,
    anyValue
  ];

  @override
  String toString() => name;

  const BlockType._(this.value, this.name);

  /// Empty block, ready to be used.
  static const BlockType free = const BlockType._(0, 'free');

  /// In transition toward being used.
  static const BlockType reserved = const BlockType._(1, 'reserved');

  /// One block to rule them all. Index 0.
  static const BlockType header = const BlockType._(2, 'header');

  /// An entry in the Inspect tree, which may hold child Values: Nodes,
  /// Metrics, or Properties.
  static const BlockType nodeValue = const BlockType._(3, 'nodeValue');

  /// An int Metric.
  static const BlockType intValue = const BlockType._(4, 'intValue');

  /// A uint Metric.
  static const BlockType uintValue = const BlockType._(5, 'uintValue');

  /// A double Metric.
  static const BlockType doubleValue = const BlockType._(6, 'doubleValue');

  /// The header of a string or byte-vector Property.
  static const BlockType propertyValue = const BlockType._(7, 'properytValue');

  /// The contents of a string Property (in a singly linked list, if necessary).
  static const BlockType extent = const BlockType._(8, 'extent');

  /// The name of a Value (Property, Metric, or Node) stored as utf8.
  ///
  /// Name must be contained in this one block. This may truncate utf8 strings
  /// in the middle of a multibyte character.
  static const BlockType nameUtf8 = const BlockType._(9, 'nameUtf8');

  /// A property that's been deleted but still has live children.
  static const BlockType tombstone = const BlockType._(10, 'tombstone');

  /// *_VALUE type, for internal use.
  ///
  /// Not valid if written to VMO.
  static const BlockType anyValue = const BlockType._(11, 'anyValue');
}

/// Order defines the block size: 1 << (order + 4).
final BitRange orderBits = BitRange(0, 3);

/// Type is one of the BlockType values.
final BitRange typeBits = BitRange(4, 7);

/// Version field of HEADER-type blocks.
final BitRange headerVersionBits = BitRange(8, 31);

/// "Magic" field of HEADER-type blocks.
final BitRange headerMagicBits = BitRange(32, 63);

/// NextFreeBlock field of FREE-type blocks.
final BitRange nextFreeBits = BitRange(8, 35);

/// Parent Index field of *_VALUE blocks.
final BitRange parentIndexBits = BitRange(8, 35);

/// Name Index field of *_VALUE blocks.
final BitRange nameIndexBits = BitRange(36, 63);

/// Total Length field of PROPERTY_VALUE blocks payload bits.
final BitRange propertyTotalLengthBits = BitRange(0, 31);

/// Extent Index field of PROPERTY_VALUE blocks payload bits.
final BitRange propertyExtentIndexBits = BitRange(32, 59);

/// Flags field of PROPERTY_VALUE blocks payload bits.
final BitRange propertyFlagsBits = BitRange(60, 63);

/// Next Extent field of EXTENT blocks.
final BitRange nextExtentBits = BitRange(8, 35);

/// Length field of NAME blocks.
final BitRange nameLengthBits = BitRange(8, 19);
