// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/tests/web_runner_tests/chromium_context.h"

#include <gtest/gtest.h>
#include <lib/fdio/directory.h>
#include <src/lib/fxl/logging.h>
#include <zircon/status.h>

ChromiumContext::ChromiumContext(sys::ComponentContext* component_context) {
  auto chromium_context_provider =
      component_context->svc()->Connect<chromium::web::ContextProvider>();
  chromium_context_provider.set_error_handler([](zx_status_t status) {
    FAIL() << "chromium_context_provider: " << zx_status_get_string(status);
  });

  auto incoming_service_clone = component_context->svc()->CloneChannel();
  FXL_CHECK(incoming_service_clone.is_valid());
  chromium::web::CreateContextParams params;
  params.set_service_directory(std::move(incoming_service_clone));

  chromium_context_provider->Create(std::move(params),
                                    chromium_context_.NewRequest());
  chromium_context_.set_error_handler([](zx_status_t status) {
    FAIL() << "chromium_context_: " << zx_status_get_string(status);
  });

  chromium_context_->CreateFrame(chromium_frame_.NewRequest());
  chromium_frame_.set_error_handler([](zx_status_t status) {
    FAIL() << "chromium_frame_: " << zx_status_get_string(status);
  });
}

void ChromiumContext::Navigate(const std::string& url) {
  // Create a navigation controller here to avoid a potential race condition if
  // a test operates on the frame. If we were to instead create the navigation
  // controller in the constructor, it would be easy to make invocations on both
  // the frame and navigation interface pointers where ordering would not be
  // guaranteed.
  chromium::web::NavigationControllerPtr navigation;
  chromium_frame_->GetNavigationController(navigation.NewRequest());
  navigation->LoadUrl(url, chromium::web::LoadUrlParams());
}
