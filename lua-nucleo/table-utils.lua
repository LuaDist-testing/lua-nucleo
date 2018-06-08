-- table-utils.lua: small table utilities
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

--------------------------------------------------------------------------------

local setmetatable, error, pairs, ipairs, tostring, select, type, assert
    = setmetatable, error, pairs, ipairs, tostring, select, type, assert

local rawget = rawget

local table_insert, table_remove = table.insert, table.remove

--------------------------------------------------------------------------------

local arguments,
      optional_arguments,
      method_arguments
      = import 'lua-nucleo/args.lua'
      {
        'arguments',
        'optional_arguments',
        'method_arguments'
      }

local is_table
      = import 'lua-nucleo/type.lua'
      {
        'is_table'
      }

--------------------------------------------------------------------------------

-- Warning: it is possible to corrupt this with rawset and debug.setmetatable.
local empty_table = setmetatable(
    { },
    {
      __newindex = function(t, k, v)
        error("attempted to change the empty table", 2)
      end;

      __metatable = "empty_table";
    }
  )

local function toverride_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      t[k] = v
    end
    -- Recursion is usually faster than calling select()
    return toverride_many(t, ...)
  end

  return t
end

local function tappend_many(t, s, ...)
  if s then
    for k, v in pairs(s) do
      if t[k] == nil then
        t[k] = v
      else
        error("attempted to override table key `" .. tostring(k) .. "'", 2)
      end
    end

    -- Recursion is usually faster than calling select()
    return tappend_many(t, ...)
  end

  return t
end

local function tijoin_many(t, s, ...)
  if s then
    -- Note: can't use ipairs() since we want to support tijoin_many(t, t)
    for i = 1, #s do
      t[#t + 1] = s[i]
    end

    -- Recursion is usually faster than calling select()
    return tijoin_many(t, ...)
  end

  return t
end

-- Keys are ordered in undetermined order
local tkeys = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = k
  end

  return r
end

-- Values are ordered in undetermined order
local tvalues = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[#r + 1] = v
  end

  return r
end

-- Keys and values are ordered in undetermined order
local tkeysvalues = function(t)
  local keys, values = { }, { }

  for k, v in pairs(t) do
    keys[#keys + 1] = k
    values[#values + 1] = v
  end

  return keys, values
end

-- If table contains multiple keys with the same value,
-- only one key is stored in the result, picked in undetermined way.
local tflip = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = k
  end

  return r
end

-- If table contains multiple keys with the same value,
-- only the last such key (highest one) is stored in the result.
local tiflip = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = i
  end

  return r
end

local tset = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = true
  end

  return r
end

local tiset = function(t)
  local r = { }

  for i = 1, #t do
    r[t[i]] = true
  end

  return r
end

local function tiinsert_args(t, a, ...)
  if a ~= nil then
    t[#t + 1] = a
    -- Recursion is usually faster than calling select() in a loop.
    return tiinsert_args(t, ...)
  end

  return t
end

local timap_inplace = function(fn, t, ...)
  for i = 1, #t do
    t[i] = fn(t[i], ...)
  end

  return t
end

local timap = function(fn, t, ...)
  local r = { }
  for i = 1, #t do
    r[i] = fn(t[i], ...)
  end
  return r
end

local timap_sliding = function(fn, t, ...)
  local r = {}

  for i = 1, #t do
    tiinsert_args(r, fn(t[i], ...))
  end

  return r
end

local tiwalk = function(fn, t, ...)
  for i = 1, #t do
    fn(t[i], ...)
  end
end

local tiwalker = function(fn)
  return function(t)
    for i = 1, #t do
      fn(t[i])
    end
  end
end

local twalk_pairs = function(fn, t)
  for k, v in pairs(t) do
    fn(k, v)
  end
end

local tequals = function(lhs, rhs)
  for k, v in pairs(lhs) do
    if v ~= rhs[k] then
      return false
    end
  end

  for k, v in pairs(rhs) do
    if lhs[k] == nil then
      return false
    end
  end

  return true
end

local tiunique = function(t)
  return tkeys(tiflip(t))
end

local tgenerate_n = function(n, generator, ...)
  local r = { }
  for i = 1, n do
    r[i] = generator(...)
  end
  return r
end

local taccumulate = function(t, init)
  local sum = init or 0
  for k, v in pairs(t) do
    sum = sum + v
  end
  return sum
end

local tnormalize, tnormalize_inplace
do
  local impl = function(t, r, sum)
    sum = sum or taccumulate(t)

    for k, v in pairs(t) do
      r[k] = v / sum
    end

    return r
  end

  tnormalize = function(t, sum)
    return impl(t, { }, sum)
  end

  tnormalize_inplace = function(t, sum)
    return impl(t, t, sum)
  end
end

local tclone
do
  local function impl(t, visited)
    local t_type = type(t)
    if t_type ~= "table" then
      return t
    end

    assert(not visited[t], "recursion detected")
    visited[t] = true

    local r = { }
    for k, v in pairs(t) do
      r[impl(k, visited)] = impl(v, visited)
    end

    visited[t] = nil

    return r
  end

  tclone = function(t)
    return impl(t, { })
  end
end

-- Slow
local tcount_elements = function(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

local tremap_to_array = function(fn, t)
  local r = { }
  for k, v in pairs(t) do
    r[#r + 1] = fn(k, v)
  end
  return r
end

local tmap_values = function(fn, t, ...)
  local r = { }
  for k, v in pairs(t) do
    r[k] = fn(v, ...)
  end
  return r
end

--------------------------------------------------------------------------------

local torderedset = function(t)
  local r = { }

  for i = 1, #t do
    local v = t[i]

    -- Have to add this limitation to avoid size ambiquity.
    -- If you need ordered set of numbers, use separate storage
    -- for set and array parts (write make_ordered_set then).
    assert(type(v) ~= "number", "can't insert number into ordered set")

    r[v] = i
    r[i] = v
  end

  return r
end

-- Returns false if item already exists
-- Returns true otherwise
local torderedset_insert = function(t, v)
  -- See torderedset() for motivation
  assert(type(v) ~= "number", "can't insert number into ordered set")

  if not t[v] then
    local i = #t + 1
    t[v] = i
    t[i] = v

    return true
  end

  return false
end

-- Returns false if item didn't existed
-- Returns true otherwise
-- Note this operation is really slow
local torderedset_remove = function(t, v)
  -- See torderedset() for motivation
  assert(type(v) ~= "number", "can't remove number from ordered set")

  local pos = t[v]
  if pos then
    t[v] = nil
    -- TODO: Do table.remove manually then to do all in a single loop.
    table_remove(t, pos)
    for i = pos, #t do
      t[t[i]] = i -- Update changed numbers
    end
  end

  return false
end

--------------------------------------------------------------------------------

-- Handles subtables (is "deep").
-- Does not support recursive defaults tables
-- WARNING: Uses tclone()! Do not use on tables with metatables!
local twithdefaults
do
  twithdefaults = function(t, defaults)
    for k, d in pairs(defaults) do
      local v = t[k]
      if v == nil then
        if type(d) == "table" then
          d = tclone(d)
        end
        t[k] = d
      elseif type(v) == "table" and type(d) == "table" then
        twithdefaults(v, d)
      end
    end

    return t
  end
end

--------------------------------------------------------------------------------

local tifilter = function(pred, t, ...)
  local r = { }
  for i = 1, #t do
    local v = t[i]
    if pred(v, ...) then
      r[#r + 1] = v
    end
  end
  return r
end

--------------------------------------------------------------------------------

local tsetof = function(value, t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = value
  end

  return r
end

--------------------------------------------------------------------------------

local tset_many = function(...)
  local r = { }

  for i = 1, select("#", ...) do
    for k, v in pairs((select(i, ...))) do
      r[v] = true
    end
  end

  return r
end

-- TODO: Pick a better name?
local tidentityset = function(t)
  local r = { }

  for k, v in pairs(t) do
    r[v] = v
  end

  return r
end

--------------------------------------------------------------------------------

local timapofrecords = function(t, key)
  local r = { }

  for i = 1, #t do
    local v = t[i]
    r[assert(v[key], "missing record key field")] = v
  end

  return r
end

local tivalues = function(t)
  local r = { }

  for i = 1, #t do
    r[#r + 1] = t[i]
  end

  return r
end

--------------------------------------------------------------------------------

-- NOTE: Optimized to be fast at simple value indexing.
--       Slower on initialization and on table value fetching.
-- WARNING: This does not protect userdata.
local treadonly, treadonly_ex
do
  local newindex = function()
    error("attempted to change read-only table")
  end

  treadonly = function(value, callbacks, tostring_fn, disable_nil)
    callbacks = callbacks or empty_table
    if disable_nil == nil then
      disable_nil = true
    end

    arguments(
        "table", value,
        "table", callbacks
      )

    optional_arguments(
        "function", tostring_fn,
        "boolean", disable_nil -- TODO: ?! Not exactly optional
      )

    local mt =
    {
      __metatable = "treadonly"; -- protect metatable

      __index = function(t, k)
        local v = rawget(value, k)
        if is_table(v) then
          -- TODO: Optimize
          v = treadonly(v, callbacks, tostring_fn, disable_nil)
        end
        if v == nil then -- TODO: Try to use metatables
          -- Note: __index does not support multiple return values in 5.1,
          --       so we can not do call right here.
          local fn = callbacks[k]
          if fn then
            return function(...) return fn(value, ...) end
          end
          if disable_nil then
            error(
                "attempted to read inexistant value at key " .. tostring(k),
                2
              )
          end
        end
        return v
      end;

      __newindex = newindex;
    }

    if tostring_fn then
      mt.__tostring = function() return tostring_fn(value) end
    end

    return setmetatable({ }, mt)
  end

  -- Changes to second return value are guaranteed to affect first one
  treadonly_ex = function(value, ...)
    local protected = treadonly(value, ...)
    return protected, value
  end
end

--------------------------------------------------------------------------------

return
{
  empty_table = empty_table;
  toverride_many = toverride_many;
  tappend_many = tappend_many;
  tijoin_many = tijoin_many;
  tkeys = tkeys;
  tvalues = tvalues;
  tkeysvalues = tkeysvalues;
  tflip = tflip;
  tiflip = tiflip;
  tset = tset;
  tiset = tiset;
  tiinsert_args = tiinsert_args;
  timap_inplace = timap_inplace;
  timap = timap;
  timap_sliding = timap_sliding;
  tiwalk = tiwalk;
  tiwalker = tiwalker;
  tequals = tequals;
  tiunique = tiunique;
  tgenerate_n = tgenerate_n;
  taccumulate = taccumulate;
  tnormalize = tnormalize;
  tnormalize_inplace = tnormalize_inplace;
  tclone = tclone;
  tcount_elements = tcount_elements;
  tremap_to_array = tremap_to_array;
  twalk_pairs = twalk_pairs;
  tmap_values = tmap_values;
  torderedset = torderedset;
  torderedset_insert = torderedset_insert;
  torderedset_remove = torderedset_remove;
  twithdefaults = twithdefaults;
  tifilter = tifilter;
  tsetof = tsetof;
  tset_many = tset_many;
  tidentityset = tidentityset;
  timapofrecords = timapofrecords;
  tivalues = tivalues;
  treadonly = treadonly;
  treadonly_ex = treadonly_ex;
}
