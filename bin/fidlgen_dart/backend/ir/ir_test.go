// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package ir

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"fidl/compiler/backend/types"
)

func TestCompileXUnion(t *testing.T) {
	cases := []struct {
		name     string
		input    types.XUnion
		expected XUnion
	}{
		{
			name: "SingleInt64",
			input: types.XUnion{
				Attributes: types.Attributes{
					Attributes: []types.Attribute{
						{
							Name:  types.Identifier("Foo"),
							Value: "Bar",
						},
					},
				},
				Name: types.EncodedCompoundIdentifier("Test"),
				Members: []types.XUnionMember{
					{
						Reserved: true,
						Ordinal:  0xbeefbabe,
					},
					{
						Reserved:   false,
						Attributes: types.Attributes{},
						Ordinal:    0xdeadbeef,
						Type: types.Type{
							Kind:             types.PrimitiveType,
							PrimitiveSubtype: types.Int64,
						},
						Name:         types.Identifier("i"),
						Offset:       0,
						MaxOutOfLine: 0,
					},
				},
				Size:         24,
				MaxHandles:   0,
				MaxOutOfLine: 4294967295,
				Strictness:   types.IsFlexible,
			},
			expected: XUnion{
				Name:    "Test",
				TagName: "TestTag",
				Members: []XUnionMember{
					{
						Ordinal: 0xdeadbeef,
						Type: Type{
							Decl:          "int",
							SyncDecl:      "int",
							AsyncDecl:     "int",
							typedDataDecl: "Int64List",
							typeExpr:      "$fidl.Int64Type()",
						},
						Name:     "i",
						CtorName: "I",
						Tag:      "i",
					},
				},
				TypeSymbol:    "kTest_Type",
				TypeExpr:      "$fidl.XUnionType<Test>(\n  members: <int, $fidl.FidlType>{\n    3735928559: $fidl.Int64Type(),\n  },\n  ctor: Test._ctor,\n  nullable: false,\n  flexible: true,\n)",
				OptTypeSymbol: "kTest_OptType",
				OptTypeExpr:   "$fidl.XUnionType<Test>(\nmembers: <int, $fidl.FidlType>{\n    3735928559: $fidl.Int64Type(),\n  },\nctor: Test._ctor,\nnullable: true,\nflexible: true,\n)",
				Strictness:    types.IsFlexible,
			},
		},
	}
	for _, ex := range cases {
		t.Run(ex.name, func(t *testing.T) {
			root := types.Root{
				XUnions: []types.XUnion{ex.input},
				DeclOrder: []types.EncodedCompoundIdentifier{
					ex.input.Name,
				},
			}
			result := Compile(root)
			actual := result.XUnions[0]

			if diff := cmp.Diff(ex.expected, actual, cmp.AllowUnexported(Type{})); diff != "" {
				t.Errorf("expected != actual (-want +got)\n%s", diff)
			}
		})
	}
}

func TestCompileUnion(t *testing.T) {
	cases := []struct {
		name     string
		input    types.Union
		expected XUnion
	}{
		{
			name: "SingleInt64",
			input: types.Union{
				Attributes: types.Attributes{
					Attributes: []types.Attribute{
						{
							Name:  types.Identifier("Foo"),
							Value: "Bar",
						},
					},
				},
				Name: types.EncodedCompoundIdentifier("Test"),
				Members: []types.UnionMember{
					{
						Reserved:      true,
						XUnionOrdinal: 0xbeefbabe,
					},
					{
						Reserved:      false,
						Attributes:    types.Attributes{},
						XUnionOrdinal: 0xdeadbeef,
						Type: types.Type{
							Kind:             types.PrimitiveType,
							PrimitiveSubtype: types.Int64,
						},
						Name:         types.Identifier("i"),
						Offset:       0,
						MaxOutOfLine: 0,
					},
				},
				Size:         24,
				MaxHandles:   0,
				MaxOutOfLine: 4294967295,
			},
			expected: XUnion{
				Name:    "Test",
				TagName: "TestTag",
				Members: []XUnionMember{
					{
						Type: Type{
							Decl:          "int",
							SyncDecl:      "int",
							AsyncDecl:     "int",
							typedDataDecl: "Int64List",
							typeExpr:      "$fidl.Int64Type()",
						},
						Name:     "i",
						Ordinal:  0xdeadbeef,
						CtorName: "I",
						Tag:      "i",
					},
				},
				TypeSymbol:    "kTest_Type",
				TypeExpr:      "$fidl.XUnionType<Test>(\n  members: <int, $fidl.FidlType>{\n    3735928559: $fidl.Int64Type(),\n  },\n  ctor: Test._ctor,\n  nullable: false,\n  flexible: false,\n)",
				OptTypeSymbol: "kTest_OptType",
				OptTypeExpr:   "$fidl.XUnionType<Test>(\nmembers: <int, $fidl.FidlType>{\n    3735928559: $fidl.Int64Type(),\n  },\nctor: Test._ctor,\nnullable: true,\nflexible: false,\n)",
				Strictness:    true,
			},
		},
	}
	for _, ex := range cases {
		t.Run(ex.name, func(t *testing.T) {
			root := types.Root{
				Unions: []types.Union{ex.input},
				DeclOrder: []types.EncodedCompoundIdentifier{
					ex.input.Name,
				},
			}
			result := Compile(root)
			actual := result.XUnions[0]

			if diff := cmp.Diff(ex.expected, actual, cmp.AllowUnexported(XUnionMember{}, Type{})); diff != "" {
				t.Errorf("expected != actual (-want +got)\n%s", diff)
			}
		})
	}
}

func makeLiteralConstant(value string) types.Constant {
	return types.Constant{
		Kind: types.LiteralConstant,
		Literal: types.Literal{
			Kind:  types.NumericLiteral,
			Value: value,
		},
	}
}

func TestCompileConstant(t *testing.T) {
	var c compiler
	cases := []struct {
		input    types.Constant
		expected string
	}{
		{
			input:    makeLiteralConstant("10"),
			expected: "0xa",
		},
		{
			input:    makeLiteralConstant("-1"),
			expected: "-1",
		},
		{
			input:    makeLiteralConstant("0xA"),
			expected: "0xA",
		},
		{
			input:    makeLiteralConstant("1.23"),
			expected: "1.23",
		},
	}
	for _, ex := range cases {
		actual := c.compileConstant(ex.input, nil)
		if ex.expected != actual {
			t.Errorf("%v: expected %s, actual %s", ex.input, ex.expected, actual)
		}
	}
}
