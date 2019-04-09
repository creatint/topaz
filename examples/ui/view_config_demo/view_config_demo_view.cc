// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_config_demo_view.h"

#include "src/lib/fxl/logging.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkPaint.h"

namespace examples {

using fuchsia::ui::views::ViewConfig;

namespace {
constexpr SkScalar kTextSize = 40;
}  // namespace

ViewConfigDemoView::ViewConfigDemoView(scenic::ViewContext view_context)
    : SkiaView(std::move(view_context), "ViewConfig Demo"),
      font_loader_(
          startup_context()
              ->ConnectToEnvironmentService<fuchsia::fonts::Provider>()) {
  // Asynchronously load the font we need in order to render text.
  fuchsia::fonts::Request font_request{
      .family = "Roboto",
  };
  font_loader_.LoadFont(std::move(font_request),
                        [this](sk_sp<SkTypeface> typeface) {
                          if (!typeface) {
                            FXL_LOG(ERROR) << "Failed to load font";
                            return;
                          }
                          FXL_LOG(INFO) << "Loaded font";
                          typeface_ = std::move(typeface);
                          InvalidateScene();
                        });
}

void ViewConfigDemoView::OnPropertiesChanged(
    fuchsia::ui::gfx::ViewProperties old_properties) {
  InvalidateScene();
}

void ViewConfigDemoView::OnSceneInvalidated(
    fuchsia::images::PresentationInfo presentation_info) {
  if (!typeface_) {
    FXL_LOG(ERROR) << "No typeface loaded";
    return;
  }

  SkCanvas* canvas = AcquireCanvas();
  if (!canvas) {
    FXL_LOG(ERROR) << "Couldn't acquire canvas";
    return;
  }

  Draw(canvas);
  ReleaseAndSwapCanvas();
  // If we want to animate, add a call to InvalidateScene() here.
}

// Return the first locale ID in the given view config, or "[none]" if the
// config is invalid.
const std::string GetFirstLocale(const ViewConfig& view_config) {
  // TODO(I18N-7): Restore after converting fuchsia.intl.Profile to FIDL table.

//  if (view_config.has_intl_profile() &&
//      !view_config.intl_profile().locales().empty()) {
//    return view_config.intl_profile().locales()[0].id;
//  }
  return "[none]";
}

void ViewConfigDemoView::OnConfigChanged(
    const fuchsia::ui::views::ViewConfig& old_config) {
  FXL_LOG(INFO) << "OnConfigChanged: locale was " << GetFirstLocale(old_config)
                << "; now \"" << GetFirstLocale(view_config2()) << "\".";
  InvalidateScene();
}

void ViewConfigDemoView::Draw(SkCanvas* canvas) {
  canvas->clear(SkColorSetRGB(180, 200, 200));

  SkPaint text_paint;
  text_paint.setColor(SK_ColorBLACK);
  text_paint.setAntiAlias(true);
  text_paint.setStyle(SkPaint::kFill_Style);

  SkFont font;
  font.setSize(kTextSize);
  font.setTypeface(typeface_);

  std::string text = std::string("Locale: " + GetFirstLocale(view_config2()));

  SkRect text_bounds{};
  font.measureText(text.c_str(), text.size(), SkTextEncoding::kUTF8,
                   &text_bounds);

  // Draw the text centered on the screen.
  canvas->drawSimpleText(text.c_str(), text.size(), SkTextEncoding::kUTF8,
                         (logical_size().x - text_bounds.width()) / 2,
                         (logical_size().y - text_bounds.height()) / 2, font,
                         text_paint);
}

}  // namespace examples