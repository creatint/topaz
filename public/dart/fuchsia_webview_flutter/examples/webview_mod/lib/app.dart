// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fuchsia_modular/entity.dart';
import 'package:webview_flutter/webview_flutter.dart';

class App extends StatefulWidget {
  final Stream<Entity> entityStream;
  const App({
    @required this.entityStream,
    Key key,
  })  : assert(entityStream != null),
        super(key: key);
  @override
  State<App> createState() => AppState(entityStream);
}

StreamSubscription<String> _entityStreamSubscriber;

class AppState extends State<App> {
  final TextEditingController _textEditingController;
  WebViewController _webViewController;
  Stream<Entity> _entityStream;

  AppState(this._entityStream)
      : _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // initialize url from a passed intent param if one was present
    _entityStream.listen((entity) {
      _entityStreamSubscriber =
          entity.watch().map(utf8.decode).listen((String url) {
        _textEditingController.text = url;
      });
    });
  }

  @override
  void dispose() {
    _entityStreamSubscriber.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Webview Mod',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildBackBtn(),
                _buildFwdBtn(),
                _buildReloadBtn(),
                _buildUrlTextField(),
                _buildEnterBtn(),
                _buildClearBtn(),
                _buildCurrentBtn(),
              ],
            ),
            _buildWebview(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTextField() {
    return Expanded(
      child: TextField(
        controller: _textEditingController,
        decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(25.0),
              ),
            ),
            filled: true,
            hintStyle: TextStyle(color: Colors.grey[800]),
            hintText: 'Enter URL',
            fillColor: Colors.white70),
      ),
    );
  }

  Widget _buildEnterBtn() {
    return IconButton(
      icon: Icon(Icons.play_arrow),
      tooltip: 'Enter',
      onPressed: () => _loadUrl(_textEditingController.text),
    );
  }

  Widget _buildClearBtn() {
    return IconButton(
      icon: Icon(Icons.clear),
      tooltip: 'Clear',
      onPressed: _textEditingController.clear,
    );
  }

  Widget _buildCurrentBtn() {
    return RaisedButton(
      child: const Text('Current'),
      color: Theme.of(context).accentColor,
      elevation: 4.0,
      splashColor: Colors.blueGrey,
      onPressed: () {
        _webViewController.currentUrl().then((url) {
          _textEditingController.text = url;
        });
      },
    );
  }

  Widget _buildReloadBtn() {
    return IconButton(
      icon: Icon(Icons.refresh),
      tooltip: 'Reload',
      onPressed: () => _webViewController.reload(),
    );
  }

  Widget _buildBackBtn() {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () => _webViewController?.goBack()
    );
  }

  Widget _buildFwdBtn() {
    return IconButton(
      icon: Icon(Icons.arrow_forward),
      tooltip: 'Forward',
      onPressed: () => _webViewController?.goForward()
    );
  }

  Widget _buildWebview() {
    return Expanded(
      child: Container(
        child: WebView(
          onWebViewCreated: (WebViewController controller) {
            _webViewController = controller;
          },
        ),
      ),
    );
  }

  void _loadUrl(String url) {
    if (url == null || url.isEmpty) {
      return;
    }
    Uri uri = Uri.parse(url);
    if (!uri.hasScheme) {
      uri = uri.replace(scheme: 'https');
    }
    _webViewController?.loadUrl(uri.toString());
  }
}
