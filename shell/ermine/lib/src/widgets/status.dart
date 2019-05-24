// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../models/status_model.dart';

/// Builds the display for the Status menu.
class Status extends StatelessWidget {
  final StatusModel model;

  const Status({this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple[300],
    );
  }
}
