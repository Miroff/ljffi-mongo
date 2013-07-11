ljffi-mongo: LuaJIT FFI MongoDB Driver
======================================

Installation
------------

1. Download mongo-c-driver from https://github.com/mongodb/mongo-c-driver/
2. Follow instructions from mongo-c-driver/README to build and install mongo-c-driver
3. Don't forget to run `sudo ldconfig` after mongo-c-driver was installed

Usage
-----

```
--import ljffi-mongo driver
local mongo = import 'ljffi-mongo/mongo' ()

--Connect to server
local con = mongo.connect("localhost", 27017)

local id = con:insert("ljffi-mongo.mycoll", {foo='bar'})
```

For more examples see `test/cases/0020-mongo.lua`

Serialization
--------------------------

ljffi-mongo supports transparent serialization/deserialization of Lua tables to BSON and BSON to Lua tables. This serialization is possible with certain restrictions:

A table could be serialized to MongoDB document iff:
 * All table keys must be either `string`, `number`, or `boolean`. Using other types as table key will cause an error. 
 * All table values must be either `string`, `number`, `boolean`, `nil`, or `table`. Using other types of values will cause an error. 
 * All nested tables should match to restrictions #1 and #2
 * Recursive tables are not supported. 

Serialization rules are:
 * Empty tables will be serialized to empty documents
 * `nil` will be serialized to `null`

Deserialization restrictions
----------------------------

A MongoDB document could be deserialized using following rules:
 * Numbers of any type, `integer`, `long`, or `double`, will be deserialized to Lua `number`. Type information will be lost for this values. 
 * Boolean values will be deserialized to Lua `boolean`
 * String values will be deserialized to Lua `string`
 * Null values will be deserialized to Lua `nil`
 * Arrays will be deserialized to Lua `table`
 * Objects will be deserialized to Lua `table`
 * Dates and timestamps will be deserialized to Lua `number`
 * ObjectID will be Arrays will be deserialized to Lua `string`

Copyright
---------

Copyright (c) 2013, ljffi-mongo authors

See the copyright information in the file named `COPYRIGHT`.

This project is sponsored by LogicEditor (http://logiceditor.com/)
