// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <unordered_map>

#include "apps/maxwell/services/suggestion/suggestion_engine.fidl.h"
#include "apps/maxwell/src/bound_set.h"
#include "apps/maxwell/src/suggestion_engine/next_subscriber.h"
#include "apps/maxwell/src/suggestion_engine/suggestion_agent_client_impl.h"
#include "apps/maxwell/src/suggestion_engine/suggestion_record.h"
#include "apps/modular/lib/app/application_context.h"
#include "apps/modular/services/user/story_provider.fidl.h"

namespace maxwell {
namespace suggestion {

class SuggestionAgentClientImpl;

class SuggestionEngineApp : public SuggestionEngine, public SuggestionProvider {
 public:
  SuggestionEngineApp()
      : app_context_(modular::ApplicationContext::CreateFromStartupInfo()) {
    app_context_->outgoing_services()->AddService<SuggestionEngine>(
        [this](fidl::InterfaceRequest<SuggestionEngine> request) {
          bindings_.AddBinding(this, std::move(request));
        });
    app_context_->outgoing_services()->AddService<SuggestionProvider>(
        [this](fidl::InterfaceRequest<SuggestionProvider> request) {
          suggestion_provider_bindings_.AddBinding(this, std::move(request));
        });
  }

  // SuggestionProvider

  void SubscribeToInterruptions(
      fidl::InterfaceHandle<Listener> listener) override;

  void SubscribeToNext(
      fidl::InterfaceHandle<Listener> listener,
      fidl::InterfaceRequest<NextController> controller) override;

  void InitiateAsk(fidl::InterfaceHandle<Listener> listener,
                   fidl::InterfaceRequest<AskController> controller) override;

  void NotifyInteraction(const fidl::String& suggestion_uuid,
                         InteractionPtr interaction) override;

  // end SuggestionProvider

  // SuggestionEngine

  void RegisterSuggestionAgent(
      const fidl::String& url,
      fidl::InterfaceRequest<SuggestionAgentClient> client) override;

  void SetStoryProvider(
      fidl::InterfaceHandle<modular::StoryProvider> story_provider) override;

  // end SuggestionEngine

 private:
  friend class SuggestionAgentClientImpl;

  std::unique_ptr<modular::ApplicationContext> app_context_;

  std::unordered_map<std::string, std::unique_ptr<SuggestionAgentClientImpl>>
      sources_;
  // TODO(rosswang): limit ranking window size based on listeners
  std::vector<Suggestion*> ranked_suggestions_;
  // indexed by suggestion ID
  std::unordered_map<std::string, SuggestionRecord*> suggestions_;

  fidl::BindingSet<SuggestionEngine> bindings_;
  maxwell::BindingSet<NextController,
                      std::unique_ptr<NextSubscriber>,
                      NextSubscriber::GetBinding>
      next_subscribers_;
  fidl::BindingSet<SuggestionProvider> suggestion_provider_bindings_;
};

}  // namespace suggestion
}  // namespace maxwell
