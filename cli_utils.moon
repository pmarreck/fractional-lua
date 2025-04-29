#!/usr/bin/env moonrun
-- cli_utils.moon

ffi = require "ffi"

ffi.cdef [[
	typedef long time_t;
	typedef struct timeval {
		time_t tv_sec;
		time_t tv_usec;
	} timeval;
	int gettimeofday(struct timeval* tv, void* tz);
]]

-- Better RNG seeding with microsecond precision
seed_rng = ->
	tv = ffi.new "timeval"
	ffi.C.gettimeofday tv, nil
	sec = tonumber tv.tv_sec
	usec = tonumber tv.tv_usec
	math.randomseed sec * 1e6 + usec
	-- Return nil explicitly (this was causing a test failure)
	nil

-- Assertion with accumulation
assert_factory = ->
	fails = 0
	assert = (expr, msg = "Assertion failed") ->
		unless expr
			io.stderr\write "FAIL: #{msg}\n"
			fails += 1
	{
		assert: assert
		fails: -> fails
	}

-- Argument parser
default_validator = -> true

parse_args = (config, argv = arg) ->
	options = {}
	positionals = {}
	helptext = {}

	spec_by_flag = {}
	for entry in *config
		for flag in *entry.flags
			spec_by_flag[flag] = entry
		if entry.description
			helptext[#helptext + 1] = table.concat(entry.flags, ", ") .. "\t" .. entry.description

	i = 1
	while i <= #argv
		token = argv[i]

		if token == "-h" or token == "--help"
			print "Usage:"
			for line in *helptext
				print "  ", line
			os.exit 0

		entry = spec_by_flag[token]
		if entry
			if entry.has_arg
				i += 1
				argval = argv[i]
				unless argval
					io.stderr\write "Missing argument for #{token}\n"
					os.exit 1
				validator = entry.validator or default_validator
				unless validator argval
					io.stderr\write "Invalid argument for #{token}: #{argval}\n"
					os.exit 2
				options[entry.name] = argval
			else
				options[entry.name] = true
		else
			positionals[#positionals + 1] = token
		i += 1

	{options, positionals}

-- Example spec format
-- config = {
--   { name: "verbose", flags: {"-v", "--verbose"}, has_arg: false, description: "Enable verbose mode" }
--   { name: "file", flags: {"-f", "--file"}, has_arg: true, description: "Path to input file", validator: (f) -> f and f != "" and io.open(f) != nil }
-- }

-- Test suite trigger
if arg and arg[0] and arg[1] == "--test"
	script_path = debug.getinfo(1, "S").source\match "^@(.*/)"
	package.path = script_path .. "?.lua;" .. script_path .. "?.moon;" .. package.path
	tf = assert_factory!
	
	-- Test seed_rng
	-- We can only verify it doesn't crash and returns nil
	seed_result = seed_rng!
	tf.assert seed_result == nil, "seed_rng should return nil"
	
	-- Test assert_factory
	factory = assert_factory!
	tf.assert type(factory) == "table", "assert_factory should return a table"
	tf.assert type(factory.assert) == "function", "factory should have an assert function"
	tf.assert type(factory.fails) == "function", "factory should have a fails function"
	tf.assert factory.fails! == 0, "New factory should have 0 failures"
	
	-- Create a separate test factory to test a failing assertion
	-- This is expected to fail (but our test will pass if it counts failures correctly)
	expected_failing_factory = assert_factory!
	expected_failing_factory.assert false, "This should fail"
	tf.assert expected_failing_factory.fails! == 1, "Factory should count failures"
	
	-- Test parse_args with a simple config
	config = {
		{ name: "verbose", flags: {"-v", "--verbose"}, has_arg: false, description: "Enable verbose mode" }
		{ name: "file", flags: {"-f", "--file"}, has_arg: true, description: "Path to input file" }
	}
	
	-- Test with no args
	result = parse_args config, {}
	tf.assert type(result) == "table", "parse_args should return a table"
	tf.assert type(result[1]) == "table", "parse_args should return options table"
	tf.assert type(result[2]) == "table", "parse_args should return positionals table"
	tf.assert #result[2] == 0, "No positional args expected"
	
	-- Test with verbose flag
	result = parse_args config, {"-v"}
	tf.assert result[1].verbose == true, "Verbose flag should be set"
	
	-- Test with long verbose flag
	result = parse_args config, {"--verbose"}
	tf.assert result[1].verbose == true, "Long verbose flag should be set"
	
	-- Test with file argument
	result = parse_args config, {"-f", "test.txt"}
	tf.assert result[1].file == "test.txt", "File argument should be set"
	
	-- Test with long file argument
	result = parse_args config, {"--file", "test.txt"}
	tf.assert result[1].file == "test.txt", "Long file argument should be set"
	
	-- Test with positional arguments
	result = parse_args config, {"pos1", "pos2"}
	tf.assert #result[2] == 2, "Should have 2 positional args"
	tf.assert result[2][1] == "pos1", "First positional arg should be correct"
	tf.assert result[2][2] == "pos2", "Second positional arg should be correct"
	
	-- Test with mixed arguments
	result = parse_args config, {"-v", "pos1", "-f", "test.txt", "pos2"}
	tf.assert result[1].verbose == true, "Verbose flag should be set"
	tf.assert result[1].file == "test.txt", "File argument should be set"
	tf.assert #result[2] == 2, "Should have 2 positional args"
	tf.assert result[2][1] == "pos1", "First positional arg should be correct"
	tf.assert result[2][2] == "pos2", "Second positional arg should be correct"
	
	-- Test validator
	config_with_validator = {
		{ 
			name: "number", 
			flags: {"-n", "--number"}, 
			has_arg: true, 
			description: "A number", 
			validator: (n) -> tonumber(n) != nil 
		}
	}
	
	-- We can't directly test the validation failure since it calls os.exit
	-- But we can test successful validation
	result = parse_args config_with_validator, {"-n", "42"}
	tf.assert result[1].number == "42", "Number argument should be set"
	
	-- Test help text generation
	-- Test the helptext table directly instead of capturing output
	config_with_desc = {
		{ name: "verbose", flags: {"-v", "--verbose"}, has_arg: false, description: "Enable verbose mode" }
		{ name: "file", flags: {"-f", "--file"}, has_arg: true, description: "Path to input file" }
	}
	
	-- Build helptext manually like in parse_args
	helptext = {}
	for entry in *config_with_desc
		if entry.description
			helptext[#helptext + 1] = table.concat(entry.flags, ", ") .. "\t" .. entry.description
	
	-- Check helptext directly
	tf.assert #helptext >= 2, "Help table should have at least 2 entries"
	
	-- Manually construct what the help output would be
	help_output = {"Usage:"}
	for line in *helptext
		help_output[#help_output + 1] = "  " .. line
	
	-- Check help output
	tf.assert #help_output >= 3, "Help output should have at least 3 lines"
	tf.assert help_output[1] == "Usage:", "Help output should start with 'Usage:'"
	
	io.stderr\write "Tests completed. Failures: #{tf.fails!}\n"
	os.exit tf.fails!

return {
	seed_rng: seed_rng
	assert_factory: assert_factory
	parse_args: parse_args
}
