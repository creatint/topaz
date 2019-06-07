// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/app/term/pty_client.h"

#include <zircon/status.h>

namespace term {

PtyClient::PtyClient(std::vector<std::string> command,
                     CreatePtyCallback callback) {
  zx_status_t status = pty_.Run(
      std::move(command),
      [this](const void* bytes, size_t num_bytes) {
        if (num_bytes > 0 && event_sender_) {
          const uint8_t* buffer = (uint8_t*)bytes;
          std::vector<uint8_t> data(buffer, buffer + num_bytes);
          event_sender_->OnRead(std::move(data));
        }
      },
      [this] {
        if (event_sender_) {
          event_sender_->OnClose();
        }
      });
  if (status != ZX_OK) {
    FXL_LOG(ERROR) << "Error starting command: " << status << " ("
                   << zx_status_get_string(status) << ")";
  } else {
    // Initialize window size to default to 80x25.
    pty_.SetWindowSize(80, 25);
  }
  // Return the status.
  callback(status);
}

void PtyClient::Write(std::vector<uint8_t> data) {
  pty_.Write(data.data(), data.size());
}

void PtyClient::SetWindowSize(uint32_t columns, uint32_t rows) {
  pty_.SetWindowSize(columns, rows);
}

}  // namespace term
