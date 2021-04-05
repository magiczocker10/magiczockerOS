-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
if component then
	os.queueEvent=computer.pushSignal
	-- https://oc.cil.li/topic/1793-how-to-mount-filesystem-component-without-openos/?do=findComment&comment=8263
	for k,v in next,component.list("filesystem",true) do
		fs=component.proxy(k)
		if fs.slot>0 then
			break
		end
	end
	local function get_file_system(file)
		for a in component.list("filesystem") do
			if component.invoke(a, "exists", file or "/init.lua") then
				return a
			end
		end
		return computer.getBootAddress() or nil
	end
	local function prepare_path(path)
		path = (path .. "/"):gsub("^/+", ""):gsub("/+", "/")
		local path_part = path:find("/")
		local drive = path_part and path:sub(1, path_part - 1) or nil
		if drive and drive:find("-") then
			path = path:sub(#drive + 1)
			path = path:gsub("^/+", "")
		else
			drive = nil
		end
		return drive, "/" .. path
	end
	local function get_file_content(dr,da)
		local to_return = ""
		while true do
			local tmp = component.invoke(dr, "read", da, 1024)
			if tmp then
				to_return = to_return .. tmp
			else
				break
			end
		end
		return to_return
	end
	fs = {
		exists = function(path)
			local drive, path = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			return component.invoke(drive, "exists", path)
		end,
		isReadOnly = function(path)
			local drive, path = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			return component.invoke(drive, "isReadOnly", path)
		end,
		isDir = function(path)
			local drive, path = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			if path == "/" then
				return true
			end
			return component.invoke(drive, "isDirectory", path)
		end,
		list = function(path)
			local drive, path2 = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			return component.invoke(drive, "list", path2 or "/")
		end,
		makeDir = function(path)
			local drive, path = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			if drive then
				component.invoke(drive, "makeDirectory", path)
			end
		end or nil,
		open = function(path, mode)
			local drive, path = prepare_path(path)
			drive = drive or get_file_system("/init.lua")
			local file = ({component.invoke(drive, "open", path, mode)})[1]
			if not file then
					return false
			end
			local is_opened = true
			local content = mode == "r" and get_file_content(drive,file) or nil
			local content_ = content
			return {
				close = function()
					if is_opened then
						is_opened = false
						component.invoke(drive, "close", file)
					end
				end,
				readAll = mode == "r" and function()
					if is_opened then
						return content
					end
				end or nil,
				readLine = mode == "r" and function()
					if is_opened and content_ then
						local text = ({content_:find("\n")})[1]
						if text then
							local __ = content_:sub(1, text - 1)
							content_ = content_:sub(text + 1)
							return __
						else
							local __ = content_
							content_ = nil
							return __
						end
					end
				end or nil,
				write = mode == "w" and function(content)
					if is_opened then
						component.invoke(drive, "write", file, (content or ""))
					end
				end or nil,
				writeLine = mode == "w" and function(content)
					if is_opened then
						component.invoke(drive, "write", file, (content or "") .. "\n")
					end
				end or nil,
			}
		end,
	}
end
loadstring = load
local file, err = fs.open("/magiczockerOS/core.lua", "r")
if err then
	error("/magiczockerOS/core.lua: File not exists", 0)
end
local filecontent = file.readAll()
file.close()
local content, err=load(filecontent, "@/magiczockerOS/core.lua")
if content then
	local ok, err = xpcall(function() return content() end, function(_) return _ end)
	if not ok then
		if err and err ~= "" then
			error(err, 0)
		end
		return
	end
	return true
end
if err and err ~= "" then
	error(err, 0)
end