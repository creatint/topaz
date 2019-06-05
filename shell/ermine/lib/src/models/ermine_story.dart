// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:fidl_fuchsia_modular/fidl_async.dart'
    show StoryInfo, StoryController, StoryState, StoryVisibilityState;
import 'package:fuchsia_modular_flutter/session_shell.dart'
    show SessionShell, Story;
import 'package:fuchsia_scenic_flutter/child_view_connection.dart';

import 'cluster_model.dart';

/// Defines a concrete implementation for [Story] for Ermine.
class ErmineStory implements Story {
  @override
  final StoryInfo info;

  final SessionShell sessionShell;

  final StoryController controller;

  final ClustersModel clustersModel;

  ErmineStory({
    this.info,
    this.sessionShell,
    this.controller,
    this.clustersModel,
  });

  @override
  String get id => info.id;

  ValueNotifier<ChildViewConnection> childViewConnectionNotifier =
      ValueNotifier(null);

  @override
  ChildViewConnection get childViewConnection =>
      childViewConnectionNotifier.value;

  @override
  set childViewConnection(ChildViewConnection value) =>
      childViewConnectionNotifier.value = value;

  ValueNotifier<bool> focusedNotifier = ValueNotifier(false);
  @override
  bool get focused => focusedNotifier.value;

  @override
  set focused(bool value) => focusedNotifier.value = value;

  ValueNotifier<StoryState> stateNotifier = ValueNotifier(null);
  @override
  StoryState get state => stateNotifier.value;

  @override
  set state(StoryState value) => stateNotifier.value = value;

  ValueNotifier<StoryVisibilityState> visibilityStateNotifier =
      ValueNotifier(null);

  @override
  StoryVisibilityState get visibilityState => visibilityStateNotifier.value;

  @override
  set visibilityState(StoryVisibilityState value) =>
      visibilityStateNotifier.value = value;

  bool get isImmersive => visibilityState == StoryVisibilityState.immersive;

  @override
  void delete() => sessionShell.deleteStory(id);

  @override
  void focus() => sessionShell.focusStory(id);

  @override
  void stop() => sessionShell.stopStory(id);

  void maximize() {
    clustersModel.maximize(id);
  }

  void restore() {
    clustersModel.restore(id);
  }
}
