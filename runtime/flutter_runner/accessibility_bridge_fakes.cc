// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/flutter_runner/accessibility_bridge_fakes.h"

#include "topaz/runtime/flutter_runner/accessibility_bridge.h"
#include "topaz/runtime/flutter_runner/fuchsia_accessibility.h"

namespace flutter_runner {

void FakeFuchsia::UpdateSemanticNodes(
    std::vector<fuchsia::accessibility::semantics::Node> nodes) {
  update_count_++;
  if (!update_overflowed_) {
    size_t size = 0;
    for (const auto& node : nodes) {
      size += sizeof(node);
      size += sizeof(node.attributes().label().size());
    }
    update_overflowed_ = size > ZX_CHANNEL_MAX_MSG_BYTES;
  }
  last_updated_nodes_ = std::move(nodes);
}

void FakeFuchsia::DeleteSemanticNodes(std::vector<uint32_t> node_ids) {
  delete_count_++;
  if (!delete_overflowed_) {
    size_t size =
        sizeof(node_ids) + (node_ids.size() * AccessibilityBridge::kNodeIdSize);
    delete_overflowed_ = size > ZX_CHANNEL_MAX_MSG_BYTES;
  }
  last_deleted_node_ids_ = std::move(node_ids);
}

const std::vector<uint32_t>& FakeFuchsia::LastDeletedNodeIds() const {
  return last_deleted_node_ids_;
}

const std::vector<fuchsia::accessibility::semantics::Node>&
FakeFuchsia::LastUpdatedNodes() const {
  return last_updated_nodes_;
}

void FakeFuchsia::Commit() { commit_count_++; }

}  // namespace flutter_runner
