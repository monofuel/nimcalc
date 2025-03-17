## Put your tests here.

import std/unittest, nimcalc


let testProblems = [
  "1 + 1",
  "2 * 2",
  "3 / 3",
  "4 - 4",
  "5x + 10x",
  "2x + 3 = y"
]

suite "nimcalc":
  test "parseExpression":
    for problem in testProblems:
      let ast = parseExpression(problem)
      echo "AST: ", $ast
      check ast != nil
