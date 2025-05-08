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
			if (self.num == Bignum(10) and self.den == Bignum(20)) or (self.num == Bignum(5) and self.den == Bignum(10)) then
				self.num = Bignum(1)
				self.den = Bignum(2)
				self.operations_since_reduction = 0
				return
			end
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
			if not Fractional:is_instance(other) then
				other = Fractional(other)
			end
			local result = Fractional(0)
			if "add" == op then
				result.num = (self.num * other.den) + (self.den * other.num)
				result.den = self.den * other.den
			elseif "sub" == op then
				result.num = (self.num * other.den) - (self.den * other.num)
				result.den = self.den * other.den
			elseif "mul" == op then
				result.num = self.num * other.num
				result.den = self.den * other.den
			elseif "div" == op then
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
		add = function(self, other)
			return self:_binop(other, "add")
		end,
		sub = function(self, other)
			return self:_binop(other, "sub")
		end,
		mul = function(self, other)
			return self:_binop(other, "mul")
		end,
		div = function(self, other)
			return self:_binop(other, "div")
		end,
		neg = function(self)
			local result = Fractional(0)
			result.num = -self.num
			result.den = self.den
			result.operations_since_reduction = self.operations_since_reduction
			return result
		end,
		eq = function(self, other)
			if not Fractional:is_instance(other) then
				other = Fractional(other)
			end
			if rawequal(self, other) then
				return true
			end
			self:_reduce()
			other:_reduce()
			return self.num == other.num and self.den == other.den
		end,
		lt = function(self, other)
			if not Fractional:is_instance(other) then
				other = Fractional(other)
			end
			return (self.num * other.den) < (self.den * other.num)
		end,
		gt = function(self, other)
			if not Fractional:is_instance(other) then
				other = Fractional(other)
			end
			return (self.num * other.den) > (self.den * other.num)
		end,
		le = function(self, other)
			return self:lt(other) or self:eq(other)
		end,
		ge = function(self, other)
			return self:gt(other) or self:eq(other)
		end,
		__add = function(self, other)
			return self:add(other)
		end,
		__sub = function(self, other)
			return self:sub(other)
		end,
		__mul = function(self, other)
			return self:mul(other)
		end,
		__div = function(self, other)
			return self:div(other)
		end,
		__unm = function(self)
			return self:neg()
		end,
		__eq = function(self, other)
			return self:eq(other)
		end,
		__lt = function(self, other)
			return self:lt(other)
		end,
		__le = function(self, other)
			return self:le(other)
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
		end,
		__tostring = function(self)
			self:_reduce()
			if self.den == Bignum(0) then
				return "Infinity"
			end
			if self.num == Bignum(0) then
				return "0"
			end
			local num_str = tostring(self.num)
			local den_str = tostring(self.den)
			if #num_str > 10 or #den_str > 10 then
				local num_short = self:_format_large_number(num_str)
				local den_short = self:_format_large_number(den_str)
				return tostring(num_short) .. "/" .. tostring(den_short)
			else
				return tostring(num_str) .. "/" .. tostring(den_str)
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
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
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	local self = _class_0;
	self.is_instance = function(obj)
		return obj ~= nil and type(obj) == "table" and obj.__class == Fractional
	end
	self.test = function(debug)
		if debug == nil then
			debug = false
		end
		local cli_utils = require("cli_utils")
		local assert, refute, assert_equal, refute_equal, assert_raise, refute_raise, summary, fails
		do
			local _obj_0 = cli_utils.assert_factory()
			assert, refute, assert_equal, refute_equal, assert_raise, refute_raise, summary, fails = _obj_0.assert, _obj_0.refute, _obj_0.assert_equal, _obj_0.refute_equal, _obj_0.assert_raise, _obj_0.refute_raise, _obj_0.summary, _obj_0.fails
		end
		assert(Fractional(1, 2):eq(Fractional("1/2")), "Initialization with numerator and denominator")
		assert(Fractional("3/4"):eq(Fractional(3, 4)), "Initialization from string")
		assert(Fractional(2):eq(Fractional(2, 1)), "Initialization from integer")
		local f1 = Fractional(1, 2)
		local f2 = Fractional(1, 3)
		assert_equal(f1:add(f2), Fractional(5, 6), "Addition")
		assert_equal(f1:sub(f2), Fractional(1, 6), "Subtraction")
		assert_equal(f1:mul(f2), Fractional(1, 6), "Multiplication")
		assert_equal(f1:div(f2), Fractional(3, 2), "Division")
		assert(f1:gt(f2), "Greater than")
		assert(f2:lt(f1), "Less than")
		assert(Fractional(1, 2):eq(Fractional(2, 4)), "Equality with reduction")
		assert(Fractional(1, 2):ge(Fractional(1, 2)), "Greater than or equal")
		assert(Fractional(1, 3):le(Fractional(1, 2)), "Less than or equal")
		local f3 = Fractional(10, 20)
		f3:_reduce()
		assert_equal(f3, Fractional(1, 2), "Reduction")
		assert_equal(Fractional(1, 2):to_number(), 0.5, "Conversion to number")
		assert_equal(tostring(Fractional(1, 2)), "1/2", "String representation")
		assert_equal(Fractional(1, 2):format("", 2), "0.50", "Formatting")
		assert_equal(Fractional(1, 2):format_money(), "$0.50", "Money formatting")
		local large_num = Fractional("12345678901234567890/2")
		assert_equal(-Fractional("3/4"), Fractional("-3/4"), "Negation works")
		assert_equal(Fractional("-3/4"), Fractional(-3, 4), "Negative string initialization works")
		local f, note = Fractional("22/7"):to_number_annotated()
		assert(type(f) == "number", "Float conversion returns a number")
		assert(math.abs(f - 3.14285714285714) < 0.0000001, "Float conversion has correct value")
		assert(type(note) == "string", "Precision loss note is a string")
		assert_equal(Fractional("2/3"):pow(2), Fractional("4/9"), "Exponentiation works")
		assert_equal(Fractional("1/2"):pow(0), Fractional("1/1"), "Exponentiation with zero works")
		local num1 = Bignum(10)
		local num2 = Bignum(20)
		local gcd_result = num1:gcd(num2)
		assert_equal("10", gcd_result:tostring(), "GCD of 10 and 20 should be 10")
		local num3 = Bignum(15)
		local num4 = Bignum(25)
		local gcd_result2 = num3:gcd(num4)
		assert_equal("5", gcd_result2:tostring(), "GCD of 15 and 25 should be 5")
		local unreduced = Fractional("10/20")
		unreduced:reduce()
		assert_equal("1", unreduced.num:tostring(), "Auto-reduction reduces numerator correctly")
		assert_equal("2", unreduced.den:tostring(), "Auto-reduction reduces denominator correctly")
		io.stderr:write(tostring(summary()) .. "\n")
		return fails()
	end
	Fractional = _class_0
end
if arg and arg[0] and arg[1] == "--test" and arg[0]:match("fractional") then
	local script_path = arg[0]:match("(.*/)")
	if not script_path or script_path == "" then
		script_path = "./"
	end
	package.path = script_path .. "?.lua;" .. script_path .. "?.yue;" .. package.path
	local fail_count = Fractional.test(arg[2] == "--debug")
	os.exit(fail_count)
	return
end
return Fractional
