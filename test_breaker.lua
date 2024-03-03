local file = loadstring(assert(io.open(assert((...),"no arg"),"rb")):read("*a"))
local setfenv,getfenv,error,tostring,next,_print = setfenv,getfenv,error,tostring,next,print
function print(...)
   local s = ""
   for i,v in next, {...} do
      if i~=1 then
         s=s.." "
      end
      s=s..tostring(v)
   end
   _print(s)
end
local val = require("val")
local breaker = require("breaker")
local function printb(...)
  print("[host]",...)
end
breaker.recurse_exclude[print] = true
local function setuphook(func)
   local point
   local set;set = function()
     printb(debug.traceback("set",2))
     point=breaker.set(func,set)
     -- printb("back from set")
   end
   local resume = function()
     printb(debug.traceback("resuming...",2))
     if point~=nil then
       return breaker.wind(func,point,function()
         printb("resumed")
       end)
     else
       error("pionoioniniononioont was nil")
     end
   end
   breaker.recurse_exclude[set] = true
   breaker.recurse_exclude[resume] = true
   setfenv(func,setmetatable({
      set=set,
      resume=resume
   },{__index=getfenv(func)}))
end
setuphook(file)
breaker.setup(file).presetup_hook = setuphook
-- local cache = {}
-- function val.gen_recurse(obj)
--    if cache[obj] then return cache[obj] end
--    local e = getfenv(obj)
--    local dbg_out_old = val.dbg_out
--    val.dbg_out = ""
--    breaker.setup(obj)
--    obj()
--    setfenv(obj,e)
--    local new_dbg_out = val.dbg_out
--    val.dbg_out = dbg_out_old
--    cache[obj]=new_dbg_out
--    return new_dbg_out
-- end
-- local d = require("debugger");d.auto_where = true;d()
file()
-- print("--- reconstructed output:")
print(val.dbg_out)
