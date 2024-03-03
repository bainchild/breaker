---@diagnostic disable: deprecated
local vstk = {}
local v = {unbox={},dbg_out="",default_actionable=true,recurse_exclude={},disregard_for_memory=false,objs={},empty={},children={},ids={},idc=0}
local function printc(...)
   -- print("[val]",...)
end
-- todo: restructure
function v.push()
   table.insert(vstk,{v.dbg_out,v.objs,v.empty,v.children,v.ids,v.idc})
   return v
end
function v.pop()
   v.dbg_out,v.objs,v.empty,v.children,v.ids,v.idc = unpack(table.remove(vstk,#vstk))
   return v
end
function v.new()
   v.dbg_out,v.objs,v.empty,v.children,v.ids,v.idc = "",{},{},{},{},0
   return v
end
function v.new_box(obj,id)
   if obj==nil then obj={};v.empty[#v.empty+1]=obj end
   if v.objs[obj]==nil then
      v.objs[obj] = setmetatable({real=obj,action=v.default_actionable and v.empty[#v.empty]~=obj},{
         __index=function(self,b)
            if rawequal(b,v.unbox) then return rawget(self,"real") end
            printc("INDEX",rawget(self,"real"),rawget(self,"action"),v.id(self))
            if rawget(self,"action") then
               return v.new_child(rawget(self,"real")[(v.boxed(b) and b[v.unbox] or b)],self,"index",b)
            else
               return v.new_child(nil,self,"index",b)
            end
         end;
         __newindex=function(self,i,val)
            -- printc("NEWINDEX",rawget(self,"real"),rawget(self,"action"),v.id(self),v.id(i),v.id(val))
            if rawget(self,"action") then
               rawget(self,"real")[(v.boxed(i) and i[v.unbox] or i)]=(v.boxed(val) and val[v.unbox] or val)
            end
            v.add_to_history(self,"newindex",i,val)
         end;
         __call=function(self,...)
            -- printc("CALL",rawget(self,"action"),rawget(self,"real"),v.id(self))
            -- if type(rawget(self,"real"))=="table" then print("SELF",require("inspect")(rawget(self,"real"))) end
            v.add_to_history(self,"call",...)
            if rawget(self,"action") then
               local arjs = {...}
               for i,val in next, arjs do
                  arjs[i]=(v.boxed(val) and val[v.unbox] or val)
               end
               local rev = {rawget(self,"real")(unpack(arjs))}
               for i,val in next, rev do
                  rev[i] = v.new_child(val,self,"call_ret",i,...)
               end
               return unpack(rev)
            else
               if v.disregard_for_memory then
                  local rv = {}
                  for i=1,249 do
                     rv[i] = v.new_child(nil,self,"call_ret",i,...)
                  end
                  return unpack(rv)
               else
                  return v.new_child(nil,self,"call_ret",1,...)
               end
            end
         end;
         __add=function(a,b)
            if v.boxed(a) then
               if rawget(a,"action") then
                  return v.new_child(a[v.unbox]+(v.boxed(b) and b[v.unbox] or b),a,"add",b)
               end
            elseif v.boxed(b) then
               if rawget(b,"action") then
                  return v.new_child(b[v.unbox]+(v.boxed(a) and a[v.unbox] or a),b,"add",a)
               end
            end
            error("Why is this metamethod being called? (add on two non-boxed objects with boxed's metamethod)")
         end;
         __sub=function(a,b)
            if v.boxed(a) then
               if rawget(a,"action") then
                  return v.new_child(a[v.unbox]-(v.boxed(b) and b[v.unbox] or b),a,"sub",b)
               end
            elseif v.boxed(b) then
               if rawget(b,"action") then
                  return v.new_child(b[v.unbox]-(v.boxed(a) and a[v.unbox] or a),b,"sub",a)
               end
            end
            error("Why is this metamethod being called? (sub on two non-boxed objects with boxed's metamethod)")
         end;
         __mul=function(a,b)
            if v.boxed(a) then
               if rawget(a,"action") then
                  return v.new_child(a[v.unbox]*(v.boxed(b) and b[v.unbox] or b),a,"mul",b)
               end
            elseif v.boxed(b) then
               if rawget(b,"action") then
                  return v.new_child(b[v.unbox]*(v.boxed(a) and a[v.unbox] or a),b,"mul",a)
               end
            end
            error("Why is this metamethod being called? (mul on two non-boxed objects with boxed's metamethod)")
         end;
         __div=function(a,b)
            if v.boxed(a) then
               if rawget(a,"action") then
                  return v.new_child(a[v.unbox]/(v.boxed(b) and b[v.unbox] or b),a,"div",b)
               end
            elseif v.boxed(b) then
               if rawget(b,"action") then
                  return v.new_child(b[v.unbox]/(v.boxed(a) and a[v.unbox] or a),b,"div",a)
               end
            end
            error("Why is this metamethod being called? (div on two non-boxed objects with boxed's metamethod)")
         end;
         __tostring=function(self)
            return v.id(self)
         end;
         __thekeythatletsyouknowitsreal=v.unbox;
      })
   end
   if id then
      v.ids[id] = obj
   end
   return v.objs[obj]
end
function v.new_child(obj,parent,action,...)
   printc("new child",parent,"--"..action.."->",obj,...)
   local arggg = {...}
   for _,val in next, rawget(parent,"history") or {} do
      -- checking whether or not to return a possibly already done action's child
      -- v[1]==action        :  checks if it's the same action type
      -- action=="..."       :  checks if action type is eligable
      -- rawequal(v[3],(...)):  first argument the same?
      printc("child check args =",unpack(val,4))
      local same = true
      for i=4,#val do
         if not rawequal(val[i],arggg[i-3]) then
            same=false
            break
         end
      end
      if val[1]==rawget(parent,"history_count") and val[2]==action and (action=="index" or action=="call" or action=="call_ret") and same then
         printc("child check SUCCESS")
         return val[3]
      else
         printc("child check",val[1],rawget(parent,"history_count"),val[2],action,"&",same)
      end
   end
   local n = v.new_box(obj)
   rawset(n,"parent",parent)
   if v.children[parent]==nil then v.children[parent]={} end
   v.children[parent][#v.children[parent]+1] = n
   v.add_to_history(parent,action,n,...)
   return n
end
function v.add_to_history(ob,act,...)
   printc("ADD TO HISTORY",ob,act,...)
   local ar = {...}
   local hist = rawget(ob,"history")
   if hist==nil then rawset(ob,"history",{});hist=rawget(ob,"history") end
   printc("history vals vs.",rawget(ob,"history_count"),act,...)
   for _,val in next, hist do
      printc("history val:",val[1],val[2],val[3],val[4])
      local same = true
      for i=4,#val do
         printc("history val check",val[i],"==",ar[i-2],"(",rawequal(val[i],ar[i-2]),")")
         if not rawequal(val[i],ar[i-2]) then
            same=false
            break
         end
      end
      if val[1]==rawget(ob,"history_count") and val[2]==act and (act=="index" or act=="call" or act=="call_ret") and same then
         printc("history val SUCCESS")
         return
      else
         printc("history val failed",val[1]==rawget(ob,"history_count"),val[2]==act,(act=="index" or act=="call" or act=="call_ret"),same)
      end
   end
   rawset(ob,"history_count",(rawget(ob,"history_count") or 0)+1)
   hist[#hist+1] = {rawget(ob,"history_count"),act,...}
   if true then return end -- in theory, out of scope V
   -- local id = #v.dbg_out
   if act=="index" then
      -- ob = parent
      -- ar[1] = resulting child
      -- ar[2] = idx

      -- if v.id(ob)==0 then
      --    print("GETGLOBAL "..v.id(ar[1]).." "..const(ar[2]))
      -- else
      --    print("GETTABLE "..v.id(ar[1]).." "..v.id(ob).." "..allocpc(ar[2]))
      -- end
      if rawget(ob,"history_raw_name") then
         v.dbg_out=v.dbg_out..("local "..v.id(ar[1]).."="..v.id(ar[2],false).."\n")
      else
         v.dbg_out=v.dbg_out..("local "..v.id(ar[1]).."="..v.id(ob).."["..v.id(ar[2]).."]\n")
      end
   elseif act=="newindex" then
      -- if v.id(ob)==0 then
      --    print("SETGLOBAL "..const(ar[1]).." "..allocpc(ar[2]))
      -- else
      --    print("SETTABLE "..v.id(ob).." "..allocpc(ar[1]).." "..allocpc(ar[2]))i
      if rawget(ob,"history_raw_name") then
         v.dbg_out=v.dbg_out..(v.id(ar[1],false).." = "..v.id(ar[2]).."\n")
      else
         v.dbg_out=v.dbg_out..(v.id(ob).."["..v.id(ar[1]).."] = "..v.id(ar[2]).."\n")
      end
      -- end
   elseif act=="call" then
      -- ob = callee
      -- ar = args
      local rvids = {}
      for i,val in next, ar do
         rvids[i] = v.id(val)
      end
      v.dbg_out=v.dbg_out..("local _cr"..v.id(ob).."={"..v.id(ob).."("..table.concat(rvids,",")..")}\n")
   elseif act=="call_ret" then
      v.dbg_out=v.dbg_out..("local "..v.id(ar[1]).."=_cr"..v.id(ob).."["..v.id(ar[2]).."]\n")
   end
   -- if true then print(v.dbg_out:sub(id+1,-2)) end
end
function v.id(obj,noquote)
   if rawequal(obj,nil) then return "nil" end
   if type(obj)=="function" and v.gen_recurse and not v.recurse_exclude[obj] then
      -- best named function...
      local olbjs,oldempty,oldchildren,oldids,oldidc = v.objs,v.empty,v.children,v.ids,v.idc
      v.objs,v.empty,v.children,v.ids,v.idc = {},{},{},{},0
      local rt = "function(...)\n"..v.gen_recurse(obj).."end"
      v.objs,v.empty,v.children,v.ids,v.idc = olbjs,oldempty,oldchildren,oldids,oldidc
      return rt
   end
   if type(obj)=="string" and noquote~=false then return "'"..obj.."'" end
   if not v.boxed(obj) then return tostring(obj) end
   local found = nil
   ---@diagnostic disable-next-line: redefined-local
   for i,v in next, v.ids do if rawequal(v,obj) then found=i;break end end
   if found==nil then v.ids[v.idc]=obj;found=v.idc;v.idc=v.idc+1; end
   -- print(rawequal(ids[found],nil),found,idc)
   return "_"..found
end
function v.boxed(a)
   return type(a)=="table" or type(a)=="userdata"
      and getmetatable(a)~=nil and type(getmetatable(a))=="table"
      and rawequal(getmetatable(a).__thekeythatletsyouknowitsreal,v.unbox)
end
function v.get_vals()
   return v.objs
end
function v.recreate(obj,sides)
   if not v.boxed(obj) then return -2 end
   if not rawequal(rawget(obj,"real"),nil) then
      return 0
   end
   -- can't really solve anything without the parent to base it off of
   if rawequal(rawget(obj,"parent"),nil) then
      return -1
   end
   v.recreate(rawget(obj,"parent")) -- ensure parent has a real value
   for _,val in next, rawget(rawget(obj,"parent"),"history") or {} do
      if rawequal(val[3],obj) then
         printc("recreation action:",val[2]," + ",val[4])
      end
   end
   if sides and v.children[obj] then
      for _,child in next, v.children[obj] do
         v.recreate(child,true)
      end
   end
end
-- function v.reset_gen()
--    protos={}
-- end
return v
