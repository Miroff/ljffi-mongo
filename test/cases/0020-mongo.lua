--------------------------------------------------------------------------------
-- tests for mongo: MongoDB driver API
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

local tpretty 
      = import 'lua-nucleo.tpretty'
      {
        'tpretty'
      }

--------------------------------------------------------------------------------

local mongo = import 'ljffi-mongo/mongo' ()

--------------------------------------------------------------------------------

local test = (...)("mongo")

--------------------------------------------------------------------------------

test:group "connect"

test:case "connect-to-local-server" (function() 
  local con = mongo.connect()

  ensure_is("Connection should be a table", con, 'table')

  ensure_equals("Connection should be established", con:is_connected(), true)

  con:drop_db("ljffi-mongo")

  ensure("Should not return nil", con:run_command('admin', { listDatabases = 1 }) ~= nil)
end)

test:case "connect-to-replica-set" (function() 
  local con = mongo.connect()

  if not pcall(function() con:run_command('admin',  { replSetGetStatus = 1 }) end)  then
    -- Replication is not available on this MongoDB instance. 
    -- No futher tests are possible
    return
  end

  local con = mongo.connect_replica_set({ { host = "127.0.0.1", port = 27017 }, { host = "127.0.0.1", port = 27017 } })

  ensure_is("Connection should be a table", con, 'table')

  ensure_equals("Connection should be established", con:is_connected(), true)
end)

--------------------------------------------------------------------------------

test:group "CRUD"
test:case "simple-document-CRUD" (function() 
  local con = mongo.connect()
  local ns = "ljffi-mongo.crud"

  local id = con:insert(ns, { number = 42 })

  ensure_is("Should return document id", id, 'string')

  local found = con:find(ns, { ['_id'] = id })()

  ensure_equals("Should return the same object we just put", found['number'], 42)

  con:update(ns, { ['_id'] = id }, { ['$set'] = { number = 56 } })

  found = con:find(ns, { ['_id'] = id })()
  ensure_equals("Should return the same value we just changed", found['number'], 56)

  con:remove(ns, { ['_id'] = id })

  found = con:find(ns, { ['_id'] = id })()
  ensure_equals("Shouldn't return removed object", found, nil)
end)

--------------------------------------------------------------------------------
test:group "Batch insert"
test:case "insert-multiple-documents" (function() 
  local con = mongo.connect()
  local ns = "ljffi-mongo.batch_insert"

  con:remove(ns) -- empty collection

  local ids = con:insert_batch(ns, { { object_number = 1 }, { object_number = 2 }, { object_number = 3 } })

  ensure_equals("Should return id for each object", #ids, 3)

  local count = 0
  for obj in con:find(ns) do
    count = count + 1
    ensure_equals("Should preserve objects order", obj['object_number'], count)
  end

  ensure_equals("Should find all objects", count, 3)

  ensure_equals("Should count all objects", con:count("ljffi-mongo", "batch_insert"), 3)
end)

--------------------------------------------------------------------------------
test:group "Create index"
test:case "create-simple-index-from-table" (function() 
  local con = mongo.connect()
  local ns = "ljffi-mongo.index"

  ensure_equals("Should return OK", con:create_index("luatest.test", { foo = 1 })['ok'], 1)
end)

test:case "create-simple-index-from-string" (function() 
  local con = mongo.connect()
  local ns = "ljffi-mongo.index"

  ensure_equals("Should return OK", con:create_index("luatest.test", "bar")['ok'], 1)
end)

--------------------------------------------------------------------------------
test:group "Capped collection"
test:case "create-capped-collection" (function() 
  local con = mongo.connect()
  local ns = "ljffi-mongo.capped"

  local result = con:create_capped_collection("ljffi-mongo", "capped", 10, 100000)
  ensure_equals("Should return ok", result['ok'], 1)
  for i = 1, 20 do
    con:insert(ns, { number = i })
  end

  ensure_equals("Should count all objects", con:count("ljffi-mongo", "capped"), 10)

  con:drop_collection("ljffi-mongo", "capped")

  ensure_equals("Should count all objects", con:count("ljffi-mongo", "capped"), 0)
end)

--------------------------------------------------------------------------------
test:group "User management"
test:case "create-and-authenticate-user" (function() 
  local con = mongo.connect()

  con:add_user("ljffi-mongo", "test_user", "1q2w3e")

  ensure("Should authenticate", con:authenticate("ljffi-mongo", "test_user", "1q2w3e"))
  
  ensure("Should fail", not con:authenticate("ljffi-mongo", "test_user", "*wrong password*"))
end)

--------------------------------------------------------------------------------
test:group "find_one methos"
test:case "find-existing-object" (function() 
  local con = mongo.connect()

  local id = con:insert("ljffi-mongo.find_one", { foo = 'bar' })

  ensure_is("Should be string", id, 'string')
  
  local obj = con:find_one("ljffi-mongo.find_one", { ['_id'] = id })
  ensure_equals("Should be string", obj['foo'], 'bar')
end)

test:case "find-missing-object" (function() 
  local con = mongo.connect()

  local obj = con:find_one("ljffi-mongo.find_one", { ['_id'] = 'missing_object' })
  ensure_equals("Should be string", obj, nil)
end)

--------------------------------------------------------------------------------
test:group "write concern"
test:case "set-global-write-concern" (function() 
  local con = mongo.connect()

  con:set_write_concern(mongo.create_write_concern())

  local id = con:insert("ljffi-mongo.find_one", { foo = 'bar' }, mongo.create_write_concern({ w = -1, fsync = true }))
end)
