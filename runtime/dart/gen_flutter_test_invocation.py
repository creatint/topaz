#!/usr/bin/env python
# Copyright 2017 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import stat
import string
import sys


def main():
  parser = argparse.ArgumentParser(
      description='Generate a script that invokes the Dart tester')
  parser.add_argument('--out',
                      help='Path to the invocation file to generate',
                      required=True)
  parser.add_argument('--source-dir',
                      help='Path to test sources',
                      required=True)
  parser.add_argument('--sdk-root',
                      help='Path to the SDK platform files',
                      required=True)
  parser.add_argument('--tests',
                      help='Path to test-to-precompiled-kernel file list',
                      required=True)
  parser.add_argument('--dot-packages',
                      help='Path to the .packages file',
                      required=True)
  parser.add_argument('--test-runner',
                      help='Path to the test runner',
                      required=True)
  parser.add_argument('--flutter-shell',
                      help='Path to the Flutter shell',
                      required=True)
  parser.add_argument('--icudtl',
                      help='Path to the ICU data file',
                      required=True)
  args = parser.parse_args()

  test_file = args.out
  test_path = os.path.dirname(test_file)
  if not os.path.exists(test_path):
    os.makedirs(test_path)

  script_template = string.Template('''#!/bin/bash
# DO NOT EDIT
# This script is generated by:
#   //topaz/runtime/dart/gen_flutter_test_invocation.py
# See: //topaz/runtime/dart/flutter_test.gni

$test_runner \\
  --packages=$dot_packages \\
  --shell=$flutter_shell \\
  --test-directory=$source_dir \\
  --tests=$tests \\
  --sdk-root=$sdk_root \\
  --icudtl=$icudtl \\
  "$$@"
''')
  with open(test_file, 'w') as file:
      file.write(script_template.substitute(args.__dict__))
  permissions = (stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR |
                 stat.S_IRGRP | stat.S_IWGRP | stat.S_IXGRP |
                 stat.S_IROTH)
  os.chmod(test_file, permissions)


if __name__ == '__main__':
  sys.exit(main())