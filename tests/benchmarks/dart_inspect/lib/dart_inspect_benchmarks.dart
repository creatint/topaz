// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer' show Timeline;

import 'package:args/args.dart';
import 'package:fuchsia_inspect/inspect.dart';
import 'package:fuchsia/fuchsia.dart' as fuchsia;

// ignore: avoid_classes_with_only_static_members
class UniqueNumber {
  static int value = 0;
  static int next() => value++;
}

void doSingleIteration() {
  Timeline.startSync('Get root');
  var root = Inspect().root;
  Timeline.finishSync();

  Timeline.startSync('Get counter');
  var counterProperty = root.intProperty('foo');
  Timeline.finishSync();

  Timeline.startSync('Set integer');
  counterProperty.setValue(1);
  Timeline.finishSync();

  Timeline.startSync('Inc counter');
  counterProperty.add(1);
  Timeline.finishSync();

  Timeline.startSync('Dec counter');
  counterProperty.subtract(1);
  Timeline.finishSync();

  Timeline.startSync('Add child');
  Node child = root.child('child');
  Timeline.finishSync();

  String name = 'foo${UniqueNumber.next()}';
  Timeline.startSync('Add property');
  var childProp = child.intProperty(name);
  Timeline.finishSync();

  Timeline.startSync('Delete property');
  childProp.delete();
  Timeline.finishSync();

  Timeline.startSync('Delete node');
  child.delete();
  Timeline.finishSync();
}

void main(List<String> args) {
  var parser = ArgParser()
    ..addOption('iterations', defaultsTo: '500', valueHelp: 'iterations');

  int iterations;
  try {
    var parsedArgs = parser.parse(args);
    iterations = int.parse(parsedArgs['iterations']);
  } on FormatException {
    print('dart_inspect_benchmarks got bad args. Please check usage.');
    print('  args = "$args"');
    print(parser.usage);
    fuchsia.exit(1);
  }

  Timeline.startSync('Init and get root');
  Inspect().root;
  Timeline.finishSync();

  for (int i = 0; i < iterations; i++) {
    doSingleIteration();
  }
  fuchsia.exit(0);
}
