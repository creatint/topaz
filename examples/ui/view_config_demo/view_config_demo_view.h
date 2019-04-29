// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_EXAMPLES_UI_VIEW_CONFIG_DEMO_VIEW_CONFIG_DEMO_VIEW_H_
#define TOPAZ_EXAMPLES_UI_VIEW_CONFIG_DEMO_VIEW_CONFIG_DEMO_VIEW_H_

#include "examples/ui/lib/skia_font_loader.h"
#include "examples/ui/lib/skia_view.h"
#include "src/lib/fxl/logging.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace examples {

// A simple implementation of |BaseView| and |SkiaView|.
//
// Uses Skia to display its current locale ID as text in the middle of the view.
class ViewConfigDemoView : public scenic::SkiaView {
 public:
  ViewConfigDemoView(scenic::ViewContext view_context);

 private:
  void OnPropertiesChanged(
      fuchsia::ui::gfx::ViewProperties old_properties) override;

  // |scenic::BaseView|
  void OnSceneInvalidated(
      fuchsia::images::PresentationInfo presentation_info) override;

  // |scenic::BaseView|
  void OnConfigChanged(
      const fuchsia::ui::views::ViewConfig& old_config) override;

  // Draw a solid background and some centered text.
  void Draw(SkCanvas* canvas);

  scenic::SkiaFontLoader font_loader_;
  sk_sp<SkTypeface> typeface_;
};

}  // namespace examples

#endif  // TOPAZ_EXAMPLES_UI_VIEW_CONFIG_DEMO_VIEW_CONFIG_DEMO_VIEW_H_
