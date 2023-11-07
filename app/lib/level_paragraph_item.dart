/// mathe:buddy - a gamified app for higher math
/// https://mathebuddy.github.io/
/// (c) 2022-2023 by TH Koeln
/// Author: Andreas Schwenk contact@compiler-construction.com
/// Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
/// License: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'package:mathebuddy/mbcl/src/level_item.dart';

import 'package:mathebuddy/level.dart';
import 'package:mathebuddy/screen.dart';
import 'package:mathebuddy/level_paragraph_item_math.dart';
import 'package:mathebuddy/level_paragraph_item_input_field.dart';
import 'package:mathebuddy/style.dart';

InlineSpan generateParagraphItem(LevelState state, MbclLevelItem item,
    {bold = false,
    italic = false,
    color = Colors.black,
    MbclExerciseData? exerciseData}) {
  switch (item.type) {
    case MbclLevelItemType.reference:
      {
        var text = TextSpan(
            text: item.text, //
            style: TextStyle(
              color: getStyle().matheBuddyGreen,
              fontSize: defaultFontSize,
              fontWeight: FontWeight.bold,
            ));
        if (item.error.isNotEmpty) {
          text = TextSpan(
              text: item.error, //
              style: TextStyle(color: Colors.red));
        }
        return text;
      }
    case MbclLevelItemType.text:
      return TextSpan(
        text: "${item.text} ",
        style: TextStyle(
            color: color,
            height: 1.6, //1.6,
            fontSize: defaultFontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal),
      );
    case MbclLevelItemType.inlineCode:
      return TextSpan(
        text: "${item.text} ",
        style: TextStyle(
            color: color,
            height: 1.6, //1.6,
            fontFamily: 'RobotoMono',
            fontSize: defaultFontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal),
      );
    case MbclLevelItemType.color:
      {
        List<InlineSpan> gen = [];
        var colorKey = int.parse(item.id);
        var colors = [
          // TODO
          Colors.black,
          getStyle().matheBuddyRed,
          getStyle().matheBuddyYellow,
          getStyle().matheBuddyGreen,
          Colors.orange
        ];
        var color = colors[colorKey % colors.length];
        for (var it in item.items) {
          gen.add(generateParagraphItem(state, it,
              color: color, exerciseData: exerciseData));
        }
        return TextSpan(children: gen);
      }
    case MbclLevelItemType.boldText:
    case MbclLevelItemType.italicText:
      {
        List<InlineSpan> gen = [];
        switch (item.type) {
          case MbclLevelItemType.boldText:
            {
              for (var it in item.items) {
                gen.add(generateParagraphItem(state, it,
                    bold: true, color: color, exerciseData: exerciseData));
              }
              return TextSpan(children: gen);
            }
          case MbclLevelItemType.italicText:
            {
              for (var it in item.items) {
                gen.add(generateParagraphItem(state, it,
                    italic: true, color: color, exerciseData: exerciseData));
              }
              return TextSpan(
                children: gen,
              );
            }
          default:
            // this will never happen
            return TextSpan();
        }
      }
    case MbclLevelItemType.inlineMath:
    case MbclLevelItemType.displayMath:
      {
        return generateParagraphItemMath(state, item,
            bold: bold,
            italic: italic,
            color: color,
            exerciseData: exerciseData);
      }
    case MbclLevelItemType.inputField:
      {
        AppInputField f = AppInputField();
        InlineSpan inputField = f.generateParagraphItemInputField(state, item,
            bold: bold,
            italic: italic,
            color: color,
            exerciseData: exerciseData);
        state.activeInputFields.add(f);
        return inputField;
      }
    default:
      {
        print(
            "ERROR: genParagraphItem(..): type '${item.type.name}' is not implemented");
        return TextSpan(
            text: "ERROR: genParagraphItem(..): "
                "type '${item.type.name}' is not implemented",
            style: TextStyle(color: Colors.red));
      }
  }
}
