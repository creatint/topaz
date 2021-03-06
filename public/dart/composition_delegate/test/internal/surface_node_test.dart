// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'package:composition_delegate/composition_delegate.dart';
import 'package:composition_delegate/src/internal/tree/_surface_node.dart';
import 'package:test/test.dart';
// import 'package:lib.app.dart/logging.dart';

void main() {
  /// Easier to reason about 'family' tree
  SurfaceNode grandparent; // the root
  SurfaceNode parent;
  SurfaceNode uncle;
  SurfaceNode aunt;
  SurfaceNode cousin;
  SurfaceNode sibling;
  SurfaceNode child;

  List<SurfaceNode> expectedList;
  List<SurfaceNode> detachedParent;

  setUp(() {
    // The Family Tree from Child's perspective
    //                     +----------------+
    //                     |  Grandparent   |
    //                     +----------------+
    //                             |
    //             +------------------------------+
    //             |               |              |
    //        +----------+    +---------+    +--------+
    //        |  Parent  |    |  Uncle  |    |  Aunt  |
    //        +----------+    +---------+    +--------+
    //             |                              |
    //       +------------+                       |
    //       |            |                       |
    //  +---------+ +-----------+           +----------+
    //  |  child  | |  sibling  |           |  cousin  |
    //  +---------+ +-----------+           +----------+
    //
    uncle = SurfaceNode(surface: Surface(surfaceId: 'uncle'));
    cousin = SurfaceNode(surface: Surface(surfaceId: 'cousin'));
    sibling = SurfaceNode(surface: Surface(surfaceId: 'sibling'));
    child = SurfaceNode(surface: Surface(surfaceId: 'child'));

    aunt =
        SurfaceNode(surface: Surface(surfaceId: 'aunt'), childNodes: [cousin]);
    parent = SurfaceNode(
        surface: Surface(surfaceId: 'parent'), childNodes: [child, sibling]);
    grandparent = SurfaceNode(
        surface: Surface(surfaceId: 'grandparent'),
        childNodes: [parent, uncle, aunt]);
    detachedParent = <SurfaceNode>[grandparent, uncle, aunt, cousin];

    expectedList = <SurfaceNode>[
      grandparent,
      parent,
      uncle,
      aunt,
      child,
      sibling,
      cousin,
    ];
  });

  group('Test SurfaceNode in surface_node.dart', () {
    /// Writing tests to ensure the behavior of SurfaceNode WAI, but the
    /// intention is for Tree building an manipulation to happen via SurfaceTree
    test('SurfaceNode children are returned', () {
      expect(grandparent.childNodes.toList(), equals([parent, uncle, aunt]));
    });
    test('SurfaceNode ancestors are found (multi-generation)', () {
      expect(child.ancestors.toList(), equals([parent, grandparent]));
    });
    test('SurfaceNode parent is found', () {
      expect(child.parentNode, equals(parent));
    });
    test('SurfaceNode Tree is flattened breadth-first', () {
      // flatten - breadth first
      expect(grandparent.toList(), equals(expectedList));
    });
    test('Detaching a SurfaceNode removes SurfaceNode and successors', () {
      grandparent.detach(childNode: parent);
      expect(grandparent.toList(), equals(detachedParent));
    });
    test('Successors remain attached to detached ancestor SurfaceNode', () {
      grandparent.detach(childNode: parent);
      expect(child.ancestors.toList(), equals([parent]));
    });
    test('Siblings of a SurfaceNode are found correctly', () {
      expect(child.siblings.toList(), equals([sibling]));
    });
  });
}
