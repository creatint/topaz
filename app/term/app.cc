// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/app/term/app.h"

#include <lib/ui/scenic/cpp/view_token_pair.h>

#include "examples/ui/lib/skia_font_loader.h"
#include "topaz/app/term/term_params.h"

namespace term {
namespace {

template <typename Iter, typename T>
Iter FindUniquePtr(Iter begin, Iter end, T* object) {
  return std::find_if(begin, end, [object](const std::unique_ptr<T>& other) {
    return other.get() == object;
  });
}

}  // namespace

App::App(TermParams params)
    : params_(std::move(params)), context_(sys::ComponentContext::Create()) {
  context_->outgoing()->AddPublicService<fuchsia::ui::app::ViewProvider>(
      [this](fidl::InterfaceRequest<fuchsia::ui::app::ViewProvider> request) {
        bindings_.AddBinding(this, std::move(request));
      });
  context_->outgoing()->AddPublicService<fuchsia::term::Term>(
      [this](fidl::InterfaceRequest<fuchsia::term::Term> request) {
        term_bindings_.AddBinding(this, std::move(request));
      });
}

void App::CreateView(
    zx::eventpair view_token,
    fidl::InterfaceRequest<fuchsia::sys::ServiceProvider> incoming_services,
    fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> outgoing_services) {
  auto scenic = context_->svc()->Connect<fuchsia::ui::scenic::Scenic>();
  scenic::ViewContextTransitional view_context = {
      .enable_ime = true,
      .session_and_listener_request =
          scenic::CreateScenicSessionPtrAndListenerRequest(scenic.get()),
      .view_token = scenic::ToViewToken(std::move(view_token)),
      .incoming_services = std::move(incoming_services),
      .outgoing_services = std::move(outgoing_services),
      .component_context = context_.get(),
  };

  controllers_.push_back(std::make_unique<ViewController>(
      std::move(view_context), params_,
      [this](ViewController* controller) { DestroyController(controller); }));
}

void App::CreatePty(std::vector<std::string> command,
                    fidl::InterfaceRequest<fuchsia::term::Pty> request,
                    CreatePtyCallback callback) {
  auto client =
      std::make_unique<PtyClient>(std::move(command), std::move(callback));
  pty_bindings_.AddBinding(std::move(client), std::move(request));
  auto* binding = pty_bindings_.bindings().back().get();
  binding->impl()->SetEventSender(binding->events());
}

void App::DestroyController(ViewController* controller) {
  auto it = FindUniquePtr(controllers_.begin(), controllers_.end(), controller);
  ZX_DEBUG_ASSERT(it != controllers_.end());
  controllers_.erase(it);
}

}  // namespace term
