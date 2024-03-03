local fp = {}
function fp.new()
	return setmetatable({indent="",stack={}},{__index=fp})
end
function fp.global()
	local g = PM_G or _G or shared or (getfenv or function() return _ENV end)()
	local id = g and g.fp_global_indentation
	local st = g and g.fp_global_stack
	local ins = setmetatable({indent=id or "",stack=st or {},global=true},{__index=fp,__newindex=function(s,i,v)
		if i=="indent" then
			g.fp_global_indentation=v
		end
		return rawset(s,i,v)
	end})
	ins.indent=""
	g.fp_global_stack=ins.stack
	return ins
end
function fp:pop()
	self.indent=table.remove(self.stack,1)
end
function fp:push()
	table.insert(self.stack,1,self.indent)
	self.stack=self.stack
end
function fp:inc(amount,char)
	if amount==nil then amount=1 end
	if char==nil then char=" " end
	self.indent=self.indent..char:rep(amount)
end
function fp:dec(amount)
	if amount==nil then amount=1 end
	self.indent=self.indent:sub(1,-(amount+1))
end
function fp:print(...)
	local s,args = self.indent,{...}
	for _,v in pairs(args) do
		s=s.." "..tostring(v)
	end
	print(s)
end
function fp:write(...)
	local s,args = self.indent,{...}
	for _,v in pairs(args) do
		s=s.." "..tostring(v)
	end
	io.write(s)
end
return fp
