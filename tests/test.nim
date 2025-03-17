## Put your tests here.

import std/unittest, nimcalc

suite "nimcalc":
  test "parseExpression":
    let testProblems = [
      "1 + 1",
      "2 * 2",
      "3 / 3",
      "4 - 4",
      "5x + 10x",
      "2x + 3 = y"
    ]
    for problem in testProblems:
      let ast = parseExpression(problem)
      echo "AST: ", $ast
      check ast != nil

  test "toMathString":
    let testProblems = [
      "1 + 1",
      "2 * 2",
      "3 / 3",
      "4 - 4",
      "5x + 10x",
      "2x + 3 = y"
    ]
    for problem in testProblems:
      let ast = parseExpression(problem)
      let mathString = toMathString(ast)
      echo "Math String: ", mathString
      check mathString == problem
