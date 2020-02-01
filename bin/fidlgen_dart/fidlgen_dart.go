// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path"
	"path/filepath"

	"fidl/compiler/backend/types"
	"fidlgen_dart/backend"
	"fidlgen_dart/backend/ir"
)

type flagsDef struct {
	jsonPath     *string
	outAsyncPath *string
	outTestPath  *string
	dartfmt      *string

	deprecatedOutputBase  *string
	deprecatedIncludeBase *string
}

var flags = flagsDef{
	jsonPath: flag.String("json", "",
		"path to the FIDL intermediate representation."),
	outAsyncPath: flag.String("output-async", "",
		"output path for the async bindings."),
	outTestPath: flag.String("output-test", "",
		"output path for the test bindings."),
	dartfmt: flag.String("dartfmt", "",
		"path to the dartfmt tool"),

	// TODO(pascallouis): Because invocation of the fidlgen_dart backend is
	// controlled in fuchsia.git, we must preserve backwards compatibility
	// with this setting as fidl_dart.gni gets updated, and rolls forward.
	deprecatedOutputBase: flag.String("output-base", "",
		"[deprecated] path to the output directory"),
	deprecatedIncludeBase: flag.String("include-base", "",
		"[deprecated] unused"),
}

// valid returns true if the parsed flags are valid.
func (f flagsDef) valid() bool {
	return *f.jsonPath != ""
}

func printUsage() {
	program := path.Base(os.Args[0])
	message := `Usage: ` + program + ` [flags]

Dart FIDL backend, used to generate Dart bindings from JSON IR input (the
intermediate representation of a FIDL library).

Flags:
`
	fmt.Fprint(flag.CommandLine.Output(), message)
	flag.PrintDefaults()
}

func main() {
	flag.Parse()
	if !flag.Parsed() || !flags.valid() {
		printUsage()
		os.Exit(1)
	}

	fidl, err := types.ReadJSONIr(*flags.jsonPath)
	if err != nil {
		log.Fatal(err)
	}
	tree := ir.Compile(fidl)

	generator := backend.NewFidlGenerator()

	// TODO(pascallouis): Remove.
	if outputBase := *flags.deprecatedOutputBase; outputBase != "" {
		asyncPath := filepath.Join(outputBase, "fidl_async.dart")
		testPath := filepath.Join(outputBase, "fidl_test.dart")
		flags.outAsyncPath = &asyncPath
		flags.outTestPath = &testPath
	}

	outAsyncPath := *flags.outAsyncPath
	if outAsyncPath != "" {
		err := generator.GenerateAsyncFile(tree, outAsyncPath, *flags.dartfmt)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}

	outTestPath := *flags.outTestPath
	if outTestPath != "" {
		err := generator.GenerateTestFile(tree, outTestPath, *flags.dartfmt)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}
}
