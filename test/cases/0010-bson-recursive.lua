--------------------------------------------------------------------------------
-- tests for bson: serialization and deserialization
-- This file is a part of ljffi-mongo  library
-- @copyright ljffi-mongo  authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ensure,
      ensure_equals,
      ensure_fails_with_substring,
      ensure_tdeepequals,
      ensure_is
      = import 'lua-nucleo/ensure.lua'
      {
        'ensure',
        'ensure_equals',
        'ensure_fails_with_substring',
        'ensure_tdeepequals',
        'ensure_is'
      }

--------------------------------------------------------------------------------

local bson = import 'ljffi-mongo/bson' ()

--------------------------------------------------------------------------------

local test = (...)("bson", bson)

--------------------------------------------------------------------------------

test:group "new_bson"

test:case "return-type" (function() 
  ensure_is("Should return BSON C struct", bson.new_bson(), 'cdata') 
end)

test:case "return-uniqueness" (function() 
  ensure("Should not return same struct twice", bson.new_bson() ~= bson.new_bson()) 
end)

--------------------------------------------------------------------------------
test:group "table_to_bson"

local function two_way(t) 
  local obj = bson.table_to_bson(t)
  ensure_is("Should return BSON C struct", obj, 'cdata') 

  ensure_tdeepequals("Should return BSON C struct", bson.bson_to_table(obj), t) 
end

test:case "simple-serialization" (function()
  two_way({ number = 42, string = "string", boolean = true })
end)

test:case "complex-table-serialization" (function()
  two_way({ number = 1, table = { string = 'string', table = { string = 'other string' } } })
end)

test:case "array-serialization" (function()
  two_way({ key = { 1, 2, 3, 4 } })
end)

test:case "nil-serialization" (function()
  two_way({ ['nil'] = nil })
end)

test:case "recursive-table-key-serialization" (function()
  local t = { }
  t[t] = "foo"
  ensure_fails_with_substring(
      "Shouldn't serialize table with recursive keys",
      function() two_way(t) end,
      "Key type is no supported for BSON serialization: 'table'"
    )
end)

test:case "recursive-table-value-serialization" (function()
  local t = { }
  t['foo'] = t
  ensure_fails_with_substring(
      "Shouldn't serialize table with recursive keys",
      function() two_way(t) end,
      "Cannot serialize recursive table to BSON"
  )
end)

--------------------------------------------------------------------------------
test:group "get_id"
test:case "extract-empty-id" (function()
  local id = bson.get_id(bson.table_to_bson({ number = 42 }))
  ensure("Should return nil if _id not found", id == nil)
end)

test:case "extract-generated-id" (function()
  local id = bson.get_id(bson.table_to_bson({ number = 42 }, true))
  ensure("Should return string if id was generated", type(id) == 'string')
  ensure("Should return standard-length MongoDB id", #id == 24)
end)

--------------------------------------------------------------------------------
test:group "bson_to_table"
test:case "empty-table-serialization" (function()
  two_way({ })
end)

test:TODO "Test deserialization of BSON object with fields doesn't match to Lua types"
--See https://github.com/logiceditor-com/ljffi-mongo/issues/2
