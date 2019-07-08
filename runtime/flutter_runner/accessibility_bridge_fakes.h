// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_FAKES_H_
#define TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_FAKES_H_

#include "flutter/fml/macros.h"
#include "topaz/runtime/flutter_runner/fuchsia_accessibility.h"

namespace flutter_runner {

class FakeFuchsia : public FuchsiaAccessibility {
 public:
  FakeFuchsia() = default;

  // |FuchsiaAccessibility|
  void UpdateSemanticNodes(
      std::vector<fuchsia::accessibility::semantics::Node> nodes) override;
  // |FuchsiaAccessibility|
  void DeleteSemanticNodes(std::vector<uint32_t> node_ids) override;
  // |FuchsiaAccessibility|
  void Commit() override;

  const std::vector<uint32_t>& LastDeletedNodeIds() const;
  const std::vector<fuchsia::accessibility::semantics::Node>& LastUpdatedNodes()
      const;
  int UpdateCount() const { return update_count_; }
  int DeleteCount() const { return delete_count_; }
  int CommitCount() const { return commit_count_; }

  bool DeleteOverflowed() const { return delete_overflowed_; }
  bool UpdateOverflowed() const { return update_overflowed_; }

 private:
  std::vector<uint32_t> last_deleted_node_ids_;
  std::vector<fuchsia::accessibility::semantics::Node> last_updated_nodes_;
  int update_count_ = 0;
  int delete_count_ = 0;
  int commit_count_ = 0;
  bool delete_overflowed_ = false;
  bool update_overflowed_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(FakeFuchsia);
};

}  // namespace flutter_runner

#endif  // TOPAZ_RUNTIME_FLUTTER_RUNNER_ACCESSIBILITY_BRIDGE_FAKES_H_
