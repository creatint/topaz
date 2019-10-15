// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package templates

// XUnion is the template for xunion declarations.
const XUnion = `
{{- define "XUnionDeclaration" -}}
enum {{ .TagName }} {
{{- if .IsFlexible }}
  $unknown,
{{- end }}
{{- range .Members }}
  {{ .Tag }}, // {{ .Ordinal | printf "%#x" }}
{{- end }}
}

const Map<int, {{ .TagName }}> _{{ .TagName }}_map = {
{{- range .Members }}
  {{ .Ordinal }}: {{ $.TagName }}.{{ .Tag }},
{{- end }}
};

{{range .Doc }}
///{{ . -}}
{{- end }}
class {{ .Name }} extends $fidl.XUnion {
{{- range .Members }}

  const {{ $.Name }}.with{{ .CtorName }}({{ .Type.Decl }} value)
    : _ordinal = {{ .Ordinal }}, _data = value;
{{- end }}

  {{ .Name }}._(int ordinal, Object data) : _ordinal = ordinal, _data = data;

  final int _ordinal;
  final _data;
{{ if .IsFlexible }}
  {{ .TagName }} get $tag {
    final {{ .TagName }} $rawtag = _{{ .TagName }}_map[_ordinal];
    return $rawtag == null ? {{ .TagName }}.$unknown : $rawtag;
  }
{{- else }}
  {{ .TagName }} get $tag => _{{ .TagName }}_map[_ordinal];
{{- end }}

{{range .Members }}
  {{ .Type.Decl }} get {{ .Name }} {
    if (_ordinal != {{ .Ordinal }}) {
      return null;
    }
    return _data;
  }

{{- end }}

  @override
  String toString() {
    switch (_ordinal) {
{{- range .Members }}
      case {{ .Ordinal }}:
        return '{{ $.Name }}.{{ .Name }}(${{ .Name }})';
{{- end }}
      default:
{{- if .IsFlexible }}
        return '{{ $.Name }}.<UNKNOWN>';
{{- else }}
        return null;
{{- end }}
    }
  }

  @override
  int get $ordinal => _ordinal;

  @override
  Object get $data => _data;

  static {{ .Name }} _ctor(int ordinal, Object data) {
    return {{ .Name }}._(ordinal, data);
  }
}

// See FIDL-308:
// ignore: recursive_compile_time_constant
const $fidl.XUnionType<{{ .Name }}> {{ .TypeSymbol }} = {{ .TypeExpr }};
// See FIDL-308:
// ignore: recursive_compile_time_constant
const $fidl.XUnionType<{{ .Name }}> {{ .OptTypeSymbol }} = {{ .OptTypeExpr }};
{{ end }}
`
