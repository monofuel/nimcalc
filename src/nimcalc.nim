import std/[strutils, math]

type
  AstKind = enum
    akNum,      # Number (fraction or decimal)
    akVar,      # Variable (e.g., "x", "y")
    akAdd,      # Addition (+)
    akMul,      # Multiplication (*)
    akSub,      # Subtraction (-)
    akDiv,      # Division (/)
    akEq        # Equality (=)

  NumKind = enum
    nkFraction, # Fraction representation
    nkDecimal   # Decimal representation

  BinaryKind = enum  # Subset for binary operations
    bkAdd = akAdd, bkMul = akMul, bkSub = akSub, bkDiv = akDiv, bkEq = akEq

  CalcNode = ref object
    case kind: AstKind
    of akNum:
      case numKind: NumKind
      of nkFraction:
        numerator: int      # Numerator of the fraction
        denominator: int    # Denominator of the fraction (non-zero)
      of nkDecimal:
        decimalValue: float # Decimal value
    of akVar:
      varName: string     # Variable name
    of akAdd, akMul, akSub, akDiv, akEq:
      left, right: CalcNode  # Binary operations

# Helper procs
proc newNumFraction(numerator: int, denominator: int = 1): CalcNode =
  ## Create a number as a fraction, simplifying it
  assert denominator != 0, "Denominator cannot be zero"
  var n = numerator
  var d = denominator
  if d < 0:  # Normalize: ensure denominator is positive
    n = -n
    d = -d
  let g = gcd(abs(n), d)  # Simplify using GCD
  CalcNode(kind: akNum, numKind: nkFraction, numerator: n div g, denominator: d div g)

proc newNumDecimal(value: float): CalcNode =
  ## Create a number as a decimal
  CalcNode(kind: akNum, numKind: nkDecimal, decimalValue: value)

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

  if cleanedExpr.startsWith("(") and cleanedExpr.endsWith(")"):
    var depth = 0
    var balanced = true
    for i in 0..<cleanedExpr.len:
      if cleanedExpr[i] == '(':
        depth += 1
      elif cleanedExpr[i] == ')':
        depth -= 1
        if depth == 0 and i < cleanedExpr.high:
          balanced = false
          break
    if balanced and depth == 0:
      return parseExpression(cleanedExpr[1..^2])

  let eqParts = cleanedExpr.split('=')
  if eqParts.len == 2:
    let left = parseExpression(eqParts[0])
    let right = parseExpression(eqParts[1])
    return newBinary(bkEq, left, right)

  var parenDepth = 0
  for i in countdown(cleanedExpr.high, 0):
    case cleanedExpr[i]
    of '(':
      parenDepth += 1
    of ')':
      parenDepth -= 1
    of '+':
      if parenDepth == 0 and i > 0:
        let left = parseExpression(cleanedExpr[0..<i])
        let right = parseExpression(cleanedExpr[i+1..^1])
        return newBinary(bkAdd, left, right)
    of '-':
      if parenDepth == 0 and i > 0:
        let left = parseExpression(cleanedExpr[0..<i])
        let right = parseExpression(cleanedExpr[i+1..^1])
        return newBinary(bkSub, left, right)
    else:
      discard

  parenDepth = 0
  for i in countdown(cleanedExpr.high, 0):
    case cleanedExpr[i]
    of '(':
      parenDepth += 1
    of ')':
      parenDepth -= 1
    of '*':
      if parenDepth == 0 and i > 0:
        let left = parseExpression(cleanedExpr[0..<i])
        let right = parseExpression(cleanedExpr[i+1..^1])
        return newBinary(bkMul, left, right)
    of '/':
      if parenDepth == 0 and i > 0:
        let left = parseExpression(cleanedExpr[0..<i])
        let right = parseExpression(cleanedExpr[i+1..^1])
        return newBinary(bkDiv, left, right)
    else:
      discard

  if cleanedExpr.len > 0:
    for i in 0..<cleanedExpr.len:
      if cleanedExpr[i].isAlphaAscii:
        if i == 0:
          return newVar(cleanedExpr)
        else:
          let coefStr = cleanedExpr[0..<i]
          let varName = cleanedExpr[i..^1]
          let coef = newNumFraction(parseInt(coefStr))
          let varNode = newVar(varName)
          return newBinary(bkMul, coef, varNode)
    return newNumFraction(parseInt(cleanedExpr))

  return nil

proc simplify*(node: CalcNode): CalcNode =
  ## Simplify an AST, preserving fractions
  if node.isNil:
    return nil
  case node.kind
  of akNum:
    return node  # Already simplified
  of akVar:
    return node
  of akAdd:
    let left = simplify(node.left)
    let right = simplify(node.right)
    if left.kind == akNum and right.kind == akNum and left.numKind == nkFraction and right.numKind == nkFraction:
      let a = left.numerator
      let b = left.denominator
      let c = right.numerator
      let d = right.denominator
      return newNumFraction(a * d + c * b, b * d)
    elif left.kind == akMul and right.kind == akMul and
         left.right.kind == akVar and right.right.kind == akVar and
         left.right.varName == right.right.varName:
      let leftCoef = left.left
      let rightCoef = right.left
      let varNode = left.right
      if leftCoef.kind == akNum and rightCoef.kind == akNum and leftCoef.numKind == nkFraction and rightCoef.numKind == nkFraction:
        return newBinary(bkMul, newNumFraction(leftCoef.numerator * rightCoef.denominator + rightCoef.numerator * leftCoef.denominator,
                                              leftCoef.denominator * rightCoef.denominator), varNode)
    return newBinary(bkAdd, left, right)
  of akMul:
    let left = simplify(node.left)
    let right = simplify(node.right)
    if left.kind == akNum and right.kind == akNum and left.numKind == nkFraction and right.numKind == nkFraction:
      return newNumFraction(left.numerator * right.numerator, left.denominator * right.denominator)
    return newBinary(bkMul, left, right)
  of akDiv:
    let left = simplify(node.left)
    let right = simplify(node.right)
    if left.kind == akNum and right.kind == akNum and right.numKind == nkFraction and left.numKind == nkFraction and right.numerator != 0:
      return newNumFraction(left.numerator * right.denominator, left.denominator * right.numerator)
    return newBinary(bkDiv, left, right)
  else:
    return node  # akSub, akEq not simplified yet

proc toDecimal*(node: CalcNode): CalcNode =
  ## Convert a CalcNode AST to its decimal representation, losing precision
  if node.isNil:
    return nil
  case node.kind
  of akNum:
    if node.numKind == nkDecimal:
      return node  # Already a decimal
    else:
      let decimalValue = node.numerator.float / node.denominator.float
      return newNumDecimal(decimalValue)
  of akVar:
    return node  # Variables stay as-is
  of akAdd:
    let left = toDecimal(node.left)
    let right = toDecimal(node.right)
    if left.kind == akNum and right.kind == akNum:
      let leftVal = if left.numKind == nkFraction: left.numerator.float / left.denominator.float else: left.decimalValue
      let rightVal = if right.numKind == nkFraction: right.numerator.float / right.denominator.float else: right.decimalValue
      return newNumDecimal(leftVal + rightVal)
    return newBinary(bkAdd, left, right)
  of akMul:
    let left = toDecimal(node.left)
    let right = toDecimal(node.right)
    if left.kind == akNum and right.kind == akNum:
      let leftVal = if left.numKind == nkFraction: left.numerator.float / left.denominator.float else: left.decimalValue
      let rightVal = if right.numKind == nkFraction: right.numerator.float / right.denominator.float else: right.decimalValue
      return newNumDecimal(leftVal * rightVal)
    return newBinary(bkMul, left, right)
  of akDiv:
    let left = toDecimal(node.left)
    let right = toDecimal(node.right)
    if left.kind == akNum and right.kind == akNum:
      let leftVal = if left.numKind == nkFraction: left.numerator.float / left.denominator.float else: left.decimalValue
      let rightVal = if right.numKind == nkFraction: right.numerator.float / right.denominator.float else: right.decimalValue
      if rightVal != 0:
        return newNumDecimal(leftVal / rightVal)
    return newBinary(bkDiv, left, right)
  else:
    return node  # akSub, akEq not converted yet

proc `$`*(node: CalcNode): string =
  ## Pretty Print a CalcNode as a tree (exported)
  if node.isNil:
    return "nil"
  case node.kind
  of akNum:
    case node.numKind
    of nkFraction:
      result = "Num (" & $node.numerator & "/" & $node.denominator & ")"
    of nkDecimal:
      result = "Num (" & $node.decimalValue & ")"
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
  ## Convert a CalcNode AST back to a mathematical expression (always as fraction where applicable)
  if node.isNil:
    return ""
  case node.kind
  of akNum:
    if node.numKind == nkFraction:
      if node.denominator == 1:
        result = $node.numerator
      else:
        result = $node.numerator & "/" & $node.denominator
    else:
      result = $node.decimalValue
  of akVar:
    result = node.varName
  of akAdd:
    result = toMathString(node.left) & " + " & toMathString(node.right)
  of akMul:
    let leftStr = toMathString(node.left)
    let rightStr = toMathString(node.right)
    if node.left.kind == akNum and node.right.kind == akVar:
      result = leftStr & rightStr
    else:
      result = leftStr & " * " & rightStr
  of akSub:
    result = toMathString(node.left) & " - " & toMathString(node.right)
  of akDiv:
    let leftStr = if node.left.kind in {akAdd, akSub}: "(" & toMathString(node.left) & ")" else: toMathString(node.left)
    let rightStr = if node.right.kind in {akAdd, akSub}: "(" & toMathString(node.right) & ")" else: toMathString(node.right)
    result = leftStr & " / " & rightStr
  of akEq:
    result = toMathString(node.left) & " = " & toMathString(node.right)
