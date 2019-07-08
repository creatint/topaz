// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/flutter_runner/accessibility_bridge.h"

#include <gtest/gtest.h>
#include <zircon/types.h>

#include <memory>

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "topaz/runtime/flutter_runner/accessibility_bridge_fakes.h"

namespace flutter_runner {

TEST(AccessibilityBridgeTest, DeletesChildrenTransitively) {
  // Test that when a node is deleted, so are its transitive children.
  auto fuchsia = std::make_shared<FakeFuchsia>();
  auto bridge = AccessibilityBridge(fuchsia);

  flutter::SemanticsNode node2;
  node2.id = 2;

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.childrenInTraversalOrder = {2};

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.childrenInTraversalOrder = {1};

  bridge.AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
  });

  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(1, fuchsia->UpdateCount());
  EXPECT_EQ(1, fuchsia->CommitCount());
  EXPECT_EQ(3U, fuchsia->LastUpdatedNodes().size());
  EXPECT_EQ(0U, fuchsia->LastDeletedNodeIds().size());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());

  // Remove the children
  node0.childrenInTraversalOrder.clear();
  bridge.AddSemanticsNodeUpdate({
      {0, node0},
  });
  EXPECT_EQ(1, fuchsia->DeleteCount());
  EXPECT_EQ(2, fuchsia->UpdateCount());
  EXPECT_EQ(2, fuchsia->CommitCount());
  EXPECT_EQ(1U, fuchsia->LastUpdatedNodes().size());
  ASSERT_EQ(std::vector<uint32_t>({1, 2}), fuchsia->LastDeletedNodeIds());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());
}

TEST(AccessibilityBridgeTest, TruncatesLargeLabel) {
  // Test that labels which are too long are truncated.
  auto fuchsia = std::make_shared<FakeFuchsia>();
  auto bridge = AccessibilityBridge(fuchsia);

  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;

  flutter::SemanticsNode bad_node;
  bad_node.id = 2;
  bad_node.label = std::string(AccessibilityBridge::kMaxStringLength + 1, '2');

  node0.childrenInTraversalOrder = {1, 2};

  bridge.AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, bad_node},
  });

  // Nothing to delete, but we should have broken
  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(1, fuchsia->UpdateCount());
  EXPECT_EQ(1, fuchsia->CommitCount());
  EXPECT_EQ(3U, fuchsia->LastUpdatedNodes().size());
  auto trimmed_node = std::find_if(
      fuchsia->LastUpdatedNodes().begin(), fuchsia->LastUpdatedNodes().end(),
      [id = static_cast<uint32_t>(bad_node.id)](
          fuchsia::accessibility::semantics::Node const& node) {
        return node.node_id() == id;
      });
  ASSERT_NE(trimmed_node, fuchsia->LastUpdatedNodes().end());
  ASSERT_TRUE(trimmed_node->has_attributes());
  EXPECT_EQ(trimmed_node->attributes().label(),
            std::string(AccessibilityBridge::kMaxStringLength, '2'));
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());
}

TEST(AccessibilityBridgeTest, SplitsLargeUpdates) {
  // Test that labels which are too long are truncated.
  auto fuchsia = std::make_shared<FakeFuchsia>();
  auto bridge = AccessibilityBridge(fuchsia);

  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.label = std::string(AccessibilityBridge::kMaxStringLength, '1');

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.label = "2";

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.label = "3";

  flutter::SemanticsNode node4;
  node4.id = 4;
  node4.label = std::string(AccessibilityBridge::kMaxStringLength, '4');

  node0.childrenInTraversalOrder = {1, 2};
  node1.childrenInTraversalOrder = {3, 4};

  bridge.AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
      {3, node3},
      {4, node4},
  });

  // Nothing to delete, but we should have broken into groups (4, 3, 2), (1, 0)
  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(2, fuchsia->UpdateCount());
  EXPECT_EQ(1, fuchsia->CommitCount());
  EXPECT_EQ(2U, fuchsia->LastUpdatedNodes().size());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());
}

TEST(AccessibilityBridgeTest, HandlesCycles) {
  // Test that cycles don't cause fatal error.
  auto fuchsia = std::make_shared<FakeFuchsia>();
  auto bridge = AccessibilityBridge(fuchsia);

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.childrenInTraversalOrder.push_back(0);
  bridge.AddSemanticsNodeUpdate({
      {0, node0},
  });

  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(1, fuchsia->UpdateCount());
  EXPECT_EQ(1, fuchsia->CommitCount());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());

  node0.childrenInTraversalOrder = {0, 1};
  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.childrenInTraversalOrder = {0};
  bridge.AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
  });
  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(2, fuchsia->UpdateCount());
  EXPECT_EQ(2, fuchsia->CommitCount());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());
}

TEST(AccessibilityBridgeTest, BatchesLargeMessages) {
  // Tests that messages get batched appropriately.
  auto fuchsia = std::make_shared<FakeFuchsia>();
  auto bridge = AccessibilityBridge(fuchsia);

  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNodeUpdates update;

  const int32_t child_nodes = 650;
  const int32_t leaf_nodes = 100;
  for (int32_t i = 1; i < child_nodes + 1; i++) {
    flutter::SemanticsNode node;
    node.id = i;
    node0.childrenInTraversalOrder.push_back(i);
    for (int32_t j = 0; j < leaf_nodes; j++) {
      flutter::SemanticsNode leaf_node;
      int id = (i * child_nodes) + ((j + 1) * leaf_nodes);
      leaf_node.id = id;
      leaf_node.label = "A relatively simple label";
      node.childrenInTraversalOrder.push_back(id);
      update.insert(std::make_pair(id, std::move(leaf_node)));
    }
    update.insert(std::make_pair(i, std::move(node)));
  }

  update.insert(std::make_pair(0, std::move(node0)));
  bridge.AddSemanticsNodeUpdate(update);

  EXPECT_EQ(0, fuchsia->DeleteCount());
  EXPECT_EQ(34, fuchsia->UpdateCount());
  EXPECT_EQ(1, fuchsia->CommitCount());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());

  // Remove the children
  node0.childrenInTraversalOrder.clear();
  bridge.AddSemanticsNodeUpdate({
      {0, node0},
  });
  EXPECT_EQ(2, fuchsia->DeleteCount());
  EXPECT_EQ(35, fuchsia->UpdateCount());
  EXPECT_EQ(2, fuchsia->CommitCount());
  EXPECT_FALSE(fuchsia->DeleteOverflowed());
  EXPECT_FALSE(fuchsia->UpdateOverflowed());
}
}  // namespace flutter_runner
