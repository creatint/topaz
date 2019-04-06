// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:fidl_fuchsia_mem/fidl.dart' as fuchsia_mem;
import 'package:fidl_fuchsia_modular/fidl.dart';
import 'package:zircon/zircon.dart';

/// Dart-idiomatic wrapper to create a modular.Intent.
class IntentBuilder {
  final Intent _intent;

  // Creates a new intent builder with both an action and a handler.
  IntentBuilder({String action, String handler})
      : _intent = Intent(
            action: action, handler: handler, parameters: <IntentParameter>[]);

  // Creates a new intent builder where the intent's action is set to the
  // provided name.
  IntentBuilder.action(String name)
      : _intent = Intent(action: name, parameters: <IntentParameter>[]);

  // Creates a new intent builder where the intent's handler is set to the
  // provided handler string.
  IntentBuilder.handler(String handler)
      : _intent = Intent(
            action: '', handler: handler, parameters: <IntentParameter>[]);

  // Converts |value| to a JSON object and adds it to the Intent. For typed
  // data, prefer to use addParameterFromEntityReference().
  void addParameter<T>(String name, T value) {
    String jsonString = json.encode(value);
    var jsonList = Uint8List.fromList(utf8.encode(jsonString));
    var data = fuchsia_mem.Buffer(
      vmo: SizedVmo.fromUint8List(jsonList),
      size: jsonList.length,
    );
    _addParameter(name, IntentParameterData.withJson(data));
  }

  // Adds a parameter that containts an entity reference to the intent.
  void addParameterFromEntityReference(String name, String reference) {
    _addParameter(name, IntentParameterData.withEntityReference(reference));
  }

  // The intent being built.
  Intent get intent => _intent;

  void _addParameterFromIntentParameter(IntentParameter parameter) {
    _intent.parameters.add(parameter);
  }

  void _addParameter(String name, IntentParameterData parameterData) {
    _addParameterFromIntentParameter(
        IntentParameter(name: name, data: parameterData));
  }
}
