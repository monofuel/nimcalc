# nimcalc.nim
import strutils  # For isAlphaAscii, replace, parseFloat

type
  AstKind = enum
    akNum,      # Number (e.g., "1", "5")
    akVar,      # Variable (e.g., "x", "y")
    akAdd,      # Addition (+)
    akMul,      # Multiplication (*)
    akSub,      # Subtraction (-)
    akDiv,      # Division (/)
    akEq        # Equality (=)

  BinaryKind = enum  # Subset for binary operations
    bkAdd = akAdd, bkMul = akMul, bkSub = akSub, bkDiv = akDiv, bkEq = akEq

  CalcNode = ref object
    case kind: AstKind
    of akNum:
      numValue: float    # Store numbers as float for flexibility
    of akVar:
      varName: string    # Variable name
    of akAdd, akMul, akSub, akDiv, akEq:
      left, right: CalcNode  # Binary operations

# Helper procs
proc newNum(value: float): CalcNode =
  CalcNode(kind: akNum, numValue: value)

proc newVar(name: string): CalcNode =
  CalcNode(kind: akVar, varName: name)

proc newBinary(kind: BinaryKind, left, right: CalcNode): CalcNode =
  result = CalcNode(kind: AstKind(kind))  # Set kind first
  case kind
  of bkAdd: result.left = left; result.right = right
  of bkMul: result.left = left; result.right = right
  of bkSub: result.left = left; result.right = right
  of bkDiv: result.left = left; result.right = right
  of bkEq:  result.left = left; result.right = right

proc parseExpression*(expr: string): CalcNode =
  ## Parse a mathematical expression into an AST
  let cleanedExpr = expr.replace(" ", "")
  if cleanedExpr.len == 0:
    return nil

  # Check for equality (lowest precedence)
  let eqParts = cleanedExpr.split('=')
  if eqParts.len == 2:
    let left = parseExpression(eqParts[0])
    let right = parseExpression(eqParts[1])
    return newBinary(bkEq, left, right)

  # Check for addition or subtraction
  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '+' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkAdd, left, right)
    elif cleanedExpr[i] == '-' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkSub, left, right)

  # Check for multiplication or division
  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '*' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkMul, left, right)
    elif cleanedExpr[i] == '/' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkDiv, left, right)

  # Base case: number or variable
  if cleanedExpr.len > 0:
    # Check if it's a coefficient with a variable (e.g., "5x")
    for i in 0..<cleanedExpr.len:
      if cleanedExpr[i].isAlphaAscii:
        if i == 0:
          return newVar(cleanedExpr)  # Just a variable, e.g., "x"
        else:
          let coefStr = cleanedExpr[0..<i]
          let varName = cleanedExpr[i..^1]
          let coef = newNum(parseFloat(coefStr))
          let varNode = newVar(varName)
          return newBinary(bkMul, coef, varNode)
    # If no letters, it's a number
    return newNum(parseFloat(cleanedExpr))

  return nil

proc `$`*(node: CalcNode): string =
  ## Pretty Print a CalcNode
  if node.isNil:
    return "nil"
  case node.kind
  of akNum:
    result = "Num (" & $node.numValue & ")"
  of akVar:
    result = "Var (" & node.varName & ")"
  of akAdd:
    result = "Add\n  L: " & $node.left & "\n  R: " & $node.right
  of akMul:
    result = "Mul\n  L: " & $node.left & "\n  R: " & $node.right
  of akSub:
    result = "Sub\n  L: " & $node.left & "\n  R: " & $node.right
  of akDiv:
    result = "Div\n  L: " & $node.left & "\n  R: " & $node.right
  of akEq:
    result = "Eq\n  L: " & $node.left & "\n  R: " & $node.right
