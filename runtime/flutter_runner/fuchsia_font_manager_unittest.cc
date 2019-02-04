// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fuchsia_font_manager.h"

#include <fuchsia/fonts/cpp/fidl.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/component/cpp/startup_context.h>
#include <lib/component/cpp/testing/test_with_environment.h>

#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace txt {

namespace {

// A codepoint guaranteed to be unknown in any font/family.
constexpr SkUnichar kUnknownUnicodeCharacter = 0xFFF0;

// Font family to use for tests.
constexpr char kTestFontFamily[] = "Roboto";

class FuchsiaFontManagerTest : public component::testing::TestWithEnvironment {
 public:
  FuchsiaFontManagerTest() : loop_(&kAsyncLoopConfigNoAttachToThread) {
    // Grab the current Environment. We'll need it to create a new set of
    // services on a background thread.
    auto context = component::StartupContext::CreateFromStartupInfo();
    fuchsia::sys::EnvironmentPtr parent_env;
    context->ConnectToEnvironmentService(parent_env.NewRequest());

    // Create a new set of services running on a newly started (background)
    // thread.
    loop_.StartThread();
    auto services = component::testing::EnvironmentServices::Create(
        parent_env, loop_.dispatcher());

    // Add the font provider service to the newly created set of services.
    fuchsia::sys::LaunchInfo launch_info{
        "fuchsia-pkg://fuchsia.com/fonts#meta/fonts.cmx"};
    zx_status_t status = services->AddServiceWithLaunchInfo(
        std::move(launch_info), fuchsia::fonts::Provider::Name_);
    EXPECT_EQ(ZX_OK, status);

    // Create an enclosing environment wrapping the new set of services.
    environment_ = CreateNewEnclosingEnvironment("font_manager_tests",
                                                 std::move(services));
    EXPECT_TRUE(WaitForEnclosingEnvToStart(environment_.get()));

    // Connect to the font provider service through the enclosing environment
    // (so that it runs on the background thread), and then wrap it inside the
    // font manager we will be testing.
    fuchsia::fonts::ProviderSyncPtr provider_ptr;
    environment_->ConnectToService(provider_ptr.NewRequest());
    font_manager_ = sk_make_sp<FuchsiaFontManager>(std::move(provider_ptr));
  }

  void TearDown() override {
    // Make sure the background thread terminates before tearing down the
    // enclosing environment (otherwise we get a crash).
    loop_.Quit();
  }

 protected:
  async::Loop loop_;
  std::unique_ptr<component::testing::EnclosingEnvironment> environment_;
  sk_sp<SkFontMgr> font_manager_;
};

// Verify that a typeface is returned for a found character.
TEST_F(FuchsiaFontManagerTest, ValidResponseWhenCharacterFound) {
  sk_sp<SkTypeface> typeface(font_manager_->matchFamilyStyleCharacter(
      "", SkFontStyle(), nullptr, 0, '&'));
  EXPECT_TRUE(typeface.get() != nullptr);
}

// Verify that a codepoint that doesn't map to a character correctly returns
// an empty typeface.
TEST_F(FuchsiaFontManagerTest, EmptyResponseWhenCharacterNotFound) {
  sk_sp<SkTypeface> typeface(font_manager_->matchFamilyStyleCharacter(
      "", SkFontStyle(), nullptr, 0, kUnknownUnicodeCharacter));
  EXPECT_TRUE(typeface.get() == nullptr);
}

// Verify that SkTypeface objects are cached.
TEST_F(FuchsiaFontManagerTest, Caching) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));

  // Expect that the same SkTypeface is returned for both requests.
  EXPECT_EQ(typeface.get(), typeface2.get());

  // Request a different typeface and verify that a different SkTypeface is
  // returned.
  sk_sp<SkTypeface> typeface3(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle::Italic()));
  EXPECT_NE(typeface.get(), typeface3.get());
}

// Verify that SkTypeface can outlive the manager.
TEST_F(FuchsiaFontManagerTest, TypefaceOutlivesManager) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  font_manager_.reset();
  EXPECT_TRUE(typeface.get() != nullptr);
}

// Verify that we can query a font after releasing a previous instance.
TEST_F(FuchsiaFontManagerTest, ReleaseThenCreateAgain) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface != nullptr);
  typeface.reset();

  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface2 != nullptr);
}

// Verify that we get a new typeface instance after releasing a previous
// instance of the same typeface (i.e. the cache purges the released typeface).
TEST_F(FuchsiaFontManagerTest, ReleasedTypefaceIsPurged) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface != nullptr);
  typeface.reset();

  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface2 != nullptr);
  EXPECT_NE(typeface.get(), typeface2.get());
}

// Verify that unknown font families are handled correctly.
TEST_F(FuchsiaFontManagerTest, MatchUnknownFamily) {
  SkFontStyleSet* style_set = font_manager_->matchFamily("unknown");
  EXPECT_TRUE(style_set == nullptr || style_set->count() == 0);
}

// Verify that a style set is returned for a known family.
TEST_F(FuchsiaFontManagerTest, MatchKnownFamily) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  EXPECT_GT(style_set->count(), 0);
}

// Verify getting an SkFontStyle from a matched family.
TEST_F(FuchsiaFontManagerTest, FontFamilyGetStyle) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  SkFontStyle style;
  style_set->getStyle(0, &style, nullptr);
  EXPECT_EQ(style.weight(), 400);
  EXPECT_EQ(style.width(), 5);
  EXPECT_EQ(style.slant(), SkFontStyle::kUpright_Slant);
}

// Verify creating a typeface from a matched family.
TEST_F(FuchsiaFontManagerTest, FontFamilyCreateTypeface) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  SkTypeface* typeface = style_set->createTypeface(0);
  EXPECT_TRUE(typeface != nullptr);
  SkFontStyle style = typeface->fontStyle();
  EXPECT_EQ(style.weight(), 400);
  EXPECT_EQ(style.width(), 5);
  EXPECT_EQ(style.slant(), SkFontStyle::kUpright_Slant);
}

}  // namespace

}  // namespace txt
