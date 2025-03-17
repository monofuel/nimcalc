# nimcalc

- nimcalc is a simple CAS (Computer Algebra System) for Nim.

## Example

```nim
import nimcalc

let ast = parseExpression("(1/2) + (1/5)")
let simplified = simplify(ast)

# will print "7/10"
echo "Simplified: ", toMathString(simplified)
```