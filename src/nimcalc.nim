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
  result = CalcNode(kind: AstKind(kind))
  case kind
  of bkAdd: result.left = left; result.right = right
  of bkMul: result.left = left; result.right = right
  of bkSub: result.left = left; result.right = right
  of bkDiv: result.left = left; result.right = right
  of bkEq:  result.left = left; result.right = right

proc parseExpression*(expr: string): CalcNode =
  ## Parse a mathematical expression into an AST (exported)
  let cleanedExpr = expr.replace(" ", "")
  if cleanedExpr.len == 0:
    return nil

  let eqParts = cleanedExpr.split('=')
  if eqParts.len == 2:
    let left = parseExpression(eqParts[0])
    let right = parseExpression(eqParts[1])
    return newBinary(bkEq, left, right)

  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '+' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkAdd, left, right)
    elif cleanedExpr[i] == '-' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkSub, left, right)

  for i in countdown(cleanedExpr.high, 0):
    if cleanedExpr[i] == '*' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkMul, left, right)
    elif cleanedExpr[i] == '/' and i > 0:
      let left = parseExpression(cleanedExpr[0..<i])
      let right = parseExpression(cleanedExpr[i+1..^1])
      return newBinary(bkDiv, left, right)

  if cleanedExpr.len > 0:
    for i in 0..<cleanedExpr.len:
      if cleanedExpr[i].isAlphaAscii:
        if i == 0:
          return newVar(cleanedExpr)
        else:
          let coefStr = cleanedExpr[0..<i]
          let varName = cleanedExpr[i..^1]
          let coef = newNum(parseFloat(coefStr))
          let varNode = newVar(varName)
          return newBinary(bkMul, coef, varNode)
    return newNum(parseFloat(cleanedExpr))

  return nil

proc simplify*(node: CalcNode): CalcNode =
  if node.isNil:
    return nil
  case node.kind
  of akNum, akVar:
    return node  # Already simplified
  of akAdd:
    let left = simplify(node.left)
    let right = simplify(node.right)
    if left.kind == akNum and right.kind == akNum:
      return newNum(left.numValue + right.numValue)  # Evaluate "1 + 2" → "3"
    elif left.kind == akMul and right.kind == akMul and
         left.right.kind == akVar and right.right.kind == akVar and
         left.right.varName == right.right.varName:
      # Combine "5x + 2x" → "7x"
      return newBinary(bkMul, newNum(left.left.numValue + right.left.numValue), left.right)
    return newBinary(bkAdd, left, right)  # No simplification possible
  of akMul:
    let left = simplify(node.left)
    let right = simplify(node.right)
    if left.kind == akNum and right.kind == akNum:
      return newNum(left.numValue * right.numValue)  # Evaluate "2 * 3" → "6"
    return newBinary(bkMul, left, right)
  # Add cases for akSub, akDiv, akEq as needed
  else:
    return node

proc `$`*(node: CalcNode): string =
  ## Pretty Print a CalcNode as a tree (exported)
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

proc toMathString*(node: CalcNode): string =
  ## Convert a CalcNode AST back to a mathematical expression
  if node.isNil:
    return ""
  case node.kind
  of akNum:
    # Remove .0 from whole numbers for cleaner output
    if node.numValue == float(int(node.numValue)):
      result = $int(node.numValue)
    else:
      result = $node.numValue
  of akVar:
    result = node.varName
  of akAdd:
    result = toMathString(node.left) & " + " & toMathString(node.right)
  of akMul:
    # Special case: omit * for coefficient-variable pairs (e.g., "5x" not "5 * x")
    let leftStr = toMathString(node.left)
    let rightStr = toMathString(node.right)
    if node.left.kind == akNum and node.right.kind == akVar:
      result = leftStr & rightStr
    else:
      result = leftStr & " * " & rightStr
  of akSub:
    result = toMathString(node.left) & " - " & toMathString(node.right)
  of akDiv:
    result = toMathString(node.left) & " / " & toMathString(node.right)
  of akEq:
    result = toMathString(node.left) & " = " & toMathString(node.right)