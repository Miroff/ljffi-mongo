--------------------------------------------------------------------------------
--- High-level FFI bindings to MongoDB C driver.
-- @module ljffi-mongo.ffi
-- This file is a part of ljffi-mongo  library
-- @copyright ljffi-mongo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local ffi = require 'ffi'

local mongoc = require 'ljffi-mongo/ffi'

local bson = require 'ljffi-mongo/bson'

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

local assert_is_string,
      assert_is_number
      = import 'lua-nucleo/typeassert.lua'
      {
        'assert_is_string',
        'assert_is_number'
      }      

--------------------------------------------------------------------------------

--Default MongoDB port
local DEFAULT_MONGODB_PORT = 27017
--Default MongoDB host name
local DEFAULT_MONGODB_HOST = 'localhost'

--------------------------------------------------------------------------------

local mongo = 
{
    -- Create a tailable cursor.
    MONGO_TAILABLE = ffi.C.MONGO_TAILABLE; 
    -- Allow queries on a non-primary node. 
    MONGO_SLAVE_OK = ffi.C.MONGO_SLAVE_OK; 
    -- Disable cursor timeouts.
    MONGO_NO_CURSOR_TIMEOUT = ffi.C.MONGO_NO_CURSOR_TIMEOUT;
    -- Momentarily block for more data.
    MONGO_AWAIT_DATA = ffi.C.MONGO_AWAIT_DATA; 
    -- Stream in multiple 'more' packages.
    MONGO_EXHAUST = ffi.C.MONGO_EXHAUST; 
    -- Allow reads even if a shard is down.
    MONGO_PARTIAL = ffi.C.MONGO_PARTIAL; 

    MONGO_INDEX_UNIQUE = ffi.C.MONGO_INDEX_UNIQUE;
    MONGO_INDEX_DROP_DUPS = ffi.C.MONGO_INDEX_DROP_DUPS;
    MONGO_INDEX_BACKGROUND = ffi.C.MONGO_INDEX_BACKGROUND;
    MONGO_INDEX_SPARSE = ffi.C.MONGO_INDEX_SPARSE;

    MONGO_UPDATE_UPSERT = ffi.C.MONGO_UPDATE_UPSERT;
    MONGO_UPDATE_MULTI = ffi.C.MONGO_UPDATE_MULTI;
    MONGO_UPDATE_BASIC = ffi.C.MONGO_UPDATE_BASIC;

    MONGO_CONTINUE_ON_ERROR = ffi.C.MONGO_CONTINUE_ON_ERROR;
}

--------------------------------------------------------------------------------
-- Admin methods
--------------------------------------------------------------------------------

local run_command, create_index, create_capped_collection, drop_db, 
    drop_collection, add_user, authenticate

do
  run_command = function (self, db, command)
    method_arguments(
      self,
      "string", db,
      "table", command
    )

    local bson_in = bson.table_to_bson(command)
    local bson_out = bson.new_bson()

    if 
      mongoc.mongo_run_command(
          self.con_, 
          db, 
          bson_in, 
          bson_out
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('run_command')
    end

    return bson.bson_to_table(bson_out)
  end

  create_index = function(self, ns, key, options)
    options = options or 0

    method_arguments(
      self,
      "string", ns,
      "number", options
    )

    local bson_out = bson.new_bson()

    if type(key) == 'table' then
      local bson_data = bson.table_to_bson(key)
      if 
        mongoc.mongo_create_index(
            self.con_, 
            ns, bson_data, 
            options, 
            bson_out
          ) ~= ffi.C.MONGO_OK 
      then
        return self:check_result_('create_index')
      end
    elseif type(key) == 'string' then 
      if 
        mongoc.mongo_create_simple_index(
            self.con_, 
            ns, 
            key, 
            options, 
            bson_out
          ) ~= ffi.C.MONGO_OK 
      then 
        return self:check_result_('create_index')
      end
    else
      error("Key type is not supported: " .. type(key))
    end

    return bson.bson_to_table(bson_out)
  end  

  create_capped_collection = function(self, db, collection, size, max)
    max = max or 0
    method_arguments(
      self,
      "string", db,
      "string", collection,
      "number", size,
      "number", max
    )

    local bson_out = bson.new_bson()

    if 
      mongoc.mongo_create_capped_collection(
          self.con_, 
          db, 
          collection, 
          size, 
          max, 
          bson_out
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('create_capped_collection')
    end

    return bson.bson_to_table(bson_out)
  end

  drop_db = function(self, db)
    method_arguments(
      self,
      "string", db
    )

    if mongoc.mongo_cmd_drop_db(self.con_, db) ~= ffi.C.MONGO_OK then
      return self:check_result_('drop_db')
    end

    return true
  end

  drop_collection = function(self, db, collection)
    method_arguments(
      self,
      "string", db,
      "string", collection
    )

    local bson_out = bson.new_bson()

    if 
      mongoc.mongo_cmd_drop_collection(
          self.con_, 
          db, 
          collection, 
          bson_out
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('drop_collection')
    end

    return bson.bson_to_table(bson_out)
  end

  add_user = function(self, db, user, pass)
    method_arguments(
      self,
      "string", db,
      "string", user,
      "string", pass
    )

    if 
      mongoc.mongo_cmd_add_user(
          self.con_, 
          db, 
          user, 
          pass
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('add_user')
    end

    return true
  end

  authenticate = function(self, db, user, pass)
    method_arguments(
      self,
      "string", db,
      "string", user,
      "string", pass
    )

    if 
      mongoc.mongo_cmd_authenticate(
          self.con_, 
          db, 
          user, 
          pass
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_failsafe_('authenticate', false)
    end

    return true
  end
end

--------------------------------------------------------------------------------
-- CRUD methods
--------------------------------------------------------------------------------

local insert, insert_batch, update, remove

do
  insert = function(self, ns, data, wc)
    method_arguments(
      self,
      "string", ns,
      "table", data
    )

    local bson_data = bson.table_to_bson(data, true)

    if mongoc.mongo_insert(self.con_, ns, bson_data, wc) ~= ffi.C.MONGO_OK then
      return self:check_result_('insert')
    end

    return bson.get_id(bson_data)
  end

  insert_batch = function(self, ns, data, options, wc)
    options = options or 0

    method_arguments(
      self,
      "string", ns,
      "table", data,
      "number", options
    )

    local bsons = { }
    local ids = { }

    for i = 1, #data do
      bsons[i] = bson.table_to_bson(data[i], true)
      ids[i] = bson.get_id(bsons[i])
    end

    if 
      mongoc.mongo_insert_batch(
          self.con_, 
          ns, 
          ffi.new('const bson*[?]', #bsons, bsons), 
          #data, 
          wc, 
          options
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('insert_batch')
    end

    return ids
  end

  update = function(self, ns, condition, operation, options, wc)
    options = options or 0
    method_arguments(
      self,
      "string", ns,
      "table", condition,
      "table", operation,
      "number", options
    )

    if 
      mongoc.mongo_update(
          self.con_, 
          ns, 
          bson.table_to_bson(condition), 
          bson.table_to_bson(operation), 
          options, 
          wc
        ) ~= ffi.C.MONGO_OK 
    then 
      return self:check_result_('update')
    end

    return true
  end

  remove = function(self, ns, condition, wc)
    condition = condition or { }

    method_arguments(
      self,
      "string", ns,
      "table", condition
    )

    if 
      mongoc.mongo_remove(
          self.con_, 
          ns, 
          bson.table_to_bson(condition), 
          wc
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_('remove')
    end

    return true
  end
end

--------------------------------------------------------------------------------
-- Cursor methods
--------------------------------------------------------------------------------

local find, find_one, count

do
  find = function(self, ns, query, fields, limit, skip, options)
    query = query or { }
    fields = fields or { }
    limit = limit or 0
    skip = skip or 0
    options = options or 0

    method_arguments(
      self,
      "string", ns,
      "table", query,
      "table", fields,
      "number", limit,
      "number", skip,
      "number", options
    )

    local cursor = mongoc.mongo_find(
        self.con_, 
        ns, 
        bson.table_to_bson(query), 
        bson.table_to_bson(fields), 
        limit, 
        skip, 
        options
      )

    if not cursor then
      return self:check_result_('find')
    end

    cursor = ffi.gc(cursor, mongoc.mongo_cursor_destroy)

    return function()
      while mongoc.mongo_cursor_next(cursor) == ffi.C.MONGO_OK do
        local bson_data = mongoc.mongo_cursor_bson(cursor)
        return bson.bson_to_table(bson_data)
      end

      return nil
    end
  end

  find_one = function(self, ns, query, fields)
    query = query or { }
    fields = fields or { }

    method_arguments(
      self,
      "string", ns,
      "table", query,
      "table", fields
    )

    local bson_out = bson.new_bson();

    if 
      mongoc.mongo_find_one(
          self.con_, 
          ns, 
          bson.table_to_bson(query), 
          bson.table_to_bson(fields), 
          bson_out
        ) ~= ffi.C.MONGO_OK 
    then
      return self:check_result_failsafe_('find_one', nil)
    end

    return bson.bson_to_table(bson_out)
  end

  count = function(self, db, collection, query)
    query = query or { }

    method_arguments(
      self,
      "string", db,
      "string", collection,
      "table", query
    )

    local res = mongoc.mongo_count(
        self.con_, 
        db, 
        collection, 
        bson.table_to_bson(query)
      )

    if res == ffi.C.MONGO_ERROR then
      return self:check_result_('count')
    end

    return res
  end
end

--------------------------------------------------------------------------------
-- Utillity methods
--------------------------------------------------------------------------------

local is_connected, set_write_concern, check_result_, check_result_failsafe_

do
  is_connected = function(self)
    method_arguments(
      self
    )
    
    return mongoc.mongo_check_connection(self.con_) == ffi.C.MONGO_OK
  end

  set_write_concern = function(self, wc)
    method_arguments(
      self,
      'cdata', wc
    )

    mongoc.mongo_set_write_concern(self.con_, wc)

    return true
  end

  check_result_ = function(self, command)
    if self.con_.err == ffi.C.MONGO_IO_ERROR then
      return nil, "Connection failed"
    else
      local msg = "[" .. command .. "] operation failed: "

      local err = tonumber(self.con_.err)
      if err ~= ffi.C.MONGO_CONN_SUCCESS then
        msg = msg .. "[" .. tostring(err) .. "] " 
            .. ffi.string(self.con_.errstr)
      end

      local last_err = tonumber(self.con_.lasterrcode)
      if last_err ~= ffi.C.MONGO_CONN_SUCCESS then
        msg = msg .. "[" .. tostring(last_err) .. "] " 
            .. ffi.string(self.con_.lasterrstr)
      end

      error(msg)
    end
  end

  check_result_failsafe_ = function(self, command, return_value)
    if self.con_.err == ffi.C.MONGO_IO_ERROR then
      return nil, "Connection failed"
    else
      return return_value
    end
  end
end

--------------------------------------------------------------------------------
-- Utillity methods
--------------------------------------------------------------------------------
do
  local create_connection = function()
    return 
    {
      is_connected = is_connected;
      run_command = run_command;
      insert = insert;
      insert_batch = insert_batch;
      update = update;
      remove = remove;
      find = find;
      find_one = find_one;
      count = count;
      create_index = create_index;
      create_capped_collection = create_capped_collection;
      drop_db = drop_db;
      drop_collection = drop_collection;
      add_user = add_user;
      authenticate = authenticate;
      set_write_concern = set_write_concern;
      --
      check_result_ = check_result_;
      check_result_failsafe_ = check_result_failsafe_;
      con_ = ffi.gc(ffi.new("mongo"), mongoc.mongo_destroy);
    }
  end

  mongo.connect = function(hostname, port)
    hostname = hostname or DEFAULT_MONGODB_HOST
    port = port or DEFAULT_MONGODB_PORT

    arguments(
      "string", hostname,
      "number", port
    )
  
    local connection = create_connection()

    mongoc.mongo_client(connection.con_, hostname, port)

    return connection
  end

  mongo.connect_replica_set = function(nodes)
    arguments(
      "table", nodes
    )

    local connection = create_connection()

    mongoc.mongo_replica_set_init(connection.con_, "")

    for i = 1, #nodes do
      assert_is_number(nodes[i]['port'], "Port must be a number")
      assert_is_string(nodes[i]['host'], "Host must be a string")

      mongoc.mongo_replica_set_add_seed(
          connection.con_, 
          nodes[i].host, 
          nodes[i].port
        )
    end

    mongoc.mongo_replica_set_client(connection.con_)

    return connection
  end

  mongo.create_write_concern = function(arg)
    arg = arg or { }
    arguments(
      "table", arg
    )

    arg.w = arg.w or 0
    arg.wtimeout = arg.wtimeout or 0
    arg.j = arg.j or false
    arg.fsync = arg.fsync or false
    arg.mode = arg.mode or "getlasterror"
  
    arguments(
      "number", arg.w,
      "number", arg.wtimeout,
      "boolean", arg.j,
      "boolean", arg.fsync,
      "string", arg.mode
    )

    local wc = ffi.gc(
        ffi.new("mongo_write_concern"), 
        mongoc.mongo_write_concern_destroy
      )

    wc.w = arg.w
    wc.wtimeout = arg.wtimeout
    wc.j = arg.j and 1 or 0
    wc.fsync = arg.fsync and 1 or 0
    wc.mode = arg.mode

    return wc
  end
end

return mongo
