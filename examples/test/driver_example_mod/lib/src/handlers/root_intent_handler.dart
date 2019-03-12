// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:fuchsia_modular/module.dart';
import 'package:lib.widgets.dart/model.dart'
    show ScopedModel, ScopedModelDescendant;

import '../driver_example_model.dart';

class RootIntentHandler extends IntentHandler {
  @override
  void handleIntent(Intent intent) async {
    DriverExampleModel model = new DriverExampleModel();
    runApp(
      new ScopedModel<DriverExampleModel>(
        model: model,
        child: new MaterialApp(
          home: new Scaffold(
            body: new ScopedModelDescendant<DriverExampleModel>(
              builder: (BuildContext context, Widget child,
                  DriverExampleModel model) {
                return Column(
                  children: <Widget>[
                    new Center(
                      child: new Directionality(
                        textDirection: TextDirection.ltr,
                        child: new Text(
                            'This counter has a value of: ${model.count}'),
                      ),
                    ),
                    new Row(
                      children: <Widget>[
                        new FlatButton(
                          child: const Text('+1'),
                          onPressed: () => model.increment(),
                        ),
                        new FlatButton(
                          child: const Text('-1'),
                          onPressed: () => model.decrement(),
                        ),
                        new FlatButton(
                          child: const Text('+5'),
                          onPressed: () => model.increment(by: 5),
                        ),
                        new FlatButton(
                          child: const Text('-5'),
                          onPressed: () => model.decrement(by: 5),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
