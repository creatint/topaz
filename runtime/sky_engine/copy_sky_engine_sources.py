#!/usr/bin/env python3
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import shutil
import sys


def main():
    parser = argparse.ArgumentParser(
        description='List the sources for the "sky_engine" dart library.')
    parser.add_argument(
        '--sky_engine_framework',
        help='Path to the "sky_engine" directory in the framework.',
        required=True)
    parser.add_argument(
        '--out_dir',
        help='Path that the "sky_engine" sources should be copied to.',
        required=True)
    parser.add_argument(
        '--dry_run', dest='dry_run', action='store_true', default=False)
    args = parser.parse_args()

    source_dir = args.sky_engine_framework
    assert os.path.exists(source_dir)
    dry_run = args.dry_run

    out_dir = args.out_dir
    out_dir = os.path.join(out_dir, 'dart-pkg', 'sky_engine')
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    else:
        # Clean the outdir if it already exists.
        if not dry_run:
            shutil.rmtree(out_dir)

    sky_engine_sources = [
        os.path.join(dir_path, filename)
        for dir_path, dir_name, filenames in os.walk(source_dir)
        for filename in filenames
    ]

    out_paths = []
    for source in sky_engine_sources:
        src_rel_path = os.path.relpath(source, source_dir)
        if not dry_run:
            abs_out_path = os.path.normpath(os.path.join(out_dir, src_rel_path))
            dir_name = os.path.dirname(abs_out_path)
            if not os.path.exists(dir_name):
                os.makedirs(dir_name)
            shutil.copy2(source, abs_out_path)
        else:
            rel_out_path = os.path.normpath(
                os.path.join('dart-pkg', 'sky_engine', src_rel_path))
            # dry-run requires relative paths
            out_paths.append(rel_out_path)

    if dry_run:
        res = {}
        res['sources'] = sky_engine_sources
        res['outputs'] = out_paths
        print(json.dumps(res))
    return 0


if __name__ == '__main__':
    sys.exit(main())
