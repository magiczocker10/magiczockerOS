-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local p = peripheral
local modem={}
local blocked_types={monitor=true}
local cached={}
local translate={
	monitor="screen",
	screen="monitor"
}
function get_type(side)
	if p then
		return p.getType(side)
	elseif component then
		local tmp=component.type(side)
		return translate[tmp] or tmp
	else
		return nil
	end
end
local colorstest = {
	[1]=0xF0F0F0,   [2]=0xF2B233,   [4]=0xE57FD8,    [8]=0x99B2F2,
	[16]=0xDEDE6C,  [32]=0x7FCC19,  [64]=0xF2B2CC,   [128]=0x4C4C4C,
	[256]=0x999999, [512]=0x4C99B2, [1024]=0xB266E5, [2048]=0x3366CC,
	[4096]=0x7F664C,[8192]=0x57A64E,[16384]=0xCC4C4C,[32768]=0x000000
}
local cur_name=""
local function get_mon_device(name)
	local name=name
	local x,y=1,1
	local w,h=51,19
	local gpu=name and component.list("gpu")()
	local cur_colors={
		colorstest[32768], -- back
		colorstest[1] -- text
	}
	local function set_col(mode,col)
		if cur_name~=name then
			component.invoke(gpu,"bind",name)
			--component.invoke(gpu,"setResolution",w,h)
		end
		if cur_name~=name or mode=="back" and col and cur_colors[1]~=col then
			component.invoke(gpu,"setBackground",col or cur_colors[1])
		elseif cur_name~=name or mode=="text" and col and cur_colors[2]~=col then
			component.invoke(gpu,"setForeground",col or cur_colors[2])
		end
		if cur_name~=name then
			cur_name=name
		end
	end
   
	set_col()
	to_return={
		clear=function() set_col() component.invoke(gpu,"fill",1,1,w,h," ") end,
		setCursorPos=function(nx,ny) x=nx y=ny end,
		getCursorPos=function() return x,y end,
		getSize=function() set_col() return component.invoke(gpu,"getResolution") end,
		isColor=function() set_col() return true end, -- return component.invoke(gpu,"maxDepth")>1 and true or false
		setBackgroundColor=function(color) set_col("back",colorstest[color]) cur_colors[1]=colorstest[color] end,
		setTextColor=function(color) set_col("text",colorstest[color]) cur_colors[2]=colorstest[color] end,
		write=function(txt) if txt then set_col(true) component.invoke(gpu,"set",x,y,txt) x=x+#txt end end
	}
	to_return.isColour = to_return.isColor
	to_return.setTextColour = to_return.setTextColor
	to_return.setBackgroundColour = to_return.setBackgroundColor
	return to_return
end
function get_device(name)
	local to_return={}
	if p then
		local tmp=p.getMethods(name)
		for i=1,#tmp do
			to_return[tmp[i]]=function(...) return peripheral.call(name,tmp[i],...) end
		end
	elseif component then
		if get_type(name)=="monitor" then
			cached[name]=cached[name] or get_mon_device(name)
			to_return=cached[name]
		else
			to_return=component.proxy(name)
		end
	end
	return to_return
end
function get_devices(system,whitelist,...) -- whitelist: true/false
	local to_return={}
	local to_filter={}
	local whitelist=whitelist and true or false
	for k,v in next,{...} do
		if type(v)=="string" then
			to_filter[v]=true
		end
	end
	if p then
		local list=p.getNames()
		for i=1,#list do
			local tmp=p.getType(list[i]) or ""
			if (system or tmp~="monitor") and whitelist==(to_filter[tmp] or false) then
				to_return[#to_return+1]=list[i]
			end
		end
	elseif component then
		for k,v in next,component.list() do
			local tmp=translate[v] or v
			if (system or tmp~="monitor") and whitelist==(to_filter[tmp] or false) then
				to_return[#to_return+1]=k
			end
		end
	end
	return to_return
end
local function filter_monitor(list)
	for i=#list,1,-1 do
		local tmp = get_type(list[i])
		if tmp == "monitor" then
			table.remove(list,i)
		end
	end
	return list
end
set_block_modem = function(side,port)
	modem[1]=side
	modem[2]=port
end or nil
function create(is_system)
	if type(is_system) ~= "boolean" then
		is_system = false
	end
	local peri = {}
	peri.find = function(stype, func)
		local list=get_devices(is_system,true,stype)
		local to_return={}
		if func then
			for i=1,#list do
				local tmp=get_device(list[i])
				to_return[#to_return+1]=func(list[i],tmp) and list[i] or nil
			end
		else
			to_return = list
		end
		return unpack(to_return)
	end
	peri.getNames=function()
		return get_devices(true,false,not is_system and "monitor" or nil)
	end
	peri.isPresent=function(side)
		local tmp=get_type(side)
		if is_system or tmp and tmp~="monitor" then
			return true
		end
		return false
	end
	peri.getType=function(side)
		local tmp=get_type(side)
		if is_system or (tmp or "")~="monitor" then
			return tmp
		end
	end
	peri.getMethods=function(side)
		if is_system or (get_type(side) or "")~="monitor" then
			if p then
				return p.getMethods(side)
			else
				local to_return={}
				local tmp=get_device(side)
				for k,v in next,tmp do
					to_return[#to_return+1]=k
				end
				table.sort(to_return)
				return to_return
			end
		end
	end
	peri.wrap=function(side)
		if is_system or (get_type(side) or "")~="monitor" then
			return get_device(side)
		end
	end
	peri.call = function(side, _type, arg1, ...)
		local tmp = get_type(side) or ""
		if is_system or tmp ~= "monitor" then
			if type(_type) == "string" and _type == "getNamesRemote" then
				return filter_monitor(p.call(side, _type))
			elseif modem[1] and tmp == "modem" and type(_type)=="string" and _type == "close" and side == modem[1] and arg1==modem[2] then
				-- Do nothing
			else
				local tmp=get_device(side)
				if tmp[_type] then
					return tmp[_type](arg1, ...)
				end
			end
		end
		return nil
	end
	peri.native = function()
		return peri
	end
	for k, v in next, (p or {}) do
		if p and not peri[k] then
			peri[k] = v
		end
	end
	return peri
end