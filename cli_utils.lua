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
assert_factory = function()
  local fails = 0
  local assert
  assert = function(expr, msg)
    if msg == nil then
      msg = "Assertion failed"
    end
    if not (expr) then
      io.stderr:write("FAIL: " .. tostring(msg) .. "\n")
      fails = fails + 1
    end
  end
  return {
    assert = assert,
    fails = function()
      return fails
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
        if not (argval) then
          io.stderr:write("Missing argument for " .. tostring(token) .. "\n")
          os.exit(1)
        end
        local validator = entry.validator or default_validator
        if not (validator(argval)) then
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
if arg and arg[0] and arg[1] == "--test" then
  local script_path = debug.getinfo(1, "S").source:match("^@(.*/)")
  package.path = script_path .. "?.lua;" .. script_path .. "?.moon;" .. package.path
  local tf = assert_factory()
  local seed_result = seed_rng()
  tf.assert(seed_result == nil, "seed_rng should return nil")
  local factory = assert_factory()
  tf.assert(type(factory) == "table", "assert_factory should return a table")
  tf.assert(type(factory.assert) == "function", "factory should have an assert function")
  tf.assert(type(factory.fails) == "function", "factory should have a fails function")
  tf.assert(factory.fails() == 0, "New factory should have 0 failures")
  local expected_failing_factory = assert_factory()
  expected_failing_factory.assert(false, "This should fail")
  tf.assert(expected_failing_factory.fails() == 1, "Factory should count failures")
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
  tf.assert(type(result) == "table", "parse_args should return a table")
  tf.assert(type(result[1]) == "table", "parse_args should return options table")
  tf.assert(type(result[2]) == "table", "parse_args should return positionals table")
  tf.assert(#result[2] == 0, "No positional args expected")
  result = parse_args(config, {
    "-v"
  })
  tf.assert(result[1].verbose == true, "Verbose flag should be set")
  result = parse_args(config, {
    "--verbose"
  })
  tf.assert(result[1].verbose == true, "Long verbose flag should be set")
  result = parse_args(config, {
    "-f",
    "test.txt"
  })
  tf.assert(result[1].file == "test.txt", "File argument should be set")
  result = parse_args(config, {
    "--file",
    "test.txt"
  })
  tf.assert(result[1].file == "test.txt", "Long file argument should be set")
  result = parse_args(config, {
    "pos1",
    "pos2"
  })
  tf.assert(#result[2] == 2, "Should have 2 positional args")
  tf.assert(result[2][1] == "pos1", "First positional arg should be correct")
  tf.assert(result[2][2] == "pos2", "Second positional arg should be correct")
  result = parse_args(config, {
    "-v",
    "pos1",
    "-f",
    "test.txt",
    "pos2"
  })
  tf.assert(result[1].verbose == true, "Verbose flag should be set")
  tf.assert(result[1].file == "test.txt", "File argument should be set")
  tf.assert(#result[2] == 2, "Should have 2 positional args")
  tf.assert(result[2][1] == "pos1", "First positional arg should be correct")
  tf.assert(result[2][2] == "pos2", "Second positional arg should be correct")
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
  tf.assert(result[1].number == "42", "Number argument should be set")
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
  tf.assert(help_output[1] == "Usage:", "Help output should start with 'Usage:'")
  io.stderr:write("Tests completed. Failures: " .. tostring(tf.fails()) .. "\n")
  os.exit(tf.fails())
end
return {
  seed_rng = seed_rng,
  assert_factory = assert_factory,
  parse_args = parse_args
}
