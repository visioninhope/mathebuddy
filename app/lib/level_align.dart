/// mathe:buddy - a gamified app for higher math
/// https://mathebuddy.github.io/
/// (c) 2022-2024 by TH Koeln
/// Author: Andreas Schwenk contact@compiler-construction.com
/// Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
/// License: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'package:mathebuddy/mbcl/src/level_item.dart';
import 'package:mathebuddy/mbcl/src/level_item_exercise.dart';
import 'package:mathebuddy/mbcl/src/level.dart';

import 'package:mathebuddy/widget_level.dart';

Widget generateAlign(State state, MbclLevel level, MbclLevelItem item,
    {MbclExerciseData? exerciseData}) {
  List<Widget> list = [];
  for (var subItem in item.items) {
    list.add(
        generateLevelItem(state, level, subItem, exerciseData: exerciseData));
  }
  return Padding(
      padding: EdgeInsets.all(3.0),
      child: Align(
          alignment: Alignment.topCenter,
          child: Wrap(alignment: WrapAlignment.start, children: list)));
}
