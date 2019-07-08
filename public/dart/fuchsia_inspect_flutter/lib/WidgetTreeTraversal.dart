// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_inspect/inspect.dart';

/// This class provides methods to convert from Flutter DiagnosticsNodes to
/// Inspect format nodes.
class WidgetTreeTraversal {
  /// Converts an diagnostics tree into a Node tree
  /// Creates a Node with Inspect data based on what
  /// information was in the DiagnosticsNode and attaches
  /// it to the parent
  static void inspectFromDiagnostic(DiagnosticsNode diagnostics, Node parent) {
    /// Finds the name of the widget and assigns it to the name of the node.
    String name = '';
    for (DiagnosticsNode diagNode in diagnostics.getProperties()) {
      /// Used to obtain the name of the widget by checking which
      /// property is titled "widget"
      if (diagNode.name == 'widget') {
        name = diagNode.value.toString();
        break;
      }
    }

    // If the name of the child does not exist abort
    if(name == ''){
      print('Name of node cannot be found');
      return;
    }

    // TODO: add hashcode to the child name so that the same widgets do not get
    // their properties merged
    var childNode = parent.child('$name');

    /// For each property, add the property to the node.
    for (DiagnosticsNode diagNode in diagnostics.getProperties()) {
      /// If the property isn't null, then get the name of the property
      /// and assign its value. The value of the property can be null
      /// but the property itself cannot be null. If the property is null then
      /// the array will only have a size of 1.
      /// TODO: add a check for if the name is null or if the value is null
      var widgetArray = diagNode.toString().split(':');
      if (widgetArray.length > 1) {
        childNode.stringProperty(diagNode.name).setValue(diagNode.toDescription());
      }
    }

    for (DiagnosticsNode diagNode in diagnostics.getChildren()) {
      inspectFromDiagnostic(diagNode, childNode);
    }
  }
}
