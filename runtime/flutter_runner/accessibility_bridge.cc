// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/flutter_runner/accessibility_bridge.h"

#include <zircon/types.h>

#include <deque>

#include "flutter/fml/logging.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "topaz/runtime/flutter_runner/fuchsia_accessibility.h"

namespace flutter_runner {
AccessibilityBridge::AccessibilityBridge(
    std::shared_ptr<FuchsiaAccessibility> fuchsia_a11y)
    : fuchsia_a11y_(std::move(fuchsia_a11y)) {}

bool AccessibilityBridge::GetSemanticsEnabled() const {
  return semantics_enabled_;
}

void AccessibilityBridge::SetSemanticsEnabled(bool enabled) {
  semantics_enabled_ = enabled;
  if (!enabled) {
    nodes_.clear();
  }
}

fuchsia::ui::gfx::BoundingBox AccessibilityBridge::GetNodeLocation(
    const flutter::SemanticsNode& node) const {
  fuchsia::ui::gfx::BoundingBox box;
  box.min.x = node.rect.fLeft;
  box.min.y = node.rect.fTop;
  box.min.z = static_cast<float>(node.elevation);
  box.max.x = node.rect.fRight;
  box.max.y = node.rect.fBottom;
  box.max.z = static_cast<float>(node.thickness);
  return box;
}

fuchsia::ui::gfx::mat4 AccessibilityBridge::GetNodeTransform(
    const flutter::SemanticsNode& node) const {
  fuchsia::ui::gfx::mat4 value;
  float* m = value.matrix.data();
  node.transform.asColMajorf(m);
  return value;
}

fuchsia::accessibility::semantics::Attributes
AccessibilityBridge::GetNodeAttributes(const flutter::SemanticsNode& node,
                                       size_t* added_size) const {
  fuchsia::accessibility::semantics::Attributes attributes;
  // TODO(MI4-2531): Don't truncate.
  if (node.label.size() > kMaxStringLength) {
    attributes.set_label(node.label.substr(0, kMaxStringLength));
    *added_size += kMaxStringLength;
  } else {
    attributes.set_label(node.label);
    *added_size += node.label.size();
  }

  return attributes;
}

fuchsia::accessibility::semantics::States AccessibilityBridge::GetNodeStates(
    const flutter::SemanticsNode& node) const {
  fuchsia::accessibility::semantics::States states;
  if (node.HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    states.set_checked(node.HasFlag(flutter::SemanticsFlags::kIsChecked));
  }
  return states;
}

std::unordered_set<int32_t> AccessibilityBridge::GetDescendants(
    int32_t node_id) const {
  std::unordered_set<int32_t> descendents;
  std::deque<int32_t> to_process = {node_id};
  while (!to_process.empty()) {
    int32_t id = to_process.front();
    to_process.pop_front();
    descendents.emplace(id);

    auto it = nodes_.find(id);
    if (it != nodes_.end()) {
      auto const& children = it->second;
      for (const auto& child : children) {
        if (descendents.find(child) == descendents.end()) {
          to_process.push_back(child);
        } else {
          // This indicates either a cycle or a child with multiple parents.
          // Flutter should never let this happen, but the engine API does not
          // explicitly forbid it right now.
          FML_LOG(ERROR) << "Semantics Node " << child
                         << " has already been listed as a child of another "
                            "node, ignoring for parent "
                         << id << ".";
        }
      }
    }
  }
  return descendents;
}

// The only known usage of a negative number for a node ID is in the embedder
// API as a sentinel value, which is not expected here. No valid producer of
// nodes should give us a negative ID.
static uint32_t FlutterIdToFuchsiaId(int32_t flutter_node_id) {
  FML_DCHECK(flutter_node_id >= 0)
      << "Unexpectedly recieved a negative semantics node ID.";
  return static_cast<uint32_t>(flutter_node_id);
}

void AccessibilityBridge::PruneUnreachableNodes() {
  const auto& reachable_nodes = GetDescendants(kRootNodeId);
  std::vector<uint32_t> nodes_to_remove;
  auto iter = nodes_.begin();
  while (iter != nodes_.end()) {
    int32_t id = iter->first;
    if (reachable_nodes.find(id) == reachable_nodes.end()) {
      // TODO(MI4-2531): This shouldn't be strictly necessary at this level.
      if (sizeof(nodes_to_remove) + (nodes_to_remove.size() * kNodeIdSize) >=
          ZX_CHANNEL_MAX_MSG_BYTES / 2) {
        fuchsia_a11y_->DeleteSemanticNodes(std::move(nodes_to_remove));
        nodes_to_remove.clear();
      }
      nodes_to_remove.push_back(FlutterIdToFuchsiaId(id));
      iter = nodes_.erase(iter);
    } else {
      iter++;
    }
  }
  if (!nodes_to_remove.empty()) {
    fuchsia_a11y_->DeleteSemanticNodes(std::move(nodes_to_remove));
  }
}

// TODO(FIDL-718) - remove this, handle the error instead in something like
// set_error_handler.
static void PrintNodeSizeError(uint32_t node_id) {
  FML_LOG(ERROR) << "Semantics node with ID " << node_id
                 << " exceeded the maximum FIDL message size and may not "
                    "be delivered to the accessibility manager service.";
}

void AccessibilityBridge::AddSemanticsNodeUpdate(
    const flutter::SemanticsNodeUpdates update) {
  if (update.empty()) {
    return;
  }
  FML_DCHECK(nodes_.find(kRootNodeId) != nodes_.end() ||
             update.find(kRootNodeId) != update.end())
      << "AccessibilityBridge received an update with out ever getting a root "
         "node.";

  std::vector<fuchsia::accessibility::semantics::Node> nodes;
  size_t current_size = 0;

  // TODO(MI4-2498): Actions, Roles, hit test children, additional
  // flags/states/attr

  // TODO(MI4-1478): Support for partial updates for nodes > 64kb
  // e.g. if a node has a long label or more than 64k children.
  for (const auto& value : update) {
    size_t this_node_size = sizeof(fuchsia::accessibility::semantics::Node);
    const auto& flutter_node = value.second;
    nodes_[flutter_node.id] =
        std::vector<int32_t>(flutter_node.childrenInTraversalOrder);
    fuchsia::accessibility::semantics::Node fuchsia_node;
    std::vector<uint32_t> child_ids;
    for (int32_t flutter_child_id : flutter_node.childrenInTraversalOrder) {
      child_ids.push_back(FlutterIdToFuchsiaId(flutter_child_id));
    }
    fuchsia_node.set_node_id(flutter_node.id)
        .set_location(GetNodeLocation(flutter_node))
        .set_transform(GetNodeTransform(flutter_node))
        .set_attributes(GetNodeAttributes(flutter_node, &this_node_size))
        .set_states(GetNodeStates(flutter_node))
        .set_child_ids(child_ids);
    this_node_size +=
        kNodeIdSize * flutter_node.childrenInTraversalOrder.size();

    // TODO(MI4-2531, FIDL-718): Remove this
    // This is defensive. If, despite our best efforts, we ended up with a node
    // that is larger than the max fidl size, we send no updates.
    if (this_node_size >= ZX_CHANNEL_MAX_MSG_BYTES) {
      PrintNodeSizeError(flutter_node.id);
      return;
    }

    current_size += this_node_size;

    // If we would exceed the max FIDL message size by appending this node,
    // we should delete/update/commit now.
    if (current_size >= ZX_CHANNEL_MAX_MSG_BYTES) {
      fuchsia_a11y_->UpdateSemanticNodes(std::move(nodes));
      nodes.clear();
      current_size = this_node_size;
    }
    nodes.push_back(std::move(fuchsia_node));
  }

  if (current_size > ZX_CHANNEL_MAX_MSG_BYTES) {
    PrintNodeSizeError(nodes.back().node_id());
  }

  PruneUnreachableNodes();

  fuchsia_a11y_->UpdateSemanticNodes(std::move(nodes));
  fuchsia_a11y_->Commit();
}

}  // namespace flutter_runner
