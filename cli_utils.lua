local ffi = require("ffi")
ffi.cdef([[	typedef long time_t;
	typedef struct timeval {
		time_t tv_sec;
		time_t tv_usec;
	} timeval;
	int gettimeofday(struct timeval* tv, void* tz);
]])
local seed_rng
seed_rng = function()
	local tv = ffi.new("timeval")
	ffi.C.gettimeofday(tv, nil)
	local sec = tonumber(tv.tv_sec)
	local usec = tonumber(tv.tv_usec)
	math.randomseed(sec * 1e6 + usec)
	return nil
end
local assert_factory
assert_factory = function(writer)
	if writer == nil then
		do
			local _base_0 = io.stderr
			local _fn_0 = _base_0.write
			writer = _fn_0 and function(...)
				return _fn_0(_base_0, ...)
			end
		end
	end
	local fails = 0
	local passes = 0
	local assert
	assert = function(expr, msg)
		if msg == nil then
			msg = "Assertion failed"
		end
		if expr then
			passes = passes + 1
		else
			writer("FAIL: " .. tostring(msg) .. "\n")
			fails = fails + 1
		end
	end
	local refute
	refute = function(expr, msg)
		if msg == nil then
			msg = "Refutation failed"
		end
		if not expr then
			passes = passes + 1
		else
			writer("FAIL: " .. tostring(msg) .. "\n")
			fails = fails + 1
		end
	end
	local assert_equal
	assert_equal = function(expected, actual, msg, comparison)
		if comparison == nil then
			comparison = "Expected " .. tostring(expected) .. " but got " .. tostring(actual)
		end
		if expected == actual then
			passes = passes + 1
		else
			writer("FAIL: " .. tostring(msg) .. ": " .. tostring(comparison) .. "\n")
			fails = fails + 1
		end
	end
	local refute_equal
	refute_equal = function(unexpected, actual, msg, comparison)
		if comparison == nil then
			comparison = "Expected " .. tostring(actual) .. " not to be " .. tostring(unexpected)
		end
		if unexpected ~= actual then
			passes = passes + 1
		else
			writer("FAIL: " .. tostring(msg) .. ": " .. tostring(comparison) .. "\n")
			fails = fails + 1
		end
	end
	local assert_raise
	assert_raise = function(func, expected_err_pattern, msg)
		if expected_err_pattern == nil then
			expected_err_pattern = nil
		end
		if msg == nil then
			msg = "Expected error was not raised"
		end
		local success, err = pcall(func)
		if not success then
			if expected_err_pattern then
				if type(err) == "string" and err:match(expected_err_pattern) then
					passes = passes + 1
				else
					writer("FAIL: Error raised but didn't match pattern. Got: " .. tostring(err) .. "\n")
					fails = fails + 1
				end
			else
				passes = passes + 1
			end
		else
			writer("FAIL: " .. tostring(msg) .. "\n")
			fails = fails + 1
		end
	end
	local refute_raise
	refute_raise = function(func, msg)
		if msg == nil then
			msg = "Unexpected error was raised"
		end
		local success, err = pcall(func)
		if success then
			passes = passes + 1
		else
			writer("FAIL: " .. tostring(msg) .. ". Error: " .. tostring(err) .. "\n")
			fails = fails + 1
		end
	end
	return {
		assert = assert,
		refute = refute,
		assert_equal = assert_equal,
		refute_equal = refute_equal,
		assert_raise = assert_raise,
		refute_raise = refute_raise,
		fails = function()
			return fails
		end,
		passes = function()
			return passes
		end,
		summary = function()
			return "Tests completed. Passes: " .. tostring(passes) .. ", Failures: " .. tostring(fails)
		end
	}
end
local default_validator
default_validator = function()
	return true
end
local parse_args
parse_args = function(config, argv)
	if argv == nil then
		argv = arg
	end
	local options = { }
	local positionals = { }
	local helptext = { }
	local spec_by_flag = { }
	for _index_0 = 1, #config do
		local entry = config[_index_0]
		local _list_0 = entry.flags
		for _index_1 = 1, #_list_0 do
			local flag = _list_0[_index_1]
			spec_by_flag[flag] = entry
		end
		if entry.description then
			helptext[#helptext + 1] = table.concat(entry.flags, ", ") .. "\t" .. entry.description
		end
	end
	local i = 1
	while i <= #argv do
		local token = argv[i]
		if token == "-h" or token == "--help" then
			print("Usage:")
			for _index_0 = 1, #helptext do
				local line = helptext[_index_0]
				print("  ", line)
			end
			os.exit(0)
		end
		local entry = spec_by_flag[token]
		if entry then
			if entry.has_arg then
				i = i + 1
				local argval = argv[i]
				if not argval then
					io.stderr:write("Missing argument for " .. tostring(token) .. "\n")
					os.exit(1)
				end
				local validator = entry.validator or default_validator
				if not validator(argval) then
					io.stderr:write("Invalid argument for " .. tostring(token) .. ": " .. tostring(argval) .. "\n")
					os.exit(2)
				end
				options[entry.name] = argval
			else
				options[entry.name] = true
			end
		else
			positionals[#positionals + 1] = token
		end
		i = i + 1
	end
	return {
		options,
		positionals
	}
end
if arg and arg[0] and arg[1] == "--test" and arg[0]:match("cli_utils") then
	local script_path = arg[0]:match("(.*/)")
	if not script_path or script_path == "" then
		script_path = "./"
	end
	package.path = script_path .. "?.lua;" .. script_path .. "?.yue;" .. package.path
	local tf = assert_factory()
	local seed_result = seed_rng()
	tf.assert_equal(nil, seed_result, "seed_rng should return nil")
	local factory = assert_factory()
	tf.assert_equal("table", type(factory), "assert_factory should return a table")
	tf.assert_equal("function", type(factory.assert), "factory should have an assert function")
	tf.assert_equal("function", type(factory.refute), "factory should have a refute function")
	tf.assert_equal("function", type(factory.assert_equal), "factory should have an assert_equal function")
	tf.assert_equal("function", type(factory.refute_equal), "factory should have a refute_equal function")
	tf.assert_equal("function", type(factory.assert_raise), "factory should have an assert_raise function")
	tf.assert_equal("function", type(factory.refute_raise), "factory should have a refute_raise function")
	tf.assert_equal("function", type(factory.fails), "factory should have a fails function")
	tf.assert_equal(0, factory.fails(), "New factory should have 0 failures")
	local null_writer
	null_writer = function(msg)
		return nil
	end
	local test_factory = assert_factory(null_writer)
	test_factory.refute(false, "This should pass")
	test_factory.refute(true, "This should fail")
	tf.assert_equal(1, test_factory.passes(), "refute should count passes")
	tf.assert_equal(1, test_factory.fails(), "refute should count failures")
	test_factory = assert_factory(null_writer)
	test_factory.assert_equal(42, 42, "This should pass")
	test_factory.assert_equal(42, 43, "This should fail")
	tf.assert_equal(1, test_factory.passes(), "assert_equal should count passes")
	tf.assert_equal(1, test_factory.fails(), "assert_equal should count failures")
	test_factory = assert_factory(null_writer)
	test_factory.refute_equal(42, 43, "This should pass")
	test_factory.refute_equal(42, 42, "This should fail")
	tf.assert_equal(1, test_factory.passes(), "refute_equal should count passes")
	tf.assert_equal(1, test_factory.fails(), "refute_equal should count failures")
	test_factory = assert_factory(null_writer)
	test_factory.assert_raise((function()
		return error("test error")
	end), nil, "This should pass")
	test_factory.assert_raise((function()
		return nil
	end), nil, "This should fail")
	tf.assert_equal(1, test_factory.passes(), "assert_raise should count passes")
	tf.assert_equal(1, test_factory.fails(), "assert_raise should count failures")
	test_factory = assert_factory(null_writer)
	test_factory.assert_raise((function()
		return error("test error")
	end), "test", "This should pass")
	test_factory.assert_raise((function()
		return error("wrong error")
	end), "test", "This should fail")
	tf.assert_equal(1, test_factory.passes(), "assert_raise with pattern should count passes")
	tf.assert_equal(1, test_factory.fails(), "assert_raise with pattern should count failures")
	test_factory = assert_factory(null_writer)
	test_factory.refute_raise((function()
		return nil
	end), "This should pass")
	test_factory.refute_raise((function()
		return error("test error")
	end), "This should fail")
	tf.assert_equal(1, test_factory.passes(), "refute_raise should count passes")
	tf.assert_equal(1, test_factory.fails(), "refute_raise should count failures")
	null_writer = function(msg)
		return nil
	end
	local expected_failing_factory = assert_factory(null_writer)
	expected_failing_factory.assert(false, "This should fail")
	tf.assert_equal(1, expected_failing_factory.fails(), "Factory should count failures")
	local config = {
		{
			name = "verbose",
			flags = {
				"-v",
				"--verbose"
			},
			has_arg = false,
			description = "Enable verbose mode"
		},
		{
			name = "file",
			flags = {
				"-f",
				"--file"
			},
			has_arg = true,
			description = "Path to input file"
		}
	}
	local result = parse_args(config, { })
	tf.assert_equal("table", type(result), "parse_args should return a table")
	tf.assert_equal("table", type(result[1]), "parse_args should return options table")
	tf.assert_equal("table", type(result[2]), "parse_args should return positionals table")
	tf.assert_equal(0, #result[2], "No positional args expected")
	result = parse_args(config, {
		"-v"
	})
	tf.assert_equal(true, result[1].verbose, "Verbose flag should be set")
	result = parse_args(config, {
		"--verbose"
	})
	tf.assert_equal(true, result[1].verbose, "Long verbose flag should be set")
	result = parse_args(config, {
		"-f",
		"test.txt"
	})
	tf.assert_equal("test.txt", result[1].file, "File argument should be set")
	result = parse_args(config, {
		"--file",
		"test.txt"
	})
	tf.assert_equal("test.txt", result[1].file, "Long file argument should be set")
	result = parse_args(config, {
		"pos1",
		"pos2"
	})
	tf.assert_equal(2, #result[2], "Should have 2 positional args")
	tf.assert_equal("pos1", result[2][1], "First positional arg should be correct")
	tf.assert_equal("pos2", result[2][2], "Second positional arg should be correct")
	result = parse_args(config, {
		"-v",
		"pos1",
		"-f",
		"test.txt",
		"pos2"
	})
	tf.assert_equal(true, result[1].verbose, "Verbose flag should be set")
	tf.assert_equal("test.txt", result[1].file, "File argument should be set")
	tf.assert_equal(2, #result[2], "Should have 2 positional args")
	tf.assert_equal("pos1", result[2][1], "First positional arg should be correct")
	tf.assert_equal("pos2", result[2][2], "Second positional arg should be correct")
	local config_with_validator = {
		{
			name = "number",
			flags = {
				"-n",
				"--number"
			},
			has_arg = true,
			description = "A number",
			validator = function(n)
				return tonumber(n) ~= nil
			end
		}
	}
	result = parse_args(config_with_validator, {
		"-n",
		"42"
	})
	tf.assert_equal("42", result[1].number, "Number argument should be set")
	local config_with_desc = {
		{
			name = "verbose",
			flags = {
				"-v",
				"--verbose"
			},
			has_arg = false,
			description = "Enable verbose mode"
		},
		{
			name = "file",
			flags = {
				"-f",
				"--file"
			},
			has_arg = true,
			description = "Path to input file"
		}
	}
	local helptext = { }
	for _index_0 = 1, #config_with_desc do
		local entry = config_with_desc[_index_0]
		if entry.description then
			helptext[#helptext + 1] = table.concat(entry.flags, ", ") .. "\t" .. entry.description
		end
	end
	tf.assert(#helptext >= 2, "Help table should have at least 2 entries")
	local help_output = {
		"Usage:"
	}
	for _index_0 = 1, #helptext do
		local line = helptext[_index_0]
		help_output[#help_output + 1] = "  " .. line
	end
	tf.assert(#help_output >= 3, "Help output should have at least 3 lines")
	tf.assert_equal("Usage:", help_output[1], "Help output should start with 'Usage:'")
	io.stderr:write(tostring(tf.summary()) .. "\n")
	os.exit(tf.fails())
end
return {
	seed_rng = seed_rng,
	assert_factory = assert_factory,
	parse_args = parse_args
}
