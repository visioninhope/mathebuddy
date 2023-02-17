/**
 * mathe:buddy - a gamified app for higher math
 * (c) 2022-2023 by TH Koeln
 * Author: Andreas Schwenk contact@compiler-construction.com
 * Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
 * License: GPL-3.0-or-later
 */

import 'dart:html';

import '../../lib/smpl/src/interpreter.dart';
import '../../lib/smpl/src/parser.dart';

import 'help.dart';

// TODO: add more examples in (yet not existing) drop-down menu
/*var example = '''
let A:B = randZ<3,3>(-5,5)
let C = A * B
let d = det(C)
let f(x) = x^2
''';*/

var example = '''let a = rand(2,5)
let b = 1/2 + 2/4
let p(x) = 2x^2 + ax - 7
let k=3
while k > 0 {
  k = k - 1;
}
''';

void smplPlayground() {
  // get code
  setTextArea('smpl-editor', example);
  querySelector('#runSmpl')?.onClick.listen((event) {
    var src =
        (querySelector('#smpl-editor') as TextAreaElement).value as String;
    //print(src);
    runSmplCode(src);
  });
}

void runSmplCode(String src) {
  Parser parser = new Parser();
  try {
    // parse
    parser.parse(src);
    // get and show intermediate code (=: ic)
    AST_Node? ast = parser.getAbstractSyntaxTree();
    String astStr = (ast as AST_Node).toString(0);
    showIntermediateCode(astStr);
    // get and show variable values
    var interpreter = new Interpreter();
    var symbols = interpreter.runProgram(ast);
    var output = '';
    for (var id in symbols.keys) {
      output += '@${id} := ${symbols[id]?.term.toString()}\n';
      if (symbols[id]?.value != null)
        output += '${id} := ${symbols[id]?.value.toString()}\n';
    }
    showOutput(output);
  } catch (e) {
    showOutput(e.toString());
  }
}

void showIntermediateCode(String o) {
  document.getElementById('smpl-ic')?.innerHtml =
      '<pre><code>' + o + '</code></pre>';
}

void showOutput(String o) {
  document.getElementById('smpl-output')?.innerHtml =
      '<pre><code>' + o + '</code></pre>';
}
