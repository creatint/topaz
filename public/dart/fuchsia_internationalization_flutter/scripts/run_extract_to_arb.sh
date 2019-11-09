#!/bin/bash
# Copyright 2019 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -x

$FUCHSIA_DIR/third_party/dart-pkg/git/flutter/bin/flutter \
  packages pub get intl_translation:extract_to_arb

$FUCHSIA_DIR/third_party/dart-pkg/git/flutter/bin/flutter \
  packages pub run intl_translation:extract_to_arb \
  --output-dir=resources lib/*strings.dart

rm .packages pubspec.lock
rm -fr .dart_tool
