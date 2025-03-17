import std/strutils

type
  CalcNode = ref object of RootObj
    kind: string  # e.g., "Add", "Mul", "Num", "Var", "Eq"
    value: string # For numbers or variables
    left: CalcNode # Left child
    right: CalcNode # Right child

# Helper to create a new CalcNode
proc newCalcNode*(kind: string, value: string = "", left: CalcNode = nil, right: CalcNode = nil): CalcNode =
  CalcNode(kind: kind, value: value, left: left, right: right)

proc parseExpression*(expr: string): CalcNode =
  ## Parse a mathematical expression into an AST
  # Remove whitespace for simplicity
  let cleanedExpr = expr.replace(" ", "")
  if cleanedExpr.len == 0:
    return nil

  # Check for equality (highest-level operator)
  let eqParts = cleanedExpr.split('=')
  if eqParts.len == 2:
    let left = parseExpression(eqParts[0])
    let right = parseExpression(eqParts[1])
    return newCalcNode("Eq", "", left, right)

  # Check for addition or subtraction
  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '+' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newCalcNode("Add", "", left, right)
    elif cleanedExpr[i] == '-' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newCalcNode("Sub", "", left, right)

  # Check for multiplication or division
  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '*' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newCalcNode("Mul", "", left, right)
    elif cleanedExpr[i] == '/' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newCalcNode("Div", "", left, right)

  # Base case: number or variable
  if cleanedExpr.len > 0:
    # Check if it's a coefficient with a variable (e.g., "5x")
    for i in 0..<cleanedExpr.len:
      if cleanedExpr[i].isAlphaNumeric:
        if i == 0:
          return newCalcNode("Var", cleanedExpr) # Just a variable, e.g., "x"
        else:
          let coef = cleanedExpr[0..<i]
          let varName = cleanedExpr[i..^1]
          let coefNode = newCalcNode("Num", coef)
          let varNode = newCalcNode("Var", varName)
          return newCalcNode("Mul", "", coefNode, varNode)
    # If no letters, it's a number
    return newCalcNode("Num", cleanedExpr)

  return nil

proc `$`*(node: CalcNode): string =
  ## Pretty Print an AST node
  if node.isNil:
    return "nil"
  result = node.kind
  if node.value.len > 0:
    result &= " (" & node.value & ")"
  if node.left != nil or node.right != nil:
    result &= "\n  L: " & $node.left
    result &= "\n  R: " & $node.right
