// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart' as fidl;
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl_modular;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_modular/lifecycle.dart';

import 'story_visual_state_watcher_impl.dart';

/// An implementation of the [StoryShell] interface leveraging the "Deja Layout"
/// strategy.
class StoryShellImpl extends fidl_modular.StoryShell {
  final _storyShellContext = fidl_modular.StoryShellContextProxy();
  final _visualStateWatcherBinding =
      fidl_modular.StoryVisualStateWatcherBinding();

  fidl_modular.StoryShellBinding _storyShellBinding;
  StoryVisualStateWatcherImpl _storyVisualStateWatcher;

  // TODO(miguelfrde): add to this stream when a surface focus changes in
  // DejaCompose presenter.
  final _focusEventStreamController = StreamController<String>.broadcast();

  StoryShellImpl() {
    Lifecycle().addTerminateListener(_onLifecycleTerminate);
  }

  void bind(fidl.InterfaceRequest<fidl_modular.StoryShell> request) {
    log.info('Received binding request for StoryShell');
    _clearBinding();
    _storyShellBinding = fidl_modular.StoryShellBinding()..bind(this, request);
  }

  @override
  Future<void> initialize(
      fidl.InterfaceHandle<fidl_modular.StoryShellContext>
          contextHandle) async {
    _storyShellContext.ctrl.bind(contextHandle);
    _storyVisualStateWatcher = StoryVisualStateWatcherImpl();
    await _storyShellContext.watchVisualState(
        _visualStateWatcherBinding.wrap(_storyVisualStateWatcher));
    // TODO(miguelfrde): we can reload story state from the link. Links are
    // deprecated though. New solution needed.
  }

  /// Add a new surface to the story.
  @override
  Future<void> addSurface(
    fidl_modular.ViewConnection viewConnection,
    fidl_modular.SurfaceInfo surfaceInfo,
  ) async {
    // TODO(miguelfrde): route to deja compose strategy.
  }

  /// Focus the surface with this id
  @override
  Future<void> focusSurface(String surfaceId) async {
    // TODO(miguelfrde): route to deja compose strategy.
  }

  /// Defocus the surface with this id
  @override
  Future<void> defocusSurface(String surfaceId) async {
    // TODO(miguelfrde): route to deja compose strategy.
  }

  @override
  Future<void> removeSurface(String surfaceId) async {
    // TODO(miguelfrde); route to deja compose strategy.
  }

  @override
  Future<void> reconnectView(fidl_modular.ViewConnection viewConnection) async {
    // TODO(miguelfrde): not sure what this is for. We probably don't need it
    // (yet).
  }

  @override
  Future<void> updateSurface(
    fidl_modular.ViewConnection viewConnection,
    fidl_modular.SurfaceInfo surfaceInfo,
  ) async {
    // TODO(miguelfrde): route to deja compose strategy, although we probably
    // don't need it (yet).
  }

  @override
  Stream<String> get onSurfaceFocused => _focusEventStreamController.stream;

  @Deprecated('Deprecated')
  @override
  Future<void> addContainer(
    String containerName,
    String parentId,
    fidl_modular.SurfaceRelation relation,
    List<fidl_modular.ContainerLayout> layouts,
    List<fidl_modular.ContainerRelationEntry> relationships,
    List<fidl_modular.ContainerView> views,
  ) async {}

  void _onLifecycleTerminate() {
    _clearBinding();
    _focusEventStreamController.close();
  }

  void _clearBinding() {
    if (_storyShellBinding != null && _storyShellBinding.isBound) {
      _storyShellBinding.unbind();
      _storyShellBinding = null;
    }
  }
}
