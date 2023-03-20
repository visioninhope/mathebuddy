/// mathe:buddy - a gamified app for higher math
/// (c) 2022-2023 by TH Koeln
/// Author: Andreas Schwenk contact@compiler-construction.com
/// Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
/// License: GPL-3.0-or-later

import 'dart:math';

import 'package:mathebuddy/screen.dart';
import 'package:tex/tex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mathebuddy/mbcl/src/level_item.dart';
import 'package:mathebuddy/math-runtime/src/parse.dart' as term_parser;

import 'package:mathebuddy/color.dart';
import 'package:mathebuddy/help.dart';
import 'package:mathebuddy/main.dart';
import 'package:mathebuddy/paragraph.dart';

Widget generateLevelItem(CoursePageState state, MbclLevelItem item,
    {paragraphPaddingLeft = 3.0,
    paragraphPaddingRight = 3.0,
    paragraphPaddingTop = 10.0,
    paragraphPaddingBottom = 5.0,
    MbclExerciseData? exerciseData}) {
  if (item.error.isNotEmpty) {
    return generateErrorWidget(
        'ERROR in element "${item.title}":\n${item.error}');
  }
  switch (item.type) {
    case MbclLevelItemType.section:
      {
        return Padding(
            //padding: EdgeInsets.all(3.0),
            padding:
                EdgeInsets.only(left: 3.0, right: 3.0, top: 10.0, bottom: 5.0),
            child: Text(item.text,
                style: Theme.of(state.context).textTheme.headlineLarge));
      }
    case MbclLevelItemType.subSection:
      {
        return Padding(
            padding:
                EdgeInsets.only(left: 3.0, right: 3.0, top: 10.0, bottom: 5.0),
            child: Text(item.text,
                style: Theme.of(state.context).textTheme.headlineMedium));
      }
    case MbclLevelItemType.paragraph:
      {
        List<InlineSpan> list = [];
        for (var subItem in item.items) {
          list.add(generateParagraphItem(state, subItem,
              exerciseData: exerciseData));
        }
        var richText = RichText(
          text: TextSpan(children: list),
        );
        return Padding(
          padding: EdgeInsets.only(
              left: paragraphPaddingLeft,
              right: paragraphPaddingRight,
              top: paragraphPaddingTop,
              bottom: paragraphPaddingBottom),
          child: richText,
        );
      }
    case MbclLevelItemType.alignCenter:
      {
        List<Widget> list = [];
        for (var subItem in item.items) {
          list.add(
              generateLevelItem(state, subItem, exerciseData: exerciseData));
        }
        return Padding(
            padding: EdgeInsets.all(3.0),
            child: Align(
                alignment: Alignment.topCenter,
                child: Wrap(alignment: WrapAlignment.start, children: list)));
      }
    case MbclLevelItemType.equation:
      {
        var texSrc = item.text;
        Widget equationWidget = Text('');
        var tex = TeX();
        tex.scalingFactor = 1.1;
        var svg = tex.tex2svg(texSrc);
        var svgWidth = tex.width;
        if (svg.isEmpty) {
          equationWidget = Text('TeX-ERROR: ${tex.error}',
              style: TextStyle(color: Colors.red));
        } else {
          var eqNumber = int.parse(item.id);
          var eqNumberWidget = Text(eqNumber >= 0 ? '($eqNumber)' : '');
          equationWidget = Row(
            children: [
              Expanded(
                  child: SvgPicture.string(svg, width: svgWidth.toDouble())),
              Column(children: [eqNumberWidget]),
            ],
          );
        }
        return Padding(
            padding: EdgeInsets.all(3.0),
            child: Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                    alignment: WrapAlignment.start,
                    children: [equationWidget])));
      }
    case MbclLevelItemType.span:
      {
        List<InlineSpan> list = [];
        for (var subItem in item.items) {
          list.add(generateParagraphItem(state, subItem,
              exerciseData: exerciseData));
        }
        var richText = RichText(
          text: TextSpan(children: list),
        );
        /*return Padding(
          padding: EdgeInsets.all(3.0),
          child: richText,
        );*/
        return richText;
      }
    case MbclLevelItemType.itemize:
    case MbclLevelItemType.enumerate:
    case MbclLevelItemType.enumerateAlpha:
      {
        List<Widget> rows = [];
        for (var i = 0; i < item.items.length; i++) {
          var subItem = item.items[i];
          Widget w = Icon(
            Icons.fiber_manual_record,
            size: 8,
          );
          if (item.type == MbclLevelItemType.enumerate) {
            w = Text("${i + 1}.");
          } else if (item.type == MbclLevelItemType.enumerateAlpha) {
            w = Text("${String.fromCharCode("a".codeUnitAt(0) + i)})");
          }
          var label = Column(children: [
            Padding(
                padding: EdgeInsets.only(
                    left: 15.0, right: 3.0, top: 0.0, bottom: 0.0),
                child: w)
          ]);
          var content =
              generateLevelItem(state, subItem, exerciseData: exerciseData);

          /*content = Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: '0123456789123456789 ',
                      style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: '0123456789123456789 ',
                      style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: '0123456789123456789 ',
                      style: TextStyle(color: Colors.black)),
                  TextSpan(
                      text: '0123456789123456789 ',
                      style: TextStyle(color: Colors.black)),
                ]))
              ]);*/
          /*content = Column(
            children: [content],
          );*/

          /*var row = Column(children: [
            Row(children: [
              w, //label,
              Column(children: [content])
            ]),
            //Column(children: [content])
          ]);*/

          var row = Padding(
              padding: EdgeInsets.only(left: 30.0, top: 5, bottom: 5),
              child: content);

          rows.add(row);
          //rows.add(row);
        }
        //return Column(children: rows);

        /*return Column(children: [
          Row(children: [
            Text('1. '),
            Row(children: [
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  RichText(
                      text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                        TextSpan(text: 'my very long texttt '),
                        TextSpan(text: 'my very long text '),
                        TextSpan(text: 'my very long text '),
                        TextSpan(text: 'my very long text '),
                        TextSpan(text: 'my very long text '),
                      ]))
                ],
              )
            ]),
          ]),
          Row(children: [Text('2. '), Text('my text')]),
          Row(children: [Text('3. '), Text('my text')]),
        ]);*/

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: rows);
      }
    case MbclLevelItemType.newPage:
      {
        return Text(
          '\n--- page break will be here later ---\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        );
      }
    case MbclLevelItemType.example:
      {
        List<Widget> list = [];
        // TODO: icon
        var title = Row(children: [
          Padding(
              padding: EdgeInsets.all(3.0),
              child: Text('EXAMPLE: ${item.title}',
                  style: TextStyle(fontWeight: FontWeight.bold)))
        ]);
        list.add(title);
        for (var i = 0; i < item.items.length; i++) {
          var subItem = item.items[i];
          list.add(Wrap(children: [
            generateLevelItem(state, subItem,
                paragraphPaddingLeft: 20.0,
                paragraphPaddingTop: i == 0 ? 0.0 : 10.0,
                exerciseData: exerciseData)
          ]));
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: list);
      }
    case MbclLevelItemType.defDefinition:
    case MbclLevelItemType.defTheorem:
      {
        // TODO: other MbclLevelItemType.def*
        // TODO: icon
        var prefix = '';
        switch (item.type) {
          case MbclLevelItemType.defDefinition:
            prefix = 'Definition';
            break;
          case MbclLevelItemType.defTheorem:
            prefix = 'Theorem';
            break;
          default:
            prefix = 'UNIMPLEMENTED';
            break;
        }
        List<Widget> list = [];
        var title = Row(children: [
          Padding(
              //padding: EdgeInsets.all(3.0),
              padding: EdgeInsets.only(
                  left: 3.0, right: 3.0, top: 12.0, bottom: 8.0),
              child: Text('$prefix (${item.title})',
                  style: TextStyle(fontWeight: FontWeight.bold)))
        ]);
        list.add(title);
        for (var i = 0; i < item.items.length; i++) {
          var subItem = item.items[i];
          list.add(Wrap(children: [
            generateLevelItem(state, subItem,
                paragraphPaddingLeft: 20.0,
                paragraphPaddingTop: i == 0 ? 0.0 : 10.0,
                exerciseData: exerciseData)
          ]));
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: list);
      }
    case MbclLevelItemType.figure:
      {
        List<Widget> rows = [];
        var figureData = item.figureData as MbclFigureData;
        // image
        var width = 100;
        for (var option in figureData.options) {
          switch (option) {
            case MbclFigureOption.width100:
              width = 100;
              break;
            case MbclFigureOption.width75:
              width = 75;
              break;
            case MbclFigureOption.width66:
              width = 66;
              break;
            case MbclFigureOption.width50:
              width = 50;
              break;
            case MbclFigureOption.width33:
              width = 33;
              break;
            case MbclFigureOption.width25:
              width = 25;
              break;
          }
        }
        if (figureData.data.startsWith('<svg') ||
            figureData.data.startsWith('<?xml')) {
          rows.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SvgPicture.string(
              figureData.data,
              width: screenWidth * width / 100.0,
            )
          ]));
        }
        // caption
        if (figureData.caption.isNotEmpty) {
          Widget caption = generateLevelItem(state, figureData.caption[0]);
          rows.add(Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [caption]));
        }
        // create column widget
        return Column(children: rows);
      }
    case MbclLevelItemType.table:
      {
        var tableData = item.tableData as MbclTableData;
        List<TableRow> rows = [];
        // head
        List<TableCell> headColumns = [];
        for (var columnData in tableData.head.columns) {
          var cell = generateLevelItem(state, columnData);
          headColumns.add(TableCell(child: cell));
        }
        rows.add(TableRow(children: headColumns));
        // rows
        for (var rowData in tableData.rows) {
          List<TableCell> columns = [];
          for (var columnData in rowData.columns) {
            var cell = generateLevelItem(state, columnData);
            columns.add(TableCell(child: cell));
          }
          rows.add(TableRow(children: columns));
        }
        // create table widget
        return Table(
            border: TableBorder.all(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows);
      }
    case MbclLevelItemType.exercise:
      {
        exerciseKey = GlobalKey();
        var exerciseData = item.exerciseData as MbclExerciseData;
        if (exerciseData.runInstanceIdx < 0) {
          exerciseData.runInstanceIdx =
              Random().nextInt(exerciseData.instances.length);
        }
        List<Widget> list = [];
        var title = Wrap(children: [
          Container(
              key: exerciseKey,
              child: Row(children: [
                Text(' '), // TODO: use padding instead of Text(' ')
                Icon(Icons.play_circle_outlined),
                Text(' '),
                // TODO: wrap does not work:
                Text(item.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
              ]))
        ]);
        list.add(title);
        for (var i = 0; i < item.items.length; i++) {
          var subItem = item.items[i];
          list.add(Wrap(children: [
            generateLevelItem(state, subItem,
                paragraphPaddingLeft: 10.0,
                paragraphPaddingTop: i == 0 ? 5.0 : 10.0,
                exerciseData: item.exerciseData)
          ]));
        }

        Color feedbackColor = getFeedbackColor(exerciseData.feedback);
        Widget feedbackText = Text('');
        switch (exerciseData.feedback) {
          case MbclExerciseFeedback.unchecked:
            feedbackText =
                Text('?', style: TextStyle(color: feedbackColor, fontSize: 20));
            break;
          case MbclExerciseFeedback.correct:
            feedbackText = Icon(Icons.check, color: feedbackColor, size: 24);
            break;
          case MbclExerciseFeedback.incorrect:
            feedbackText = Icon(Icons.clear, color: feedbackColor, size: 24);
            break;
        }

        list.add(GestureDetector(
            onTap: () {
              print("----- evaluating exercise -----");
              state.keyboardState.layout = null;
              // check exercise: TODO must implement in e.g. new file exercise.dart
              var allCorrect = true;
              for (var inputFieldId in exerciseData.inputFields.keys) {
                var inputField = exerciseData.inputFields[inputFieldId]
                    as MbclInputFieldData;

                var ok = false;
                try {
                  var studentTerm =
                      term_parser.Parser().parse(inputField.studentValue);
                  var expectedTerm =
                      term_parser.Parser().parse(inputField.expectedValue);
                  print("comparing $studentTerm to $expectedTerm");
                  ok = expectedTerm.compareNumerically(studentTerm);
                } catch (e) {
                  // TODO: give GUI feedback, that term is not well formed, ...
                  print("evaluating answer failed: $e");
                  ok = false;
                }
                if (ok) {
                  print("answer OK");
                } else {
                  allCorrect = false;
                  print("answer wrong: expected ${inputField.expectedValue},"
                      " got ${inputField.studentValue}");
                }
              }
              if (allCorrect) {
                print("... all answers are correct!");
                exerciseData.feedback = MbclExerciseFeedback.correct;
              } else {
                print("... at least one answer is incorrect!");
                exerciseData.feedback = MbclExerciseFeedback.incorrect;
              }
              print("----- end of exercise evaluation -----");
              // ignore: invalid_use_of_protected_member
              state.setState(() {});
            },
            child: Center(
                child: Container(
                    margin: EdgeInsets.only(left: 20, top: 10, right: 20),
                    child: Container(
                      width: 75, //double.infinity,
                      //padding: EdgeInsets.only(left: 15, right: 5),
                      decoration: BoxDecoration(
                          border: Border.all(
                              width: 2.5,
                              color: feedbackColor,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(5),
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20))),
                      child: Center(child: feedbackText),
                    )))));
        return Container(
            margin: EdgeInsets.only(top: 20.0, bottom: 10.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: list));
      }
    case MbclLevelItemType.multipleChoice:
    case MbclLevelItemType.singleChoice:
      {
        // exerciseData is non-null in a multiple choice context
        exerciseData as MbclExerciseData;
        //
        int n = item.items.length;
        if (exerciseData.indexOrdering.isEmpty) {
          exerciseData.indexOrdering = List<int>.generate(n, (i) => i);
          if (exerciseData.staticOrder == false) {
            shuffleIntegerList(exerciseData.indexOrdering);
          }
        }
        // generate answers
        List<Widget> mcOptions = [];
        for (var i = 0; i < item.items.length; i++) {
          var inputField = item.items[exerciseData.indexOrdering[i]];
          var inputFieldData = inputField.inputFieldData as MbclInputFieldData;
          if (exerciseData.inputFields.containsKey(inputField.id) == false) {
            exerciseData.inputFields[inputField.id] = inputFieldData;
            inputFieldData.studentValue = "false";
            var exerciseInstance =
                exerciseData.instances[exerciseData.runInstanceIdx];
            inputFieldData.expectedValue =
                exerciseInstance[inputFieldData.variableId] as String;
          }
          var feedbackColor = getFeedbackColor(exerciseData.feedback);
          var iconId = 0;
          if (inputFieldData.studentValue == "false") {
            if (item.type == MbclLevelItemType.singleChoice) {
              iconId = 0xe504; // Icons.radio_button_unchecked
            } else {
              iconId = 0xe158; // Icons.check_box_outline_blank
            }
          } else {
            if (item.type == MbclLevelItemType.singleChoice) {
              iconId = 0xe503; // Icons.radio_button_checked
            } else {
              iconId = 0xEF46; // Icons.check_box_outlined
            }
          }
          var icon = Icon(
            IconData(iconId, fontFamily: 'MaterialIcons'),
            color: feedbackColor,
            size: 36,
          );
          var button = Column(children: [
            Padding(
                padding: EdgeInsets.only(
                    left: 8.0, right: 2.0, top: 0.0, bottom: .0),
                child: icon),
          ]);
          var text = generateLevelItem(state, inputField.items[0],
              exerciseData: exerciseData);
          mcOptions.add(GestureDetector(
              onTap: () {
                if (item.type == MbclLevelItemType.multipleChoice) {
                  // multiple choice: swap clicked answer
                  if (inputFieldData.studentValue == "true") {
                    inputFieldData.studentValue = "false";
                  } else {
                    inputFieldData.studentValue = "true";
                  }
                } else {
                  // single choice: mark clicked answer as true and mark all
                  // other answers as false
                  for (var subitem in item.items) {
                    var ifd = subitem.inputFieldData as MbclInputFieldData;
                    ifd.studentValue = ifd == inputFieldData ? "true" : "false";
                  }
                }
                exerciseData.feedback = MbclExerciseFeedback.unchecked;
                // ignore: invalid_use_of_protected_member
                state.setState(() {});
              },
              child: Row(children: [button, text])));
        }
        return Column(children: mcOptions);
      }
    default:
      {
        print(
            "ERROR: genLevelItem(..): type '${item.type.name}' is not implemented");
        return Text(
          "\n--- ERROR: genLevelItem(..): type '${item.type.name}' is not implemented ---\n",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        );
      }
  }
}

Widget generateErrorWidget(String errorText) {
  return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          padding: EdgeInsets.all(5),
          child: Text(errorText,
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        )
      ]);
}
