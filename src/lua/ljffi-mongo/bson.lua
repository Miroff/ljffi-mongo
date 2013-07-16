--------------------------------------------------------------------------------
--- BSON to Lua table conversion tool
-- @module ljffi-mongo.ffi
-- This file is a part of ljffi-mongo  library
-- @copyright ljffi-mongo  authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

require 'lua-nucleo'

local ffi = require 'ffi'

local mongoc = require 'ljffi-mongo/ffi'

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

local tisarray,
      tisempty
      = import 'lua-nucleo/table-utils.lua'
      {
        'tisarray',
        'tisempty'
      }

--------------------------------------------------------------------------------

local table_to_bson, bson_to_table

--------------------------------------------------------------------------------

-- MongoDB object ID field name
local MONGO_ID_FIELD = '_id'

--------------------------------------------------------------------------------

do
  local key_handlers = { }
  local value_handlers = { }

  local is_array = function(t)
    --Treat empty table is object because it makes more sense in BSON
    if tisempty(t) then
      return false
    end

    local mt = getmetatable(t)
    
    if is_table(mt) and mt.is_array ~= nil then
      return mt.is_array
    end

    return tisarray(t)
  end

  local values_to_bson = function(bson, t, visited, array_mode)
    if not visited[t] then
      visited[t] = true
    else
      error "Cannot serialize recursive table to BSON"
    end

    for k, v in pairs(t) do
      assert(key_handlers[type(k)], "Key type is no supported for BSON serialization: '" .. type(k) .. "'")

      local key
      if array_mode then
        --BSON array indices starts from 0 while Lua indices starts from 1
        key = tostring(k - 1)
      else
        key = key_handlers[type(k)](k)
      end

      assert(value_handlers[type(v)], "Value type is no supported for BSON serialization: '" .. type(v) .. "' of key '" .. key .. "'")

      value_handlers[type(v)](bson, key, v, visited)
    end
  end

  -- Handlers of Lua type to BSON key serializing

  key_handlers['number'] = function(k)
    return tostring(k)
  end

  key_handlers['boolean'] = function(k)
    return tostring(k)
  end

  key_handlers['string'] = function(k)
    return k
  end

  -- Handlers of Lua type to BSON values serializing

  value_handlers['number'] = function(bson, k, v)
    assert(mongoc.bson_append_double(bson, k, v) == ffi.C.BSON_OK, "Cannot append bson value")
  end

  value_handlers['boolean'] = function(bson, k, v)
    assert(mongoc.bson_append_bool(bson, k, v) == ffi.C.BSON_OK, "Cannot append bson value")
  end

  value_handlers['string'] = function(bson, k, v)
    --TODO: Remove this hack
    --https://github.com/logiceditor-com/ljffi-mongo/issues/1
    if k == '_id' then
      local oid_t = ffi.new("bson_oid_t")
      mongoc.bson_oid_from_string(oid_t, tostring(v))
      assert(mongoc.bson_append_oid(bson, k, oid_t) == ffi.C.BSON_OK)
    else 
      assert(mongoc.bson_append_string(bson, k, tostring(v)) == ffi.C.BSON_OK)
    end
  end

  value_handlers['table'] = function(bson, k, v, visited)
    --TODO Use BSON schema builder 
    --https://github.com/logiceditor-com/ljffi-mongo/issues/4
    if is_array(v) then 
      assert(mongoc.bson_append_start_array(bson, k) == ffi.C.BSON_OK, "Cannot append bson value")
      values_to_bson(bson, v, visited, true)
      assert(mongoc.bson_append_finish_array(bson) == ffi.C.BSON_OK, "Cannot append bson value")
    else
      assert(mongoc.bson_append_start_object(bson, k) == ffi.C.BSON_OK, "Cannot append bson value")
      values_to_bson(bson, v, visited, false)
      assert(mongoc.bson_append_finish_object(bson) == ffi.C.BSON_OK, "Cannot append bson value")
    end
  end

  table_to_bson = function(t, generate_id)
    generate_id = generate_id or false

    arguments(
      "table", t,
      "boolean", generate_id
    )

    local bson = ffi.gc(ffi.new("bson"), mongoc.bson_destroy)
    local visited = { }
    mongoc.bson_init(bson)

    values_to_bson(bson, t, visited)

    if not t[MONGO_ID_FIELD] and generate_id then
      mongoc.bson_append_new_oid(bson, MONGO_ID_FIELD)
    end

    mongoc.bson_finish(bson)

    return bson
  end
end

--------------------------------------------------------------------------------

do
  local handlers = { }
 
  local function value_to_lua(value_type, iterator)
    if handlers[value_type] then
      return handlers[value_type](iterator)
    else
      error("Unexpected BSON type: " .. tostring(value_type))
    end
  end 

  local function iterator_to_table(iterator)
    local t = { }
    while mongoc.bson_iterator_more(iterator) > 0 do
      local value_type = tonumber(mongoc.bson_iterator_type(iterator))
      local key = ffi.string(mongoc.bson_iterator_key(iterator))

      t[key] = value_to_lua(value_type, iterator)

      mongoc.bson_iterator_next(iterator)
    end

    return t
  end

  local function iterator_to_array(iterator)
    local array = { }

    while mongoc.bson_iterator_more(iterator) > 0 do
      local value_type = tonumber(mongoc.bson_iterator_type(iterator))
      local key = ffi.string(mongoc.bson_iterator_key(iterator))

      --Convert array index from 0-based to 1-based
      local index = tonumber(key) + 1
      array[index] = value_to_lua(value_type, iterator)

      mongoc.bson_iterator_next(iterator)
    end

    return array
  end

  --TODO: Accept other types
  --https://github.com/logiceditor-com/ljffi-mongo/issues/2
  handlers[ffi.C.BSON_DOUBLE] = function(it)
    return mongoc.bson_iterator_double(it)
  end

  handlers[ffi.C.BSON_INT] = function(it)
    return mongoc.bson_iterator_int(it)
  end

  handlers[ffi.C.BSON_LONG] = function(it)
    return mongoc.bson_iterator_long(it)
  end

  handlers[ffi.C.BSON_NULL] = function()
    return nil
  end

  handlers[ffi.C.BSON_BOOL] = function(it)
    return mongoc.bson_iterator_bool(it) == 1
  end

  handlers[ffi.C.BSON_STRING] = function(it)
    return ffi.string(mongoc.bson_iterator_string(it))
  end

  handlers[ffi.C.BSON_DATE] = function(it)
    return mongoc.bson_iterator_date(it)
  end

  handlers[ffi.C.BSON_TIMESTAMP] = function(it)
    return mongoc.bson_iterator_timestamp_time(it)
  end

  handlers[ffi.C.BSON_OID] = function(it)
    local oid = mongoc.bson_iterator_oid(it)
    local oid_string = ffi.new('char [25]')
   
    mongoc.bson_oid_to_string(oid, oid_string)

    return ffi.string(oid_string)
  end

  handlers[ffi.C.BSON_OBJECT] = function(iterator)
    local it = ffi.new("bson_iterator")

    mongoc.bson_iterator_subiterator(iterator, it)

    return iterator_to_table(it)
  end

  handlers[ffi.C.BSON_ARRAY] = function(iterator)
    local it = ffi.new("bson_iterator")

    mongoc.bson_iterator_subiterator(iterator, it)

    return iterator_to_array(it)
  end

  bson_to_table = function(bson)
    arguments(
      "cdata", bson
    )

    local iterator = ffi.new("bson_iterator")

    mongoc.bson_iterator_init(iterator, bson)
    return iterator_to_table(iterator)
  end
end

local get_id = function(bson)
  --TODO avoid table conversion
  --https://github.com/logiceditor-com/ljffi-mongo/issues/3
  return bson_to_table(bson)[MONGO_ID_FIELD]
end

local new_bson = function()
  return ffi.gc(ffi.new("bson"), mongoc.bson_destroy)
end

return 
{
  table_to_bson = table_to_bson;
  bson_to_table = bson_to_table;
  get_id = get_id;
  new_bson = new_bson;
}
