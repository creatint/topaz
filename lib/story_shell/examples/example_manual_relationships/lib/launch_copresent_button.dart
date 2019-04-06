import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fidl_fuchsia_modular/fidl.dart';

import 'start_module_button.dart';

/// Specify an emphasis and launch a copresented surface
class CopresentLauncher extends StatefulWidget {
  final ModuleContext _moduleContext;

  final GenerateChildId _generateChildId;

  /// CopresentLauncher
  const CopresentLauncher(this._moduleContext, this._generateChildId, {Key key})
      : super(key: key);

  @override
  CopresentLauncherState createState() =>
      CopresentLauncherState(_moduleContext, _generateChildId);
}

/// Copresent Launch State
class CopresentLauncherState extends State<CopresentLauncher> {
  final ModuleContext _moduleContext;

  final GenerateChildId _generateChildId;

  CopresentLauncherState(
    this._moduleContext,
    this._generateChildId,
  ) : super();

  double _copresentEmphasisExp = 0.0;

  double get _emphasis =>
      (math.pow(2, _copresentEmphasisExp) * 10.0).roundToDouble() / 10.0;

  @override
  Widget build(BuildContext context) => Container(
        alignment: FractionalOffset.center,
        constraints: BoxConstraints(maxWidth: 200.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Slider(
              min: -1.6,
              max: 1.6,
              value: _copresentEmphasisExp,
              label: 'Emphasis: $_emphasis',
              onChanged: (double value) =>
                  setState(() => _copresentEmphasisExp = value),
            ),
            StartModuleButton(
              _moduleContext,
              SurfaceRelation(
                emphasis: _emphasis,
                arrangement: SurfaceArrangement.copresent,
              ),
              'Copresent',
              _generateChildId,
            ),
            StartModuleButton(
              _moduleContext,
              SurfaceRelation(
                emphasis: _emphasis,
                arrangement: SurfaceArrangement.copresent,
                dependency: SurfaceDependency.dependent,
              ),
              'Dependent\nCopresent',
              _generateChildId,
            ),
          ],
        ),
      );
}
