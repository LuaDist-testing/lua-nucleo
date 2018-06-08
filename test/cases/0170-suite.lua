--------------------------------------------------------------------------------
-- 0170-suite.lua: a simple test suite test
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

-- TODO: Test run_tests
-- TODO: Test make_suite with imports_list argument and related methods.
-- TODO: Test strict mode

local make_suite = assert(loadfile('test/test-lib/init/strict.lua'))(...)

local run_tests
    = import 'lua-nucleo/suite.lua'
    {
      'run_tests'
    }

assert(pcall(function() make_suite() end) == false)

-- test, case, run
do
  local test = make_suite("test")
  assert(type(test) == "table")

  assert(pcall(function() test "a" (false) end) == false)

  local to_call = { ["1"] = true, ["2"] = true, ["3"] = true }
  local next_i = 1

  assert(to_call['1'] == true)
  test '1' (function() if next_i ~= 1 then next_i = false else next_i = 2 end to_call['1'] = nil end)
  assert(to_call['1'] == true)

  assert(test:run() == true)
  assert(to_call['1'] == nil)
  assert(next_i == 2)

  to_call['1'] = true
  next_i = 1

  test '2' (function() if next_i ~= 2 then next_i = false else next_i = 3 end to_call['2'] = nil error("this error is expected") end)
  test '3' (function() if next_i ~= 3 then next_i = false else next_i = true end  to_call['3'] = nil end)

  assert(to_call['2'] == true)
  assert(to_call['3'] == true)

  assert(test:run() == nil) -- TODO: Check actual error message.

  assert(next_i == true)
  assert(next(to_call) == nil)
end

-- run_tests, fail_on_first_error
do
  local names =
  {
    "test/data/suite/expected-error-suite.lua",
    "test/data/suite/no-error-suite.lua"
  }

  local parameters_list = {}
  parameters_list.seed_value = 123456

  --missing fail_on_first_error, default is false
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 1)

  parameters_list.fail_on_first_error = true
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 0)

  parameters_list.fail_on_first_error = false
  local nok, errs = run_tests(names, parameters_list)
  assert(nok == 1)
end
