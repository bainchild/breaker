local file = loadstring(assert(io.open(assert((...),"no arg"),"rb")):read("*a"))
local v = require("val")
local env = v.new(getfenv(file),0)
setfenv(file,env)
v.dbg_out=v.dbg_out.."local "..(v.id(env).." = ".."(_ENV or getfenv())\n")
function v.gen_recurse(fun)
   local b4out = v.dbg_out
   local newinv = v.new_box(getfenv(fun),0)
   v.dbg_out="local "..(v.id(newinv).." = ".."(_ENV or getfenv())\n")
   setfenv(fun,newinv)
   fun()
   local out = v.dbg_out
   v.dbg_out = b4out
   return out
end
file()
print(v.dbg_out)
