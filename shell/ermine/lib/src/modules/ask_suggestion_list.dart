// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'ask_model.dart';

class AskSuggestionList extends StatelessWidget {
  final AskModel model;
  final _kListItemHeight = 50.0;

  const AskSuggestionList({this.model});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model.suggestions,
      builder: (context, child) => RawKeyboardListener(
            onKey: model.onKey,
            focusNode: model.focusNode,
            child: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final suggestion = model.suggestions.value[index];
                  final iconImageNotifier =
                      model.imageFromSuggestion(suggestion);
                  return GestureDetector(
                    onTap: () => model.onSelect(suggestion),
                    child: AnimatedBuilder(
                      animation: model.selection,
                      builder: (context, child) {
                        return Material(
                          color: Colors.white,
                          elevation: model.elevation,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            height: _kListItemHeight,
                            color: model.selection.value == index
                                ? Colors.lightBlue
                                : Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                AnimatedBuilder(
                                  animation: iconImageNotifier,
                                  builder: (context, child) => Offstage(
                                        offstage:
                                            iconImageNotifier.value == null,
                                        child: RawImage(
                                          color: model.selection.value == index
                                              ? Colors.white
                                              : Colors.grey[900],
                                          image: iconImageNotifier.value,
                                          width: 24,
                                          height: 24,
                                          filterQuality: FilterQuality.medium,
                                        ),
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                ),
                                Text(
                                  suggestion.display.headline,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: model.selection.value == index
                                        ? Colors.white
                                        : Colors.grey[900],
                                    fontFamily: 'RobotoMono',
                                    fontWeight: model.selection.value == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 22.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: model.suggestions.value.length,
              ),
            ),
          ),
    );
  }
}
