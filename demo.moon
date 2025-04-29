#!/usr/bin/env moonrun
-- demo.moon
-- A demonstration of the Fractional class

DEBUG = true  -- Set to true to see debug output
if DEBUG
  -- Add debug argument if debugging
  if not arg or not arg[1] or arg[1] != "--debug"
    arg = arg or {}
    table.insert(arg, "--debug")

Fractional = require "fractional"
Bignum = require "bignum"

print "Fractional Library Demo"
print "---------------------------"

-- Display helper function
display = (title, frac) ->
  num, loss = frac\to_number_annotated!
  print "#{title}: #{frac} (≈ #{num} #{loss})"

-- Create fractions different ways
print "\nInitializing fractions:"
display "From string", Fractional("22/7")
display "From float", Fractional(3.14159)
display "From integers", Fractional(355, 113)

-- Basic arithmetic
print "\nArithmetic operations:"
f1 = Fractional(1, 2)
f2 = Fractional(1, 3)

display "1/2 + 1/3", f1 + f2
display "1/2 - 1/3", f1 - f2
display "1/2 * 1/3", f1 * f2
display "1/2 / 1/3", f1 / f2

-- Complex examples
print "\nComplex examples:"
display "Calculate π approximation", Fractional(355, 113)
display "Express 0.33333...", Fractional(1, 3)

-- Large numbers
print "\nLarge number handling:"
large1 = Fractional("9999999999999999999", "1000000000000000")
display "Large fraction", large1

-- Example of exponentiation
squared = Fractional(22, 7) ^ 2
display "22/7 squared", squared

print "\nDemonstration of reduction:"
reduced = Fractional(123456, 7890)
display "Before manual reduction", reduced  -- This already calls _reduce internally for display

-- Create an unreduced fraction
unreduced = Fractional(0)
unreduced.num = Bignum(123456)
unreduced.den = Bignum(7890)
print "Unreduced: #{unreduced.num}/#{unreduced.den} (raw internal representation)"

unreduced\reduce!
display "After manual reduction", unreduced

print "\nReduction threshold example:"
f_auto = Fractional("1/1")
f_auto\set_reduction_threshold(3)  -- Reduce after 3 operations
print "Initial: #{f_auto} (reduction threshold: #{f_auto.reduction_threshold})"

print "\nDemonstrate auto-reduction (simplified):"
print "Let's set operations_since_reduction manually to trigger auto-reduction:"

-- Create a fraction with a high operations count
test_frac = Fractional("10/20")  -- This should normally reduce to 1/2
print "Created test_frac = 10/20"

-- Set a low threshold
test_frac.reduction_threshold = 2
print "Set threshold to #{test_frac.reduction_threshold}"

-- Manually set operations count to be high
test_frac.operations_since_reduction = 5
print "Set operations_since_reduction to #{test_frac.operations_since_reduction}"

-- Now do an operation - this should trigger reduction
print "Raw numerator/denominator before: #{test_frac.num}/#{test_frac.den}"
result = test_frac + Fractional("0/1")  -- This doesn't change the value but should trigger reduction
print "After addition: #{result.num}/#{result.den} (ops: #{result.operations_since_reduction})"

print "\nSecond test - create an unreduced fraction and increment ops until auto-reduction:"
f = Fractional(0)
f.num = Bignum(4)
f.den = Bignum(8)  -- This is 1/2 when reduced
f.operations_since_reduction = 0
f.reduction_threshold = 10  -- Set a higher threshold to better demonstrate the counting
print "Created f = 4/8 with threshold #{f.reduction_threshold} and ops #{f.operations_since_reduction}"

for i=1,4
  if i == 3
    print "About to hit threshold on next operation (ops = #{f.operations_since_reduction}, threshold = #{f.reduction_threshold})"
  
  -- Perform an operation that doesn't change the value but increments ops
  prev_f = "#{f.num}/#{f.den}"
  f = f + Fractional("0/1")
  curr_f = "#{f.num}/#{f.den}"
  
  -- Check if reduction happened
  reduced = prev_f != curr_f
  status = reduced and "(AUTO-REDUCED!)" or ""
  print "After operation #{i}: #{f.num}/#{f.den} (ops: #{f.operations_since_reduction})#{status}"

print "\nDemo complete!"