// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_APP_TERM_PTY_CLIENT_H_
#define TOPAZ_APP_TERM_PTY_CLIENT_H_

#include <fuchsia/term/cpp/fidl.h>

#include "topaz/app/term/pty_server.h"

namespace term {

using CreatePtyCallback = fit::function<void(int32_t)>;

class PtyClient : public fuchsia::term::Pty {
 public:
  explicit PtyClient(std::vector<std::string> command,
                     CreatePtyCallback callback);
  ~PtyClient() = default;

  // |fuchsia::term::Pty|
  void Write(::std::vector<uint8_t> data) override;
  void SetWindowSize(uint32_t columns, uint32_t rows) override;

  void SetEventSender(fuchsia::term::Pty_EventSender& event_sender) {
    event_sender_ = &event_sender;
  }

 private:
  PtyClient(const PtyClient&) = delete;
  PtyClient& operator=(const PtyClient&) = delete;

  PTYServer pty_;
  fuchsia::term::Pty_EventSender* event_sender_ = nullptr;
};

}  // namespace term

#endif  // TOPAZ_APP_TERM_PTY_CLIENT_H_
