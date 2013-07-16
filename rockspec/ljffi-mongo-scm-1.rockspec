package = "ljffi-mongo"
version = "scm-1"
source = {
   url = "git://github.com/logiceditor-com/ljffi-mongo.git",
   branch = "master"
}
description = {
   summary = "LuaJIT FFI MongoDB Driver",
   homepage = "https://github.com/logiceditor-com/ljffi-mongo",
   license = "MIT/X11",
   maintainer = "LogicEditor Team <team@logiceditor.com>"
}
dependencies = {
   "lua >= 5.1",
   "lua-nucleo >= 0.2.1"
}
build = {
   type = "builtin",
   modules = {
      mongo = {
         sources = {
            -- bundled mongo-c-driver code --
            "lib/mongo-c-driver/src/bcon.c",
            "lib/mongo-c-driver/src/bson.c",
            "lib/mongo-c-driver/src/encoding.c",
            "lib/mongo-c-driver/src/env.c",
            "lib/mongo-c-driver/src/gridfs.c",
            "lib/mongo-c-driver/src/md5.c",
            "lib/mongo-c-driver/src/mongo.c",
            "lib/mongo-c-driver/src/numbers.c"
         },
         incdirs = {
            -- bundled mongo-c-driver code --
            "lib/",
            "lib/mongo-c-driver/src"
         },
         defines = { "MONGO_HAVE_STDINT" }
      },
   },
   install = {
      lua = {
         ["ljffi-mongo.mongo"] = "src/lua/ljffi-mongo/mongo.lua";
         ["ljffi-mongo.ffi"] = "src/lua/ljffi-mongo/ffi.lua";
         ["ljffi-mongo.bson"] = "src/lua/ljffi-mongo/bson.lua";
      }
   }
}
