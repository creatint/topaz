/// Copyright 2019 The Fuchsia Authors. All rights reserved.
/// Use of this source code is governed by a BSD-style license that can be
/// found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'package:test/test.dart';
import 'package:fuchsia_inspect_flutter/WidgetTreeTraversal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fuchsia_inspect/inspect.dart';
import 'package:test_vmo_reader/vmo_reader.dart' show VmoReader;
import 'package:fuchsia_inspect/src/vmo/vmo_holder.dart';
import 'package:fuchsia_inspect/src/inspect/internal/_inspect_impl.dart';
import 'package:fuchsia_inspect/src/vmo/vmo_writer.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test_vmo_reader/util.dart';

// This class was made to test the WidgetTreeTraversal class
// The FakeDiagnosticsNode allows properties and children
// to be added to the node.
class FakeDiagnosticsNode extends DiagnosticsNode {
  List<FakeDiagnosticsNode> properties = <FakeDiagnosticsNode>[];
  List<FakeDiagnosticsNode> children = <FakeDiagnosticsNode>[];
  @override
  String value;

  FakeDiagnosticsNode(String newName)
      : super(name: newName, style: DiagnosticsTreeStyle.dense);

  @override
  List<FakeDiagnosticsNode> getChildren() {
    return children;
  }

  @override
  List<FakeDiagnosticsNode> getProperties() {
    return properties;
  }

  void addProperty(String property) {
    var widgetArray = property.split(':');
    if (widgetArray.length < 2) {
      throw Exception('Incorrect input format');
    }
    var fakeNode =
        (FakeDiagnosticsNode(widgetArray[0])..value = widgetArray[1]);
    properties.add(fakeNode);
  }

  void addChild(String child) {
    var widgetArray = child.split(':');
    if (widgetArray.length < 2) {
      throw Exception('Incorrect input format');
    }
    var fakeNode =
        (FakeDiagnosticsNode(child)..value = widgetArray[1]);
    children.add(fakeNode);
  }

  @override
  String toDescription({TextTreeConfiguration parentConfiguration}) {
    return '$value';
  }
}

void main() {
  VmoHolder vmo;
  Node root;
  const defaultVmoSize = 256 * 1024;

  setUp(() {
    var context = StartupContext.fromStartupInfo();
    vmo = FakeVmo(defaultVmoSize);
    var writer = VmoWriter.withVmo(vmo);
    Inspect inspect =
        InspectImpl(context.outgoing.debugDir(), 'root.inspect', writer);
    root = inspect.root;
  });

  // TODO: add another test case to show that information that shouldn't be
  // displayed isn't displayed
  test('Widget Tree Output is correct', () async {
    FakeDiagnosticsNode fakeNode = (FakeDiagnosticsNode('IGNORED')
      ..addProperty('widget: node1')
      ..addProperty('prop1: value1')
      ..addProperty('prop2: value2')
      ..addProperty('prop3: value3')
      ..addChild('widget: node2')
      ..children[0].addProperty('widget: node2'));
    WidgetTreeTraversal.inspectFromDiagnostic(fakeNode, root);
    expect(VmoReader(vmo).toString(), (
            '<> Node: "root"\n'
            '<> >> Node: " node1"\n'
            '<> >> >> StringProperty "prop3": " value3"\n'
            '<> >> >> StringProperty "prop2": " value2"\n'
            '<> >> >> StringProperty "prop1": " value1"\n'
            '<> >> >> StringProperty "widget": " node1"\n'
            '<> >> >> Node: " node2"\n'
            '<> >> >> >> StringProperty "widget": " node2"\n'
            ));
  });
}
