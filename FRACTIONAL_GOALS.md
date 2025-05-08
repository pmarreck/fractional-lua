# Fractional Library Goals

## Overview
Create a `fractional.moon`/`fractional.yue` library that implements arbitrary precision fractions using the existing `bignum.moon`/`bignum.yue` library.

## Core Requirements

### Class Structure
- Create a `Fractional` class that uses `Bignum` objects for both numerator and denominator
- Track number of operations performed since last reduction

### Initialization
- From string: `Frac("3/4")` → numerator=3, denominator=4
- From float: `Frac(123.456)` → numerator=123456, denominator=1000 (then reduced)
- From integer: `Frac(100)` → numerator=100, denominator=1

### Operations
- Support infix operators: +, -, *, /, ==, <, >, <=, >=
- Implement proper fraction arithmetic (see formulas below)
- Configurable reduction strategy:
  - Perform full GCD reduction after X operations
  - Quick optimization: divide both by 2 if both are even

### Conversion/Output
- String representation: `tostring()` returns "numerator/denominator" (always fully reduced first)
- Float conversion: method to convert to Lua float with precision loss estimate
- JSON serialization

## Implementation Notes

### Addition/Subtraction
- a/b + c/d = (a*d + b*c)/(b*d)
- a/b - c/d = (a*d - b*c)/(b*d)

### Multiplication/Division
- a/b * c/d = (a*c)/(b*d)
- a/b / c/d = (a*d)/(b*c)

### Reduction
- Use GCD from Bignum for fraction reduction
- Track operations to reduce periodically
- Quick check: if both num/den are even, divide both by 2 before any other reduction

### References
- MoonScript documentation: https://moonscript.org/reference
- Yuescript documentation: https://yuescript.org/doc/
- Existing bignum.moon/bignum.yue implementation