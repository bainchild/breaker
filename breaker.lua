--WARN: upvalues WILL not be handled, unless their functions are also wrapped

---@diagnostic disable: deprecated, unused-local
local infos = {}
local val = require('val')
local b = {infos=infos,heirarchy={},recurse_exclude={},catch_failed_winds=true}
local function printa(...)
   print("[breaker]",...)
end
function b.set(func,hook,loud)
   -- hook is the function the sandbox called to initiate this breakpoint setting
   -- (so that you can later resume from it.)
   assert(infos[func]~=nil,"Function not set up!")
   assert(infos[func].enabled,"Not enabled for function!")
   local i = infos[func]
   local new = {vars={},hists={},func_envs={},hook=hook}
   for ni,v in next, i.vars do
      new.vars[ni]=rawget(v,"real")
      new.hists[ni]=rawget(v,"history_count")
      if type(rawget(v,"real"))=="function" and b.recurse_exclude[rawget(v,"real")]==nil and infos[rawget(v,"real")]==nil then
         if i.presetup_hook then
            i.presetup_hook(rawget(v,"real"))
         end
         b.setup(rawget(v,"real")).presetup_hook = i.presetup_hook
      end
      printa("save",ni,v)
   end
   i.points[#i.points+1] = new
   -- if val.dbg_out and loud~=false then val.dbg_out=val.dbg_out.."-- save point "..#i.points.."\n" end
   return #i.points
end
function b.apply(func,pi,loud)
   assert(infos[func]~=nil,"Function not set up!")
   local i = infos[func]
   local point = assert(i.points[pi],"Non-existant point")
   for ni,v in next, point.vars do
      printa("apply",ni,v)
      rawset(i.vars[ni],"real",v)
      rawset(i.vars[ni],"history_count",point.hists[ni] or 0)
      if i.enabled and not rawget(i.vars[ni],"action") then
         rawset(i.vars[ni],"action",true)
      end
   end
   -- if val.dbg_out and loud~=false then val.dbg_out=val.dbg_out.."-- apply point "..pi.."\n" end
end
function b.wind(func,pi,the)
   assert(infos[func]~=nil,"Function not set up!")
   local i = infos[func]
   local point = assert(i.points[pi],"Non-existant point")
   if point.hook==nil then printa("point has no hook, dead end."); return end
   assert(rawequal(getfenv(func),i.env),"Function's environment has changed since it was set up. (this would normally lead to an infinite loop)")
   b.apply(func,pi,false)
   for _i,_v in next, i.vars do printa("VAR PRINT",_i,_v) end
   local cought = false
   for _,v in next, i.vars do
      printa(rawget(v,"action"),rawget(v,"real"),"will be nilled:",not rawequal(rawget(v,"real"),point.hook))
      rawset(v,"history_count",1)
      if not rawequal(rawget(v,"real"),point.hook) then
         rawset(v,"action",false)
         rawset(v,"real",nil)
      else
         printa("this is the hook point, doin the hook stuff...")
         rawset(v,"action",true)
         local f = function() -- (args) does NOT matter
            printa("hit catch.")
            printa("real?")
            cought = true
            b.apply(func,pi)
            printa("hook type:",type(point.hook))
            rawset(v,"real",point.hook)
            the()
            -- for resuming execution controlled by the user
            -- (without coroutines)
            -- (this will cause stack pileup)
         end;
         b.recurse_exclude[f] = true
         rawset(v,"real",f)
      end
      printa("-> ",rawget(v,"action"),rawget(v,"real"),val.id(v))
   end
   i.enabled = true
   printa("start windup...")
   func() -- WARN: vararg not covered by sandbox
   printa("after wind")
   -- todo: a way to exit via error in the hooked function
   if not cought then
      if b.catch_failed_winds then
         error("Function did not call hook, wind failed.",3)
      else
         b.apply(func,pi)
      end
   end
end
function b.setup(func,loud,hook)
   if infos[func]~=nil then return infos[func] end
   if b.setup_hook and hook~=false then b.setup_hook(func) end
   infos[func] = {
      func=func,
      rawenv=getfenv(func),
      env=val.new_box(getfenv(func),0),
      vars=val.get_vals(),
      points={}
   }
   rawset(infos[func].env,"history_raw_name",true)
   setfenv(func,infos[func].env)
   b.enable(func)
   b.set(func,nil,false) -- starting...
   printa("init func",func)
   -- if val.dbg_out and loud~=false then val.dbg_out=val.dbg_out.."-- init function\n" end
   return infos[func]
end
function b.unsetup(func,hook)
   if infos[func]==nil then return end
   setfenv(func,infos[func].rawenv)
   if b.unsetup_hook and hook~=false then b.unsetup_hook(func) end
   for _,v in next, infos[func].vars do
      if type(rawget(v,"real"))=="function" and b.recurse_exclude[rawget(v,"real")]==nil then
         b.unsetup(rawget(v,"real"))
      end
   end
end
function b.enable(func,recreate)
   assert(infos[func]~=nil,"Function not set up!")
   infos[func].enabled = true
   for _,v in next, infos[func].vars do
      if not rawget(v,"action") then
         if recreate~=false then val.recreate(v) end
         rawset(v,"action",true)
      end
   end
end
function b.disable(func)
   assert(infos[func]~=nil,"Function not set up!")
   infos[func].enabled = false
   for _,v in next, infos[func].vars do
      rawset(v,"action",false)
   end
end
return b
