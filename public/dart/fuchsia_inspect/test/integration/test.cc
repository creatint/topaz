// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fuchsia/io/cpp/fidl.h>
#include <lib/async/default.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/fd.h>
#include <lib/fdio/fdio.h>
#include <lib/inspect_deprecated/reader.h>
#include <lib/inspect_deprecated/testing/inspect.h>

#include "gmock/gmock.h"
#include "lib/inspect_deprecated/deprecated/expose.h"
#include "lib/sys/cpp/testing/test_with_environment.h"
#include "src/lib/files/glob.h"
#include "src/lib/fxl/strings/substitute.h"

namespace {

using ::fxl::Substitute;
using sys::testing::EnclosingEnvironment;
using ::testing::UnorderedElementsAre;
using namespace inspect_deprecated::testing;

constexpr char kTestComponent[] =
    "fuchsia-pkg://fuchsia.com/dart_inspect_vmo_test_writer#meta/"
    "dart_inspect_vmo_test_writer.cmx";
constexpr char kTestProcessName[] = "dart_inspect_vmo_test_writer.cmx";
constexpr char kTestInspectFileName1[] = "test";
constexpr char kTestInspectFileName2[] = "test_2";
const std::string digitsOfPi("31415");
const std::string digitsOfE("27182");
const std::string digitsOfSqrt2("14142");
const std::string digitsOfQuake3("5f375");
constexpr int indexOfDigitOfPi = 0;
constexpr int indexOfDigitOfE = 1;
constexpr int indexOfDigitOfSqrt2 = 2;
constexpr int indexOfDigitOfQuake3 = 3;

class InspectTest : public sys::testing::TestWithEnvironment {
 protected:
  InspectTest() {
    fuchsia::sys::LaunchInfo launch_info;
    launch_info.url = kTestComponent;

    environment_ = CreateNewEnclosingEnvironment("test", CreateServices());
    environment_->CreateComponent(std::move(launch_info),
                                  controller_.NewRequest());
    bool ready = false;
    controller_.events().OnDirectoryReady = [&ready] { ready = true; };
    RunLoopWithTimeoutOrUntil([&ready] { return ready; }, zx::sec(100));
    if (!ready) {
      printf("The output directory is not ready\n");
    }
  }
  ~InspectTest() { CheckShutdown(); }

  void CheckShutdown() {
    controller_->Kill();
    bool done = false;
    controller_.events().OnTerminated =
        [&done](int64_t code, fuchsia::sys::TerminationReason reason) {
          ASSERT_EQ(fuchsia::sys::TerminationReason::EXITED, reason);
          done = true;
        };
    ASSERT_TRUE(
        RunLoopWithTimeoutOrUntil([&done] { return done; }, zx::sec(100)));
  }

  // Open the root object connection on the given sync pointer.
  // Returns ZX_OK on success.
  fit::result<fuchsia::io::FileSyncPtr, zx_status_t> OpenInspectVmoFile(
      const std::string& file_name) {
    files::Glob glob(
        Substitute("/hub/r/test/*/c/*/*/c/$0/*/out/debug/$1.inspect",
                   kTestProcessName, file_name));
    if (glob.size() == 0) {
      printf("Size == 0\n");
      return fit::error(ZX_ERR_NOT_FOUND);
    }

    fuchsia::io::FileSyncPtr file;
    auto status = fdio_open(std::string(*glob.begin()).c_str(),
                            fuchsia::io::OPEN_RIGHT_READABLE,
                            file.NewRequest().TakeChannel().release());
    if (status != ZX_OK) {
      printf("Status bad %d\n", status);
      return fit::error(status);
    }

    EXPECT_TRUE(file.is_bound());

    return fit::ok(std::move(file));
  }

  fit::result<zx::vmo, zx_status_t> DescribeInspectVmoFile(
      const fuchsia::io::FileSyncPtr& file) {
    fuchsia::io::NodeInfo info;
    auto status = file->Describe(&info);
    if (status != ZX_OK) {
      printf("get failed\n");
      return fit::error(status);
    }

    if (!info.is_vmofile()) {
      printf("not a vmofile");
      return fit::error(ZX_ERR_NOT_FOUND);
    }

    return fit::ok(std::move(info.vmofile().vmo));
  }

 private:
  std::unique_ptr<EnclosingEnvironment> environment_;
  fuchsia::sys::ComponentControllerPtr controller_;
};

TEST_F(InspectTest, ReadHierarchy) {
  auto open_file_result(InspectTest::OpenInspectVmoFile("root"));
  ASSERT_TRUE(open_file_result.is_ok());
  fuchsia::io::FileSyncPtr file(open_file_result.take_value());
  auto describe_file_result = InspectTest::DescribeInspectVmoFile(file);
  ASSERT_TRUE(describe_file_result.is_ok());
  zx::vmo vmo(describe_file_result.take_value());
  auto read_file_result = inspect_deprecated::ReadFromVmo(std::move(vmo));
  ASSERT_TRUE(read_file_result.is_ok());
  inspect_deprecated::ObjectHierarchy hierarchy = read_file_result.take_value();

  EXPECT_THAT(
      hierarchy,
      AllOf(
          NodeMatches(NameMatches("root")),
          ChildrenMatch(UnorderedElementsAre(
              AllOf(NodeMatches(AllOf(
                        NameMatches("t1"),
                        PropertyList(UnorderedElementsAre(
                            StringPropertyIs("version", "1.0"),
                            ByteVectorPropertyIs(
                                "frame", std::vector<uint8_t>({0, 0, 0})))),
                        MetricList(
                            UnorderedElementsAre(IntMetricIs("value", -10))))),
                    ChildrenMatch(UnorderedElementsAre(
                        NodeMatches(AllOf(NameMatches("item-0x0"),
                                          MetricList(UnorderedElementsAre(
                                              IntMetricIs("value", 10))))),
                        NodeMatches(AllOf(NameMatches("item-0x1"),
                                          MetricList(UnorderedElementsAre(
                                              IntMetricIs("value", 100)))))

                            ))),
              AllOf(
                  NodeMatches(AllOf(
                      NameMatches("t2"),
                      PropertyList(UnorderedElementsAre(
                          StringPropertyIs("version", "1.0"),
                          ByteVectorPropertyIs(
                              "frame", std::vector<uint8_t>({0, 0, 0})))),
                      MetricList(
                          UnorderedElementsAre(IntMetricIs("value", -10))))),
                  ChildrenMatch(UnorderedElementsAre(NodeMatches(AllOf(
                      NameMatches("item-0x2"), MetricList(UnorderedElementsAre(
                                                   IntMetricIs("value", 4)))))))

                      )))));
}

TEST_F(InspectTest, DynamicGeneratesNewHierarchy) {
  auto open_file_result(OpenInspectVmoFile("digits_of_numbers"));
  ASSERT_TRUE(open_file_result.is_ok());
  fuchsia::io::FileSyncPtr file(open_file_result.take_value());

  auto expectInspectOnDemandVmoFile = [&](std::vector<const std::string>
                                              digits) {
    auto describe_file_result(DescribeInspectVmoFile(file));
    ASSERT_TRUE(describe_file_result.is_ok());
    zx::vmo vmo(describe_file_result.take_value());
    auto read_file_result = inspect_deprecated::ReadFromVmo(std::move(vmo));
    ASSERT_TRUE(read_file_result.is_ok());
    inspect_deprecated::ObjectHierarchy hierarchy =
        read_file_result.take_value();

    EXPECT_THAT(
        hierarchy,
        AllOf(
            NodeMatches(NameMatches("root")),
            ChildrenMatch(UnorderedElementsAre(
                NodeMatches(AllOf(  // child one
                    NameMatches("transcendental"),
                    PropertyList(UnorderedElementsAre(
                        StringPropertyIs("pi", digits[indexOfDigitOfPi]),
                        StringPropertyIs("e", digits[indexOfDigitOfE]))))),
                NodeMatches(AllOf(  // child two
                    NameMatches("nontranscendental"),
                    PropertyList(UnorderedElementsAre(
                        StringPropertyIs("sqrt2", digits[indexOfDigitOfSqrt2]),
                        StringPropertyIs(
                            "quake3",
                            digits
                                [indexOfDigitOfQuake3])))))))  // ChildrenMatch
            )                                                  // AllOf
    );                                                         // EXPECT_THAT
  };
  auto getDigitsOfConstants =
      [](const int digit) -> std::vector<const std::string> {
    return {digitsOfPi.substr(digit, 1), digitsOfE.substr(digit, 1),
            digitsOfSqrt2.substr(digit, 1), digitsOfQuake3.substr(digit, 1)};
  };

  expectInspectOnDemandVmoFile(getDigitsOfConstants(0));
  expectInspectOnDemandVmoFile(getDigitsOfConstants(1));
  expectInspectOnDemandVmoFile(getDigitsOfConstants(2));
  expectInspectOnDemandVmoFile(getDigitsOfConstants(3));
}
TEST_F(InspectTest, NamedInspectVisible) {
  files::Glob glob1(
      Substitute("/hub/r/test/*/c/*/*/c/$0/*/out/debug/$1.inspect",
                 kTestProcessName, kTestInspectFileName1));
  files::Glob glob2(
      Substitute("/hub/r/test/*/c/*/*/c/$0/*/out/debug/$1.inspect",
                 kTestProcessName, kTestInspectFileName2));
  EXPECT_TRUE(glob1.size() > 0);
  EXPECT_TRUE(glob2.size() > 0);
}
}  // namespace
