// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_APP_TERM_APP_H_
#define TOPAZ_APP_TERM_APP_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <fuchsia/ui/app/cpp/fidl.h>
#include <lib/zx/eventpair.h>

#include "examples/ui/lib/skia_font_loader.h"
#include "topaz/app/term/pty_client.h"
#include "topaz/app/term/term_params.h"
#include "topaz/app/term/view_controller.h"

namespace term {

class App : public fuchsia::ui::app::ViewProvider, public fuchsia::term::Term {
 public:
  explicit App(TermParams params);
  ~App() = default;

  // |fuchsia::ui::app::ViewProvider|
  void CreateView(
      zx::eventpair view_token,
      fidl::InterfaceRequest<fuchsia::sys::ServiceProvider> incoming_services,
      fidl::InterfaceHandle<fuchsia::sys::ServiceProvider> outgoing_services)
      override;

  // |fuchsia::term::Term|
  void CreatePty(std::vector<::std::string> commandArgs,
                 fidl::InterfaceRequest<fuchsia::term::Pty> request,
                 CreatePtyCallback callback) override;

  void DestroyController(ViewController* controller);

 private:
  App(const App&) = delete;
  App& operator=(const App&) = delete;

  TermParams params_;
  std::unique_ptr<sys::ComponentContext> context_;
  fidl::BindingSet<fuchsia::ui::app::ViewProvider> bindings_;
  fidl::BindingSet<fuchsia::term::Term> term_bindings_;
  fidl::BindingSet<fuchsia::term::Pty, std::unique_ptr<PtyClient>>
      pty_bindings_;
  std::vector<std::unique_ptr<ViewController>> controllers_;
};

}  // namespace term

#endif  // TOPAZ_APP_TERM_APP_H_
