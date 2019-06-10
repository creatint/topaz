// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:fidl_fuchsia_net_http/fidl_async.dart' as fidl_net;
import 'package:fidl_fuchsia_web/fidl_async.dart' as fidl_web;
import 'package:flutter_test/flutter_test.dart';
import 'package:fuchsia_webview_flutter/src/fuchsia_web_services.dart';
import 'package:fuchsia_webview_flutter/src/fuchsia_webview_platform_controller.dart';
import 'package:fuchsia_webview_flutter/webview.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore_for_file: implementation_imports

class MockFuchsiaWebServices extends Mock implements FuchsiaWebServices {}

class MockWebViewPlatformCallbacksHandler extends Mock
    implements WebViewPlatformCallbacksHandler {}

class MockFuchsiaWebViewPlatformController extends Mock
    implements FuchsiaWebViewPlatformController {}

class MockNavigationControllerProxy extends Mock
    implements fidl_web.NavigationControllerProxy {}

void main() {
  FuchsiaWebServices mockWebServices = MockFuchsiaWebServices();
  fidl_web.NavigationControllerProxy mockNavigationController =
      MockNavigationControllerProxy();

  group('Custom platform implementation', () {
    setUpAll(() {
      when(mockWebServices.navigationController)
          .thenReturn(mockNavigationController);
      WebView.platform = FuchsiaWebView(fuchsiaWebServices: mockWebServices);
    });

    tearDownAll(() {
      WebView.platform = null;
    });

    testWidgets('Create WebView', (WidgetTester tester) async {
      await tester.pumpWidget(const WebView());
    });

    testWidgets('loadUrl', (WidgetTester tester) async {
      WebViewController controller;
      await tester.pumpWidget(
        WebView(
          onWebViewCreated: (WebViewController webViewController) {
            controller = webViewController;
          },
        ),
      );

      final headers = <String, String>{'header': 'value'};
      String url = 'https://google.com';
      await controller.loadUrl(url, headers: headers);

      verify(mockNavigationController.loadUrl(
          url,
          fidl_web.LoadUrlParams(
            type: fidl_web.LoadUrlReason.typed,
            headers: [
              fidl_net.Header(
                  name: utf8.encode('header'), value: utf8.encode('value'))
            ],
          )));
    });
  });
}
