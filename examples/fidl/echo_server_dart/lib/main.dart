// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fidl_examples_echo/fidl.dart';
import 'package:lib.app.dart/app.dart';

bool quiet = false;

class _EchoImpl extends Echo {
  final EchoBinding _binding = EchoBinding();

  void bind(InterfaceRequest<Echo> request) {
    _binding.bind(this, request);
  }

  @override
  void echoString(String value, void callback(String response)) {
    if (!quiet) {
      print('EchoString: $value');
    }
    callback(value);
  }
}

StartupContext _context;
_EchoImpl _echo;

void main(List<String> args) {
  quiet = args.contains('-q');
  _context = StartupContext.fromStartupInfo();
  _echo = _EchoImpl();
  _context.outgoingServices
      .addServiceForName<Echo>(_echo.bind, Echo.$serviceName);
}
