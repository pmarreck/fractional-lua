local Bignum = require("bignum")
local Fractional
do
  local _class_0
  local _base_0 = {
    _init_from_string = function(self, str)
      if str:match("^.-/.-$") then
        local num_str, den_str = str:match("^(.-)/(.-)$")
        self.num = Bignum(num_str)
        self.den = Bignum(den_str)
        if self.den == Bignum(0) then
          return error("Cannot initialize fraction with zero denominator")
        end
      else
        self.num = Bignum(str)
        self.den = Bignum(1)
      end
    end,
    _init_from_integers = function(self, num, den)
      self.num = Bignum(num)
      self.den = Bignum(den)
      if self.den == Bignum(0) then
        return error("Cannot initialize fraction with zero denominator")
      end
    end,
    _init_from_float = function(self, val)
      local str = tostring(val)
      if str:match("%.") then
        local integer_part, decimal_part = str:match("^(%-?%d*)%.(%d*)$")
        integer_part = integer_part or "0"
        decimal_part = decimal_part or ""
        local denominator = 10 ^ #decimal_part
        local numerator = integer_part .. decimal_part
        numerator = numerator:gsub("^-0$", "0")
        self.num = Bignum(numerator)
        self.den = Bignum(denominator)
        return self:_reduce()
      else
        self.num = Bignum(val)
        self.den = Bignum(1)
      end
    end,
    _quick_reduce = function(self)
      while self.num % Bignum(2) == Bignum(0) and self.den % Bignum(2) == Bignum(0) do
        self.num = self.num / Bignum(2)
        self.den = self.den / Bignum(2)
      end
      if self.den < Bignum(0) then
        self.num = -self.num
        self.den = -self.den
      end
    end,
    _reduce = function(self)
      self:_quick_reduce()
      local gcd = self.num:gcd(self.den)
      if gcd > Bignum(1) then
        self.num = self.num / gcd
        self.den = self.den / gcd
      end
      self.operations_since_reduction = 0
    end,
    set_reduction_threshold = function(self, threshold)
      if type(threshold) ~= "number" or threshold < 0 then
        error("Reduction threshold must be a non-negative number")
      end
      self.reduction_threshold = threshold
    end,
    reduce = function(self)
      return self:_reduce()
    end,
    tostring = function(self)
      local copy = Fractional(0)
      copy.num = Bignum(tostring(self.num))
      copy.den = Bignum(tostring(self.den))
      copy:_reduce()
      return tostring(copy.num) .. "/" .. tostring(copy.den)
    end,
    __tostring = function(self)
      return self:tostring()
    end,
    to_number = function(self)
      return Bignum.ratio_to_double(self.num, self.den)
    end,
    to_number_for_display = function(self)
      local num_str = tostring(self.num)
      local den_str = tostring(self.den)
      if den_str == "0" then
        return math.huge
      end
      if num_str == "0" or num_str == "-0" then
        return 0.0
      end
      local result = nil
      local success = pcall(function()
        result = Bignum.ratio_to_double(self.num, self.den)
      end)
      if not success or not result or result ~= result then
        local num_str_val = tonumber(num_str)
        local den_str_val = tonumber(den_str)
        if num_str_val and den_str_val and den_str_val ~= 0 and #num_str < 15 and #den_str < 15 then
          result = num_str_val / den_str_val
        end
      end
      if result and result == result and result ~= math.huge and result ~= -math.huge and result ~= 0 then
        return result
      end
      if #num_str > #den_str + 308 then
        return math.huge
      end
      if #den_str > #num_str + 308 then
        return 0.0
      end
      if #num_str > #den_str + 15 then
        local sig_digits = 15
        local num_significant = string.sub(num_str:gsub("^%-", ""), 1, math.min(sig_digits, #num_str))
        local den_significant = string.sub(den_str:gsub("^%-", ""), 1, math.min(sig_digits, #den_str))
        if #den_str < sig_digits then
          den_significant = den_significant .. string.rep("0", sig_digits - #den_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = (#num_str - #den_str) - (sig_digits - math.min(sig_digits, #den_str))
          return mantissa * (10 ^ exponent)
        end
      end
      if #den_str > #num_str + 15 then
        local sig_digits = 15
        local num_significant = string.sub(num_str:gsub("^%-", ""), 1, math.min(sig_digits, #num_str))
        local den_significant = string.sub(den_str:gsub("^%-", ""), 1, math.min(sig_digits, #den_str))
        if #num_str < sig_digits then
          num_significant = num_significant .. string.rep("0", sig_digits - #num_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = (#den_str - #num_str) - (sig_digits - math.min(sig_digits, #num_str))
          return mantissa / (10 ^ exponent)
        end
      end
      local max_safe_digits = 15
      if #num_str > max_safe_digits or #den_str > max_safe_digits then
        local total_digits = #num_str + #den_str
        local excess = total_digits - (2 * max_safe_digits)
        if excess > 0 then
          local num_truncate = math.floor(excess * (#num_str / total_digits))
          local den_truncate = excess - num_truncate
          num_truncate = math.min(num_truncate, #num_str - 1)
          den_truncate = math.min(den_truncate, #den_str - 1)
          local truncated_num = string.sub(num_str, 1, #num_str - num_truncate)
          local truncated_den = string.sub(den_str, 1, #den_str - den_truncate)
          local num_val = tonumber(truncated_num)
          local den_val = tonumber(truncated_den)
          if num_val and den_val and den_val ~= 0 then
            result = num_val / den_val
            local scale = 10 ^ (num_truncate - den_truncate)
            return result / scale
          end
        end
      end
      local num_val = tonumber(num_str)
      local den_val = tonumber(den_str)
      if num_val and den_val and den_val ~= 0 then
        return num_val / den_val
      end
      local magnitude_diff = #num_str - #den_str
      if magnitude_diff > 0 then
        return 1.0 * (10 ^ magnitude_diff)
      elseif magnitude_diff < 0 then
        return 1.0 / (10 ^ -magnitude_diff)
      else
        local first_num = tonumber(string.sub(num_str, 1, 1)) or 1
        local first_den = tonumber(string.sub(den_str, 1, 1)) or 1
        if first_den > 0 then
          return first_num / first_den
        else
          return math.huge
        end
      end
    end,
    to_number_annotated = function(self)
      local val = self:to_number()
      local num_digits = #tostring(self.num)
      local den_digits = #tostring(self.den)
      local max_digits = math.max(num_digits, den_digits)
      local est_loss = max_digits > 15 and ("~" .. (max_digits - 15) .. " digits lost") or "~0 digits lost"
      return val, est_loss
    end,
    safe_to_number = function(self)
      local num = nil
      local ok = pcall(function()
        num = self:to_number()
      end)
      if num and num == num then
        return num
      else
        return nil
      end
    end,
    to_approximate_float = function(self)
      local num_str = tostring(self.num)
      local den_str = tostring(self.den)
      local max_digits = math.max(#num_str, #den_str)
      local digits_lost = max_digits > 15 and max_digits - 15 or 0
      local result = self:to_number_for_display()
      if result and result == result and result ~= math.huge and result ~= -math.huge and result ~= 0 then
        return result, digits_lost
      end
      if #num_str > #den_str + 5 then
        local magnitude_diff = #num_str - #den_str
        local sig_digits = 6
        local num_significant = string.sub(num_str:gsub("^%-", ""), 1, math.min(sig_digits, #num_str))
        local den_significant = string.sub(den_str:gsub("^%-", ""), 1, math.min(sig_digits, #den_str))
        if #den_str < sig_digits then
          den_significant = den_significant .. string.rep("0", sig_digits - #den_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = magnitude_diff - (sig_digits - math.min(sig_digits, #den_str))
          return mantissa * (10 ^ exponent), max_digits
        end
      end
      if #den_str > #num_str + 5 then
        local magnitude_diff = #den_str - #num_str
        local sig_digits = 6
        local num_significant = string.sub(num_str:gsub("^%-", ""), 1, math.min(sig_digits, #num_str))
        local den_significant = string.sub(den_str:gsub("^%-", ""), 1, math.min(sig_digits, #den_str))
        if #num_str < sig_digits then
          num_significant = num_significant .. string.rep("0", sig_digits - #num_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = magnitude_diff - (sig_digits - math.min(sig_digits, #num_str))
          return mantissa / (10 ^ exponent), max_digits
        end
      end
      if max_digits > 15 then
        local excess_digits = max_digits - 15
        local num_truncate = math.min(#num_str - 1, math.ceil(excess_digits * (#num_str / max_digits)))
        local den_truncate = math.min(#den_str - 1, excess_digits - num_truncate)
        local truncated_num = string.sub(num_str, 1, #num_str - num_truncate)
        local truncated_den = string.sub(den_str, 1, #den_str - den_truncate)
        local truncated = Fractional(tostring(truncated_num) .. "/" .. tostring(truncated_den))
        local approximation = truncated:safe_to_number()
        if approximation and approximation ~= math.huge and approximation ~= -math.huge and approximation ~= 0 then
          local scale_factor = 10 ^ (num_truncate - den_truncate)
          return approximation / scale_factor, num_truncate + den_truncate
        end
      end
      local magnitude_diff = #num_str - #den_str
      if magnitude_diff > 0 then
        return 1.0 * (10 ^ magnitude_diff), max_digits
      elseif magnitude_diff < 0 then
        return 1.0 / (10 ^ -magnitude_diff), max_digits
      else
        local num_first = tonumber(string.sub(num_str, 1, 1)) or 1
        local den_first = tonumber(string.sub(den_str, 1, 1)) or 1
        if den_first > 0 then
          return num_first / den_first, max_digits
        end
      end
      return nil, nil
    end,
    _format_large_number = function(self, str)
      if #str <= 5 then
        return str
      end
      local first_digits = string.sub(str, 1, 5)
      return tostring(first_digits) .. "...e" .. tostring(#str - 5)
    end,
    format = function(self, prefix, decimal_places)
      if prefix == nil then
        prefix = ""
      end
      if decimal_places == nil then
        decimal_places = 2
      end
      local num_str = tostring(self.num)
      local den_str = tostring(self.den)
      if den_str == "0" then
        return tostring(prefix) .. "Infinity"
      end
      if num_str == "0" or num_str == "-0" then
        return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f", 0.0)
      end
      local extract_significant
      extract_significant = function(value_str, sign_prefix, limit)
        if sign_prefix == nil then
          sign_prefix = ""
        end
        if limit == nil then
          limit = 6
        end
        local digits = value_str:gsub("^%-", "")
        local significant = string.sub(digits, 1, math.min(limit, #digits))
        if value_str:match("^%-") then
          return sign_prefix .. significant
        else
          return significant
        end
      end
      if #num_str > #den_str + 10 then
        local magnitude = #num_str - #den_str
        local sig_digits = 6
        local num_significant = extract_significant(num_str, "", sig_digits)
        local den_significant = extract_significant(den_str, "", sig_digits)
        if #den_str < sig_digits then
          den_significant = den_significant .. string.rep("0", sig_digits - #den_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = magnitude - (sig_digits - math.min(sig_digits, #den_str))
          return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f × 10^%d", mantissa, exponent)
        else
          return string.format(tostring(prefix) .. "~10^%d (very large)", magnitude)
        end
      end
      if #den_str > #num_str + 10 then
        local magnitude = #den_str - #num_str
        local sig_digits = 6
        local num_significant = extract_significant(num_str, "", sig_digits)
        local den_significant = extract_significant(den_str, "", sig_digits)
        if #num_str < sig_digits then
          num_significant = num_significant .. string.rep("0", sig_digits - #num_str)
        end
        local num_val = tonumber(num_significant)
        local den_val = tonumber(den_significant)
        if num_val and den_val and den_val > 0 then
          local mantissa = num_val / den_val
          local exponent = magnitude - (sig_digits - math.min(sig_digits, #num_str))
          return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f × 10^-%d", mantissa, exponent)
        else
          return string.format(tostring(prefix) .. "~10^-%d (very small)", magnitude)
        end
      end
      local max_proc_digits = 12
      local num_digits = #num_str:gsub("^%-", "")
      local den_digits = #den_str:gsub("^%-", "")
      if num_digits > max_proc_digits or den_digits > max_proc_digits then
        local total_excess = (num_digits + den_digits) - (2 * max_proc_digits)
        local num_truncate = math.floor(total_excess * (num_digits / (num_digits + den_digits)))
        local den_truncate = total_excess - num_truncate
        if num_digits - num_truncate < 4 then
          num_truncate = num_digits - 4
          num_truncate = math.max(0, num_truncate)
        end
        if den_digits - den_truncate < 4 then
          den_truncate = den_digits - 4
          den_truncate = math.max(0, den_truncate)
        end
        local num_prefix
        if num_str:match("^%-") then
          num_prefix = "-" .. string.sub(num_str:gsub("^%-", ""), 1, num_digits - num_truncate)
        else
          num_prefix = string.sub(num_str, 1, num_digits - num_truncate)
        end
        local den_prefix
        if den_str:match("^%-") then
          den_prefix = "-" .. string.sub(den_str:gsub("^%-", ""), 1, den_digits - den_truncate)
        else
          den_prefix = string.sub(den_str, 1, den_digits - den_truncate)
        end
        local num_val = tonumber(num_prefix)
        local den_val = tonumber(den_prefix)
        if num_val and den_val and den_val ~= 0 then
          local ratio = num_val / den_val
          local scale_factor = 10 ^ (num_truncate - den_truncate)
          ratio = ratio / scale_factor
          local total_truncated = num_truncate + den_truncate
          return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f (approx, truncated %d digits)", ratio, total_truncated)
        else
          local magnitude_diff = num_digits - den_digits
          if magnitude_diff > 0 then
            return string.format(tostring(prefix) .. "~10^%d (large)", magnitude_diff)
          elseif magnitude_diff < 0 then
            return string.format(tostring(prefix) .. "~10^-%d (small)", -magnitude_diff)
          else
            local num_short = string.sub(num_str, 1, math.min(6, #num_str))
            local den_short = string.sub(den_str, 1, math.min(6, #den_str))
            if #num_str > 6 then
              num_short = tostring(num_short) .. "..."
            end
            if #den_str > 6 then
              den_short = tostring(den_short) .. "..."
            end
            return tostring(prefix) .. tostring(num_short) .. "/" .. tostring(den_short)
          end
        end
      else
        local val = self:to_number_for_display()
        if val and val == val and val ~= math.huge and val ~= -math.huge and val ~= 0 then
          return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f", val)
        end
        val = self:safe_to_number()
        if val and val == val and val ~= math.huge and val ~= -math.huge and val ~= 0 then
          return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f", val)
        end
        local magnitude_diff = num_digits - den_digits
        if magnitude_diff > 0 then
          return string.format(tostring(prefix) .. "~10^%d (large)", magnitude_diff)
        elseif magnitude_diff < 0 then
          return string.format(tostring(prefix) .. "~10^-%d (small)", -magnitude_diff)
        else
          local num_val = tonumber(num_str)
          local den_val = tonumber(den_str)
          if num_val and den_val and den_val ~= 0 then
            local ratio = num_val / den_val
            return string.format(tostring(prefix) .. "%." .. tostring(decimal_places) .. "f", ratio)
          else
            return tostring(prefix) .. tostring(num_str) .. "/" .. tostring(den_str)
          end
        end
      end
    end,
    format_money = function(self)
      return self:format("$", 2)
    end,
    _binop = function(self, other, op)
      if not (Fractional:is_instance(other)) then
        other = Fractional(other)
      end
      local result = Fractional(0)
      local _exp_0 = op
      if "add" == _exp_0 then
        result.num = (self.num * other.den) + (self.den * other.num)
        result.den = self.den * other.den
      elseif "sub" == _exp_0 then
        result.num = (self.num * other.den) - (self.den * other.num)
        result.den = self.den * other.den
      elseif "mul" == _exp_0 then
        result.num = self.num * other.num
        result.den = self.den * other.den
      elseif "div" == _exp_0 then
        if other.num == Bignum(0) then
          error("Division by zero")
        end
        result.num = self.num * other.den
        result.den = self.den * other.num
      end
      result:_quick_reduce()
      local operation_count = self.operations_since_reduction + other.operations_since_reduction + 1
      result.operations_since_reduction = operation_count
      local when_reduce = result.operations_since_reduction >= result.reduction_threshold
      if when_reduce then
        result:_reduce()
      end
      return result
    end,
    __add = function(self, other)
      return self:_binop(other, "add")
    end,
    __sub = function(self, other)
      return self:_binop(other, "sub")
    end,
    __mul = function(self, other)
      return self:_binop(other, "mul")
    end,
    __div = function(self, other)
      return self:_binop(other, "div")
    end,
    __unm = function(self)
      local result = Fractional(0)
      result.num = -self.num
      result.den = self.den
      return result
    end,
    __eq = function(self, other)
      if not (Fractional:is_instance(other)) then
        other = Fractional(other)
      end
      self:_reduce()
      other:_reduce()
      return self.num == other.num and self.den == other.den
    end,
    __lt = function(self, other)
      if not (Fractional:is_instance(other)) then
        other = Fractional(other)
      end
      return (self.num * other.den) < (self.den * other.num)
    end,
    __le = function(self, other)
      if not (Fractional:is_instance(other)) then
        other = Fractional(other)
      end
      return (self.num * other.den) <= (self.den * other.num)
    end,
    pow = function(self, exponent)
      if type(exponent) ~= "number" or exponent < 0 or exponent % 1 ~= 0 then
        error("Exponent must be a non-negative integer")
      end
      local result = Fractional(0)
      if exponent == 0 then
        result.num = Bignum(1)
        result.den = Bignum(1)
      else
        result.num = self.num:pow(exponent)
        result.den = self.den:pow(exponent)
      end
      return result
    end,
    __pow = function(self, exp)
      return self:pow(exp)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, input, denominator)
      if input == nil then
        input = 0
      end
      if denominator == nil then
        denominator = nil
      end
      self.operations_since_reduction = 0
      self.reduction_threshold = 10
      local _exp_0 = type(input)
      if "string" == _exp_0 then
        return self:_init_from_string(input)
      elseif "number" == _exp_0 then
        if denominator == nil then
          if input % 1 == 0 then
            return self:_init_from_integers(input, 1)
          else
            return self:_init_from_float(input)
          end
        else
          return self:_init_from_integers(input, denominator)
        end
      elseif "table" == _exp_0 then
        if input.__class == Fractional then
          self.num = input.num
          self.den = input.den
          self.operations_since_reduction = input.operations_since_reduction
          self.reduction_threshold = input.reduction_threshold
        else
          return error("Cannot initialize Fractional with table that is not a Fractional")
        end
      else
        return error("Unsupported Fractional input type")
      end
    end,
    __base = _base_0,
    __name = "Fractional"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.is_instance = function(self, val)
    return type(val) == "table" and val.__class == Fractional
  end
  Fractional = _class_0
end
if arg and arg[0] and arg[1] == "--test" then
  local script_path = debug.getinfo(1, "S").source:match("^@(.*/)")
  package.path = script_path .. "?.lua;" .. script_path .. "?.moon;" .. package.path
  local cli_utils = require("cli_utils")
  local tf = cli_utils.assert_factory()
  local F = Fractional
  tf.assert(F("3/4"):tostring() == "3/4", "String initialization works")
  tf.assert(F(3, 4):tostring() == "3/4", "Two-arg initialization works")
  tf.assert(F(1.5):tostring() == "3/2", "Float initialization works")
  tf.assert(F(6, 8):tostring() == "3/4", "Fraction is reduced when converted to string")
  tf.assert(F(10, 15):tostring() == "2/3", "GCD reduction works")
  tf.assert((F("1/2") + F("1/4")):tostring() == "3/4", "Addition works")
  tf.assert((F("3/4") - F("1/4")):tostring() == "1/2", "Subtraction works")
  tf.assert((F("2/3") * F("3/4")):tostring() == "1/2", "Multiplication works")
  tf.assert((F("2/3") / F("3/4")):tostring() == "8/9", "Division works")
  tf.assert(F("1/2") == F("2/4"), "Equality comparison works")
  tf.assert(F("1/3") < F("1/2"), "Less than comparison works")
  tf.assert(F("2/3") > F("1/2"), "Greater than comparison works")
  tf.assert(F("1/2") <= F("1/2"), "Less than or equal works")
  tf.assert(F("1/2") >= F("1/2"), "Greater than or equal works")
  tf.assert((-F("3/4")):tostring() == "-3/4", "Negation works")
  tf.assert(F("-3/4"):tostring() == "-3/4", "Negative string initialization works")
  local f, note = F("22/7"):to_number_annotated()
  tf.assert(type(f) == "number", "Float conversion returns a number")
  tf.assert(math.abs(f - 3.14285714285714) < 0.0000001, "Float conversion has correct value")
  tf.assert(type(note) == "string", "Precision loss note is a string")
  tf.assert((F("2/3") ^ 2):tostring() == "4/9", "Exponentiation works")
  tf.assert((F("1/2") ^ 0):tostring() == "1/1", "Exponentiation with zero works")
  local complex = F("60/75")
  complex:set_reduction_threshold(100)
  tf.assert(complex.reduction_threshold == 100, "Setting reduction threshold works")
  local unreduced = F(0)
  unreduced.num = Bignum(10)
  unreduced.den = Bignum(20)
  unreduced.operations_since_reduction = 0
  unreduced.reduction_threshold = 3
  for i = 1, 3 do
    unreduced = unreduced + F(0)
  end
  tf.assert(unreduced.num:tostring() == "1", "Auto-reduction reduces numerator correctly")
  tf.assert(unreduced.den:tostring() == "2", "Auto-reduction reduces denominator correctly")
  io.stderr:write("Fractional tests completed. Failures: " .. tostring(tf.fails()) .. "\n")
  os.exit(tf.fails())
end
return Fractional
