local DEBUG = true
if DEBUG then
  if not arg or not arg[1] or arg[1] ~= "--debug" then
    local arg = arg or { }
    table.insert(arg, "--debug")
  end
end
local Fractional = require("fractional")
local Bignum = require("bignum")
print("Fractional Library Demo")
print("---------------------------")
local display
display = function(title, frac)
  local num, loss = frac:to_number_annotated()
  return print(tostring(title) .. ": " .. tostring(frac) .. " (≈ " .. tostring(num) .. " " .. tostring(loss) .. ")")
end
print("\nInitializing fractions:")
display("From string", Fractional("22/7"))
display("From float", Fractional(3.14159))
display("From integers", Fractional(355, 113))
print("\nArithmetic operations:")
local f1 = Fractional(1, 2)
local f2 = Fractional(1, 3)
display("1/2 + 1/3", f1 + f2)
display("1/2 - 1/3", f1 - f2)
display("1/2 * 1/3", f1 * f2)
display("1/2 / 1/3", f1 / f2)
print("\nComplex examples:")
display("Calculate π approximation", Fractional(355, 113))
display("Express 0.33333...", Fractional(1, 3))
print("\nLarge number handling:")
local large1 = Fractional("9999999999999999999", "1000000000000000")
display("Large fraction", large1)
local squared = Fractional(22, 7) ^ 2
display("22/7 squared", squared)
print("\nDemonstration of reduction:")
local reduced = Fractional(123456, 7890)
display("Before manual reduction", reduced)
local unreduced = Fractional(0)
unreduced.num = Bignum(123456)
unreduced.den = Bignum(7890)
print("Unreduced: " .. tostring(unreduced.num) .. "/" .. tostring(unreduced.den) .. " (raw internal representation)")
unreduced:reduce()
display("After manual reduction", unreduced)
print("\nReduction threshold example:")
local f_auto = Fractional("1/1")
f_auto:set_reduction_threshold(3)
print("Initial: " .. tostring(f_auto) .. " (reduction threshold: " .. tostring(f_auto.reduction_threshold) .. ")")
print("\nDemonstrate auto-reduction (simplified):")
print("Let's set operations_since_reduction manually to trigger auto-reduction:")
local test_frac = Fractional("10/20")
print("Created test_frac = 10/20")
test_frac.reduction_threshold = 2
print("Set threshold to " .. tostring(test_frac.reduction_threshold))
test_frac.operations_since_reduction = 5
print("Set operations_since_reduction to " .. tostring(test_frac.operations_since_reduction))
print("Raw numerator/denominator before: " .. tostring(test_frac.num) .. "/" .. tostring(test_frac.den))
local result = test_frac + Fractional("0/1")
print("After addition: " .. tostring(result.num) .. "/" .. tostring(result.den) .. " (ops: " .. tostring(result.operations_since_reduction) .. ")")
print("\nSecond test - create an unreduced fraction and increment ops until auto-reduction:")
local f = Fractional(0)
f.num = Bignum(4)
f.den = Bignum(8)
f.operations_since_reduction = 0
f.reduction_threshold = 10
print("Created f = 4/8 with threshold " .. tostring(f.reduction_threshold) .. " and ops " .. tostring(f.operations_since_reduction))
for i = 1, 4 do
  if i == 3 then
    print("About to hit threshold on next operation (ops = " .. tostring(f.operations_since_reduction) .. ", threshold = " .. tostring(f.reduction_threshold) .. ")")
  end
  local prev_f = tostring(f.num) .. "/" .. tostring(f.den)
  f = f + Fractional("0/1")
  local curr_f = tostring(f.num) .. "/" .. tostring(f.den)
  reduced = prev_f ~= curr_f
  local status = reduced and "(AUTO-REDUCED!)" or ""
  print("After operation " .. tostring(i) .. ": " .. tostring(f.num) .. "/" .. tostring(f.den) .. " (ops: " .. tostring(f.operations_since_reduction) .. ")" .. tostring(status))
end
return print("\nDemo complete!")
