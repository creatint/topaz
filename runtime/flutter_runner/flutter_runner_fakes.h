// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_

#include "fuchsia/accessibility/cpp/fidl.h"
#include "fuchsia/accessibility/semantics/cpp/fidl.h"

namespace flutter_runner_test {
using fuchsia::accessibility::semantics::SemanticsManager;
using AccessibilitySettingsManager = fuchsia::accessibility::SettingsManager;
using AccessibilitySettingsWatcher = fuchsia::accessibility::SettingsWatcher;
using AccessibilitySettingsProvider = fuchsia::accessibility::SettingsProvider;

class MockSemanticsManager : public SemanticsManager {
 public:
  MockSemanticsManager() = default;
  ~MockSemanticsManager() = default;

  // |fuchsia::accessibility::semantics::SemanticsManager|:
  void RegisterView(
      fuchsia::ui::views::ViewRef view_ref,
      fidl::InterfaceHandle<
          fuchsia::accessibility::semantics::SemanticActionListener>
          handle,
      fidl::InterfaceRequest<fuchsia::accessibility::semantics::SemanticTree>
          semantic_tree) override {
    has_view_ref_ = true;
  }

  fidl::InterfaceRequestHandler<SemanticsManager> GetHandler(
      async_dispatcher_t* dispatcher) {
    return bindings_.GetHandler(this, dispatcher);
  }

  bool RegisterViewCalled() { return has_view_ref_; }

 private:
  bool has_view_ref_ = false;
  fidl::BindingSet<SemanticsManager> bindings_;
};

class MockAccessibilitySettingsManager : public AccessibilitySettingsManager {
 public:
  MockAccessibilitySettingsManager(fuchsia::accessibility::Settings settings)
      : settings_(std::move(settings)) {}
  ~MockAccessibilitySettingsManager() = default;

  // |fuchsia::accessibility::SettingsManager|
  void RegisterSettingProvider(
      fidl::InterfaceRequest<AccessibilitySettingsProvider>
          settings_provider_request) override {}

  // |fuchsia::accessibility::SettingsManager|
  void Watch(
      fidl::InterfaceHandle<AccessibilitySettingsWatcher> watcher) override {
    watch_called_ = true;
    auto proxy = watcher.Bind();
    EXPECT_TRUE(proxy);
    fuchsia::accessibility::Settings settings = fidl::Clone(settings_);
    proxy->OnSettingsChange(std::move(settings));
  }

  fidl::InterfaceRequestHandler<AccessibilitySettingsManager> GetHandler(
      async_dispatcher_t* dispatcher) {
    return bindings_.GetHandler(this, dispatcher);
  }

  bool WatchCalled() { return watch_called_; }

 private:
  bool watch_called_ = false;
  fuchsia::accessibility::Settings settings_;
  fidl::BindingSet<AccessibilitySettingsManager> bindings_;
};

}  // namespace flutter_runner_test

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_PLATFORM_VIEW_FAKES_H_
