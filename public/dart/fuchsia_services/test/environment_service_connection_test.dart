// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: implementation_imports
import 'package:fidl/fidl.dart';
import 'package:fuchsia_services/src/environment_service_connection.dart';
import 'package:test/test.dart';

void main() {
  group('connectToEnvironmentService', () {
    test('throws if serviceProxy is null', () {
      expect(() => connectToEnvironmentService(null), throwsException);
    });
  });
}

class FakeAsyncProxy<T> extends AsyncProxy<T> {
  String serviceName;
  String interfaceName;
  FakeAsyncProxy(this.serviceName, this.interfaceName)
      : super(AsyncProxyController(
          $serviceName: serviceName,
          $interfaceName: interfaceName,
        ));
}