// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:fidl/fidl.dart' show InterfaceRequest;
import 'package:fidl_fuchsia_modular/fidl_async.dart' as modular;

import '../../story_shell.dart';
import '_modular_story_shell_impl.dart';

typedef StoryShellFactory = StoryShell Function(String id);
typedef StoryShellCallback = void Function(StoryShell storyShell);

/// Implements [modular.StoryShellFactory].
///
/// Allows callers to provide callbacks when a story is attached or detached in
/// the session shell.
class StoryShellFactoryImpl extends modular.StoryShellFactory {
  /// Callback to get notified when a story with given id is started.
  final StoryShellFactory onStoryAttached;

  /// Callback to get notified when a story with given id is stopped.
  final ValueChanged<StoryShell> onStoryDetached;

  final _storiesById = <String, ModularStoryShellImpl>{};

  /// Constructor.
  StoryShellFactoryImpl({
    @required this.onStoryAttached,
    this.onStoryDetached,
  }) : assert(onStoryAttached != null);

  @override
  Future<void> attachStory(
    String id,
    InterfaceRequest<modular.StoryShell> request,
  ) async {
    final storyShell = onStoryAttached(id);
    final modularStoryShell = newModularStoryShell(storyShell, request);

    _storiesById[id] = modularStoryShell;
  }

  @override
  Future<void> detachStory(String id) async {
    final modularStoryShell = _storiesById.remove(id);

    onStoryDetached?.call(modularStoryShell.storyShell);
  }

  /// Create a new instance of [ModularStoryShellImpl]. Used for testing.
  @visibleForTesting
  ModularStoryShellImpl newModularStoryShell(
    StoryShell storyShell,
    InterfaceRequest<modular.StoryShell> request,
  ) =>
      ModularStoryShellImpl(storyShell)..bind(request);
}
