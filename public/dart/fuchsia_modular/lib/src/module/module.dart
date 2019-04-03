// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:fidl_fuchsia_modular/fidl_async.dart' as modular;
import 'package:fuchsia_services/services.dart';
import 'package:meta/meta.dart';

import '../entity/entity.dart';
import 'embedded_module.dart';
import 'intent_handler.dart';
import 'internal/_intent_handler_impl.dart';
import 'internal/_module_impl.dart';
import 'ongoing_activity.dart';

/// The [Module] class provides a mechanism for module authors
/// to interact with the underlying framework. The main responsibilities
/// of the [Module] class are to implement the intent handler
/// interface and the lifecycle interface.
abstract class Module {
  static Module _module;

  /// returns a shared instance of this.
  factory Module() {
    return _module ??= ModuleImpl(
      intentHandlerImpl:
          IntentHandlerImpl(startupContext: StartupContext.fromStartupInfo()),
    );
  }

  /// Starts a new Module instance and adds it to the story. The Module to
  /// execute is identified by the contents of [intent] and the Module instance
  /// is given a [name] in the scope of the starting Module instance. The view
  /// for the Module is given to the StoryShell for display.
  ///
  /// Providing a [surfaceRelation] advises the StoryShell on how to layout
  /// surfaces that the new module creates. If [surfaceRelation] is `null` then
  /// a default relation is used. Note, [surfaceRelation] is an optional
  /// parameter so a default value will be provided:
  /// ```
  /// modular.SurfaceRelation surfaceRelation = modular.SurfaceRelation(
  ///    arrangement: modular.SurfaceArrangement.copresent,
  ///    dependency: modular.SurfaceDependency.dependent,
  ///    emphasis: 0.5,
  /// )
  ///```
  ///
  /// If this method is called again with the same [name] by the same Module
  /// instance, but with different arguments, a new module will be started and
  /// replace the existing one (the ModuleController of the existing module will
  /// be closed). If the [intent] is resolved to the same module, the module
  /// will get the intent.
  ///
  /// A [modular.ModuleController] is returned to the caller to control the start
  /// Module instance. Closing this connection doesn't affect its Module
  /// instance; it just relinquishes the ability of the caller to control the
  /// Module instance.
  ///
  /// The [name] parameter can be used identify a view in the resulting story
  /// and can be used to either update a running module with a new [intent] or
  /// can be used to replace an existing module in the same space if the intent
  /// resolves to a new module instance.
  /// ```
  /// // This code will result in one view being displayed on
  /// // screen with either one module receiving two intents if the
  /// // intents resolve to the same module binaries or one module
  /// // being started and then torn down to start a new module.
  /// Module().addModuleToStory(name: 'foo', intent: foo_intent);
  /// Module().addModuleToStory(name: 'foo', intent: bar_intent);
  /// ```
  ///
  /// ```
  /// // This code will result in two views being displayed on
  /// // screen. They may be the same binary but two different processes
  /// // or they may be two binaries depending on how what modules
  /// // are resolved.
  /// Module().addModuleToStory(name: 'foo', intent: foo_intent);
  /// Module().addModuleToStory(name: 'bar', intent: bar_intent);
  /// ```
  Future<modular.ModuleController> addModuleToStory({
    @required String name,
    @required modular.Intent intent,
    modular.SurfaceRelation surfaceRelation,
  });

  /// Creates an entity that will live for the lifetime of the story.
  /// The entity that is created will be backed by the framework and
  /// can be treated as if it was received from any other entity provider.
  Future<Entity> createEntity({
    @required String type,
    @required Uint8List initialData,
  });

  /// This method functions similarly to [addModuleToStory()], but instead
  /// of relying on the story shell for display it is up to the caller to
  /// display the view from the new module.
  ///
  /// The method will complete with an [EmbeddedModule] which contains the
  /// [modular.ModuleController] and the [views.ViewHolderToken].
  /// The token can be used to embed the child module's view to display in your
  /// module's view hierarchy. This is commonly done in Flutter modules with
  /// the ChildView widget.
  ///
  /// If no modules are found a [ModuleResolutionException] will be thrown.
  @experimental
  Future<EmbeddedModule> embedModule({
    @required String name,
    @required modular.Intent intent,
  });

  /// Registers the [intentHandler] with this.
  ///
  /// This method must be called in the main function of the module
  /// so the framework has a chance to connect the intent handler.
  ///
  /// ```
  /// void main(List<String> args) {
  ///   Module()
  ///     ..registerIntentHandler(MyHandler());
  /// }
  /// ```
  void registerIntentHandler(IntentHandler intentHandler);

  /// When [RemoveSelfFromStory()] is called the framework will stop the
  /// module and remove it from the story. If there are no more running modules
  /// in the story the story will be stopped.
  void removeSelfFromStory();

  /// Requests that the current story and module gain focus. It's up to the
  /// story shell and session shell to honor that request.
  void requestFocus();

  /// Declares that activity of the given [type] is ongoing in this module.
  ///
  /// Modules should call [OngoingActivity.done] when the ongoing activity has
  /// stopped. Pausing media should count as a stopped ongoing activity, and
  /// when it is resumed it should be started as a new ongoing activity.
  /// Conversely, media playing in a continuous playlist (i.e playing the next
  /// video or song) should be treated as the same ongoing activity. Modules
  /// must request a connection per ongoing activity; a single connection may
  /// not be re-used for multiple ongoing activities.
  ///
  /// When an module indicates that it is performing an ongoing activity the
  /// system can make informed decisions about power/memory management. For
  /// example, if the module indicates that it is playing a video the system
  /// can prevent the display from dimming when not in use.
  OngoingActivity startOngoingActivity(modular.OngoingActivityType type);
}
