import std/unittest, nimcalc

suite "nimcalc":
  test "parseExpression":
    let testProblems = [
      "1 + 1",
      "2 * 2",
      "3 / 3",
      "4 - 4",
      "5x + 10x",
      "2x + 3 = y",
      "(1/2) + (1/5)"
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
      "2x + 3 = y",
    ]
    for problem in testProblems:
      let ast = parseExpression(problem)
      let mathString = toMathString(ast)
      echo "Math String: ", problem, " -> ", mathString
      check mathString == problem

  test "simplify":
    let testProblems = [
      ("1 + 2 + 3", "6"),
      ("5x + 2x", "7x"),
      ("(1/2) + (1/5)", "7/10")
    ]
    for problem in testProblems:
      let ast = parseExpression(problem[0])
      let simplifiedAst = simplify(ast)
      let simplifiedMathString = toMathString(simplifiedAst)
      echo "Simplified Math String: ", problem[0], " -> ", simplifiedMathString
      check simplifiedMathString == problem[1]

  test "decimal":
    let testProblems = [
      ("(1/2) + (1/5)", "0.7")
    ]
    for problem in testProblems:
      let ast = parseExpression(problem[0])
      let decimalAst = toDecimal(ast)
      let decimalMathString = toMathString(decimalAst)