// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The context in which the CompositionDelegate determines layout
class LayoutContext {
  /// The size of the viewport the CompositionDelegate can use
  final Size size;

  /// Constructor
  const LayoutContext({this.size});
}

/// Simple class for capturing 2D size of boxes in layout.
class Size {
  /// height
  final double height;

  /// width
  final double width;

  /// constructor
  const Size(this.width, this.height);

  /// convert to JSON
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
      };
}
