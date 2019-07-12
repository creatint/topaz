// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/flutter_runner/fuchsia_accessibility.h"

#include <gtest/gtest.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/gtest/real_loop_fixture.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>

#include "flutter_runner_fakes.h"

namespace flutter_runner_test::flutter_runner_a11y_test {
using FuchsiaAccessibilityTests = gtest::RealLoopFixture;

TEST_F(FuchsiaAccessibilityTests, RegisterViewRef) {
  MockSemanticsManager semantics_manager;
  sys::testing::ServiceDirectoryProvider services_provider(dispatcher());
  services_provider.AddService(semantics_manager.GetHandler(dispatcher()),
                               SemanticsManager::Name_);
  zx::eventpair a, b;
  zx::eventpair::create(/* flags */ 0u, &a, &b);
  auto view_ref = fuchsia::ui::views::ViewRef({
      .reference = std::move(a),
  });
  auto fuchsia_accessibility = flutter_runner::FuchsiaAccessibility::Create(
      services_provider.service_directory(), std::move(view_ref));

  RunLoopUntilIdle();
  EXPECT_TRUE(semantics_manager.RegisterViewCalled());
}

}  // namespace flutter_runner_test::flutter_runner_a11y_test
