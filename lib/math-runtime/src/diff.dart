/**
 * mathe:buddy - a gamified app for higher math
 * (c) 2022-2023 by TH Koeln
 * Author: Andreas Schwenk contact@compiler-construction.com
 * Funded by: FREIRAUM 2022, Stiftung Innovation in der Hochschullehre
 * License: GPL-3.0-or-later
 */

import 'operand.dart';
import 'term.dart';

Term diffTerm(Term term, String varId) {
  var t = new Term('', [], []);
  Term u, v;
  switch (term.op) {
    case '+':
      // diff(n0+n1+...) = diff(n0) + diff(n1) + ...
      t = Term.Op('+', [], []);
      for (var i = 0; i < term.o.length; i++) {
        var oi = term.o[i];
        t.o.add(oi.diff(varId));
      }
      break;
    case '.-':
      // diff(-u) = -diff(u);
      t = Term.Op('.-', [term.o[0].diff(varId)], []);
      break;
    case '-':
      if (term.o.length > 2)
        throw new Exception(
          'diff(..): non-binary "-" operator is unimplemented',
        );
      // diff(u-v) = diff(u) - diff(v);
      t = Term.Op('-', [term.o[0].diff(varId), term.o[1].diff(varId)], []);
      break;
    case '*':
      // diff(u * v * ...) = diff(u)*(v*...) + u*diff(v*...)
      u = term.o[0];
      v = term.o.length == 2 ? term.o[1] : Term.Op('*', term.o.sublist(1), []);
      t = Term.Op('+', [
        Term.Op('*', [u.diff(varId), v.clone()], []),
        Term.Op('*', [u.clone(), v.diff(varId)], []),
      ], []);
      break;
    case '/':
      if (term.o.length > 2)
        throw new Exception(
          'diff(..): non-binary "/" operator is unimplemented',
        );
      // diff(u/v) = (diff(u) * v - u * diff(v)) / v^2;
      t = Term.Op('/', [
        Term.Op('-', [
          Term.Op('*', [term.o[0].diff(varId), term.o[1].clone()], []),
          Term.Op('*', [term.o[0].clone(), term.o[1].diff(varId)], []),
        ], []),
        Term.Op('^', [term.o[1].clone(), Term.ConstInt(2)], []),
      ], []);
      break;
    case '^':
      // diff(u^v) = diff(u) * v * u^(v-1);
      if (term.o[1].op != '#') {
        throw new Exception(
          'diff(..): u^v: operator ^ only implemented for constant v',
        );
      }
      t = Term.Op('*', [
        term.o[0].diff(varId),
        term.o[1].clone(),
        Term.Op('^', [
          term.o[0].clone(),
          Term.ConstInt(
            Operand.addSub('-', term.o[1].value, Operand.createInt(1)).real,
          ),
        ], []),
      ], []);
      break;
    case 'exp':
      // diff(exp(u)) = diff(u) * exp(u);
      t = Term.Op('*', [
        term.o[0].diff(varId),
        Term.Op('exp', [term.o[0].clone()], []),
      ], []);
      break;
    case 'sin':
      // diff(sin(u)) = diff(u) * cos(u)
      t = Term.Op('*', [
        term.o[0].diff(varId),
        Term.Op('cos', [term.o[0].clone()], []),
      ], []);
      break;
    case 'cos':
      // diff(cos(u)) = - diff(u) * cos(u)
      t = Term.Op('.-', [
        Term.Op('*', [
          term.o[0].diff(varId),
          Term.Op('cos', [term.o[0].clone()], []),
        ], []),
      ], []);
      break;
    case '\$':
      t = Term.ConstInt(term.value.id == varId ? 1 : 0);
      break;
    case '#':
      if (term.value.type == OperandType.INT ||
          term.value.type == OperandType.RATIONAL ||
          term.value.type == OperandType.COMPLEX ||
          term.value.type == OperandType.REAL)
        t = Term.ConstInt(0);
      else
        throw new Exception(
          'diff(constant): unimplemented type ' + term.value.type.name,
        );
      break;
    default:
      throw new Exception('diff(..): unimplemented operator "' + term.op + '"');
  }
  return t;
}
