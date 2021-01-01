-- magiczockerOS - Copyright by Julian Kriete 2016-2021

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
local color_link = {}
for i = 0, 15 do
	color_link[2 ^ i] = i
end
local cur_name=""
local w, h = 51, 19
local function get_mon_device(name)
	local name, x, y, cur_colors = name, 1, 1, {15, 0}
	local gpu = name and component.list("gpu")()
	local function set_col(mode, col)
		if cur_name ~= name then
			component.invoke(gpu, "bind", name)
			local wm, hm = component.invoke(gpu,"maxResolution")
			local w_, h_ = 0, 0
			w_, h_ = w > wm and wm or w, h > hm and hm or h
			component.invoke(gpu, "setResolution", w_, h_)
		end
		if cur_name~=name or mode=="back" and col and cur_colors[1]~=col then
			component.invoke(gpu,"setBackground",col or cur_colors[1], true)
		elseif cur_name~=name or mode=="text" and col and cur_colors[2]~=col then
			component.invoke(gpu,"setForeground",col or cur_colors[2], true)
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
		setBackgroundColor=function(color) if color_link[color] then color = color_link[color] set_col("back",color) cur_colors[1]=color end end,
		setPaletteColor=function(a, b) if color_link[a] then component.invoke(gpu, "setPaletteColor", a, b) end end,
		setTextColor=function(color) if color_link[color] then color = color_link[color] set_col("text",color) cur_colors[2]=color end end,
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
		for k,v in next, component.list() do
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