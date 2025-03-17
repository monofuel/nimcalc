import nimcalc

let ast = parseExpression("(1/2) + (1/5)")
let simplified = simplify(ast)

# will print "7/10"
echo "Simplified: ", toMathString(simplified)

# will print "0.7"
echo "Decimal: ", toMathString(toDecimal(simplified))
