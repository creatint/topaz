// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_services/services.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl_modular;

import 'src/story_shell_impl.dart';

void main() {
  setupLogger(name: 'Deja Compose');

  final storyShell = StoryShellImpl();

  StartupContext.fromStartupInfo()
      .outgoing
      .addPublicService(storyShell.bind, fidl_modular.StoryShell.$serviceName);

  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Offstage(), // TODO(miguelfrde): bring dejacompose presenter
    ),
  );
}
