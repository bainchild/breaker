---@diagnostic disable: deprecated
-- side project semi-related to breaker
local v = require('val')
local inspect = require("inspect")
local fp = require('formprint').global()
local function find(a,b)
   ---@diagnostic disable-next-line: redefined-local
   for i,v in next, a do
      if rawequal(v,b) then return i end
   end
   return nil
end
local function tab_rawequal(ta,ta2,hist)
   ---@diagnostic disable-next-line: redefined-local
   for i,v in next, ta do
      if type(v)~=type(ta2[i]) then
         return false
      end
      if hist~=nil and find(hist,v)~=nil then
         return false
      end
      if type(v)=="table" and not tab_rawequal(v,ta2[i],(hist and {unpack(hist),ta} or {ta})) then
         return false
      end
      if not rawequal(v,ta2[i]) then return false end
   end
   return true
end
local function dump(func)
   v.push()
   local val = v.new()
   val.default_actionable = false
   val.disregard_for_memory = true
   local env = getfenv(func)
   local venv = val.new_box(env,0)
   rawset(venv,"history_raw_name",true)
   setfenv(func,venv)
   function val.gen_recurse(fun)
      return dump(fun)
   end
   for _,v1 in next, val.get_vals() do
      rawset(v1,"action",false)
   end
   func()
   -- now the history is recordedi
   local function recur(node)
      if rawget(node,"history")==nil then
         return
      end
      print(":")
      fp:inc(4)
      for _,v1 in next, rawget(node,"history") do
         if v1[2]=="index" then
            fp:write(val.id(node).."["..inspect((val.boxed(v1[4]) and val.id(v1[4]) or v1[4])).."] ->",val.id(v1[3]))
            fp:inc(8)
            recur(v1[3])
            fp:dec(8)
         elseif v1[2]=="call" then
            if #v1>2 then
               fp:write(val.id(node).."(")
               local s=""
               for i=3,#v1 do
                  s=s..((i~=3 and ", " or "")..inspect((val.boxed(v1[i]) and val.id(v1[i]) or v1[i])))
               end
               io.write(s..")")
            else
               fp:write(val.id(node).."()")
            end
            fp:inc(3)
            local arjj = {unpack(v1,3)}
            local res,unused = {},0
            for _,v2 in next, rawget(node,"history") do
               if v2[2]=="call_ret" and tab_rawequal({unpack(v2,5)},arjj) then
                  if rawget(v2,"history")~=nil then
                     res[#res+1] = v2
                  else
                     unused=unused+1
                  end
               end
            end
            if unused~=0 then
               io.write(" ("..unused.." unused)")
            end
            if #res>0 then
               print(":")
               for _,v2 in next, res do
                  fp:write("->",val.id(v2[3]))
                  recur(v2[3])
               end
            elseif unused~=0 then
               print()
            end
            fp:dec(3)
         end
      end
      fp:dec(4)
   end
   fp:write(val.id(venv))
   recur(venv)
   v.pop()
end
return dump
