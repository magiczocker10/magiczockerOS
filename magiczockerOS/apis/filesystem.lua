-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local term=term or nil
local to_complete = {"isDir", "isReadOnly", "getSize", "getFreeSpace", "getDrive"}
local to_complete_ = {"copy", "move"}
local _peri_names = peripheral and peripheral.getNames
local _peri_type = peripheral and peripheral.getType
local _peri_call = peripheral and peripheral.call
local path_to_listen={}
local event_active=true
local write_modes = {w = true, wb = true, ab = true, a = true}
local function call_func(remote,is_remote,id,func,...)
	if is_remote and id and remote then
		return remote(id,func,...)
	else
		return fs[func](...)
	end
end
function find_in_string(str, data) -- string.find in older cc versions is broken :/
	local datalength = #data
	for i = 1, #str - datalength + 1 do
		if str:sub(i, i + datalength - 1) == data then
			return i, i + datalength - 1
		end
	end
	return nil
end
function get_path(path)
	path = (path or ""):gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "") .. "/"
	local cur_path={}
	for k in path:gmatch("[^/]+") do
		local tmp=k:gsub("^%s+",""):gsub("%s+$","")
		if tmp=="." then
		elseif (tmp:match("%.+") or "") == tmp then
			cur_path[#cur_path] = nil
		elseif #tmp>0 then
			cur_path[#cur_path + 1] = tmp
		end
	end
	return table.concat(cur_path, "/")
end
local function remove_root_path(rp, paths)
	rp = rp:gsub("/+", "/"):gsub("^/+", ""):gsub("/+$", "") .. "/"
	for i = 1, #paths do
		paths[i] = paths[i]:gsub("/+", "/"):gsub("^/+", "")
		if paths[i]:sub(1, #rp) == rp then
			paths[i] = paths[i]:sub(#rp + 1)
		end
	end
	return paths
end
local function getDrives()
	local drives = {}
	if _peri_names and _peri_type and _peri_call then
		local names = _peri_names()
		for i = 1, #names do
			if _peri_type(names[i]) == "drive" and _peri_call(names[i], "isDiskPresent") then
				drives[#drives + 1] = names[i]
			end
		end
	end
	return drives
end
local function addMissingFolders(path, normalPath,remote,is_remote,server_id)
	local items = call_func(remote,is_remote,server_id,"isDir",path) and call_func(remote,is_remote,server_id,"list",path) or {}
	if term then
		for i = 1, #items do
			if items[i] == "rom" then
				return items
			end
		end
	end
	if normalPath and normalPath == "" then
		if term then
			items[#items + 1] = "rom"
		end
		local drives = getDrives()
		for i = 1, #drives do
			items[#items + 1] = _peri_call(drives[i], "getMountPath")
		end
		table.sort(items)
	end
	return items
end
function rom_checking(path)
	local driveList = getDrives()
	local path_ = path or ""
	path_ = path_:gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "") .. "/"
	if term and path_:sub(1, 4) == "rom/" then
		return true
	end
	for i = 1, #driveList do
		local mount_path = _peri_call(driveList[i], "getMountPath") .. "/"
		if path_:sub(1, #mount_path) == mount_path then
			return true
		end
	end
	return false
end
function add_listener(path,methods)
	if path and methods then
		path_to_listen[path]={}
		local tmp = path_to_listen[path]
		for k in next,methods do
			tmp[k]=true
		end
	end
end
function remove_listener(path)
	path_to_listen[path]=nil
end
local function send_event(path,method)
	if event_active then
		local folder = find_in_string(path:reverse(), "/")
		folder = folder and path:sub(1, #path - folder) or ""
		local tmp = path_to_listen[folder]
		if tmp and tmp[method] then
			os.queueEvent("filesystem_changed",method,folder)
		end
	end
end
function create(root_path,is_remote,server_id)
	local filesystem = {}
	local remote
	local is_remote = server_id and is_remote or false
	local function call(is_remote,...)
		return call_func(remote,is_remote,server_id,...)
	end
	if not call(is_remote,"exists",root_path) then
		call(is_remote,"makeDir",root_path)
	end
	function filesystem.set_server(id)
		server_id=id
	end
	function filesystem.set_remote(data)
		remote = data
	end
	function filesystem.is_online(var)
		is_remote = var
	end
	function filesystem.set_root_path(path)
		root_path = path
	end
	function filesystem.get_root_path()
		return root_path
	end
	filesystem.exists = fs.exists and function(path)
		local path = get_path(path)
		local rc=rom_checking(path)
		local tmp = (not rc and root_path .. "/" or "") .. path
		send_event(tmp,"exists")
		return call(not rc and is_remote,"exists",tmp)
	end
	filesystem.list = fs.list and function(path)
		local path = event_active and get_path(path) or path
		local rc = rom_checking(path)
		local tmp = (not rc and root_path .. "/" or "") .. path
		send_event(tmp,"list")
		return addMissingFolders(tmp, path,remote,not rc and is_remote,server_id)
	end
	filesystem.delete = fs.delete and function(path)
		local path = get_path(path)
		local rc=rom_checking(path)
		path = rc and path or root_path .. "/" .. path
		if path == root_path .. "/desktop" then -- added for magiczockerOS
			return nil
		end
		send_event(path,"delete")
		return call(not rc and is_remote,"exists",path) and call(not rc and is_remote,"delete",path)
	end
	-- gsub-filter from https://github.com/JasonTheKitten/Mimic/blob/gh-pages/lua/pre-bios.lua
	filesystem.find=function(wildcard)
		event_active=false
		local to_return={}
		wildcard="^"..get_path(wildcard):gsub("^/+",""):gsub("/+","/"):gsub("*","[^/]-").."$"
		local fts={""} -- FoldersToSearch
		for k,v in next,fts do
			local files = filesystem.list(v)
			for j=1,#files do
				local tmp = v.."/"..files[j]
				tmp=tmp:gsub("^/+",""):gsub("/+$",""):gsub("/+","/")
				if filesystem.isDir(tmp) then
					fts[#fts+1]=tmp
				end
				if tmp:find(wildcard) then
					to_return[#to_return+1]=tmp
				end
			end
		end
		event_active=true
		return to_return
	end
	filesystem.combine = function(a, b)
		return get_path((a or "") .. (a and b and "/" or "") .. (b or ""))
	end
	filesystem.getDir = function(str)
		local tmp = get_path(str):gsub("/+$", "")
		local _found = find_in_string(tmp:reverse(), "/")
		return _found and tmp:sub(1, #tmp - _found) or ""
	end
	filesystem.getName = function(str)
		local tmp = "/" .. get_path(str):gsub("/+$", "")
		local _found = find_in_string(tmp:reverse(), "/")
		tmp = _found and tmp:sub(-_found + 1) or ""
		return #tmp == 0 and "root" or tmp
	end
	filesystem.isDriveRoot = fs and fs.isDriveRoot and function(path) -- added for support for CC-Tweaked 1.15.2
		local path = get_path(path)
		local rc = rom_checking(path)
		return call(not rc and is_remote,"isDriveRoot",rc and path or root_path .. "/" .. path)
	end or nil
	filesystem.makeDir = fs.makeDir and function(path)
		local path = get_path(path)
		local rc=rom_checking(path)
		local to_add=(rc and "" or root_path).."/"
		local tmp=""
		for k in path:gmatch("[^/]+") do
			if not call(not rc and is_remote,"exists",to_add..tmp..k) then
				call(not rc and is_remote,"makeDir",to_add..tmp..k)
				send_event(to_add..tmp..k,"delete")
			end
			tmp=tmp..k.."/"
		end
	end or nil
	filesystem.open = fs.open and function(path, mode)
		local path = get_path(path)
		local rc = rom_checking(path)
		local tmp = rc and path or root_path .. "/" .. path
		local file
		if not rc and is_remote then
			local content=(mode=="r" or mode == "rb" or mode=="a" or mode == "ab") and call(true,"get_file",path) or (mode=="w" or mode=="wb") and "" or nil
			local cursor=1
			local is_open=true
			local function check_open()
				if not is_open then
					return error("File closed!",0)
				end
			end
			file = content and {
				close=function()
					check_open()
					if write_modes[mode] then
						call(true,"send_file",path,content)
					end
					for k in next,file do
						file[k]=nil
					end
					is_open=false
				end,
				flush=write_modes[mode] and function()
					check_open()
					call(true,"send_file",path,content)
				end,
				read=(mode=="r" or mode=="rb") and function()
					check_open()
					local tmp = content:sub(cursor,cursor)
					cursor=cursor+1
					return mode=="rb" and tmp:byte() or tmp
				end,
				readAll=(mode=="r" or mode=="rb") and function()
					check_open()
					local tmp=content
					content=""
					return tmp
				end,
				readLine=(mode=="r" or mode=="rb") and function()
					check_open()
					local tmp1 = content:find("\n")
					if tmp1 then
						local tmp = content:sub(1,tmp1-1)
						content=content:sub(tmp1+2)
						return tmp
					elseif #content>0 then
						local tmp = content
						content=""
						return tmp
					end
				end,
				write=write_modes[mode] and function(txt)
					check_open()
					if (mode=="wb" or mode=="ab") and type(txt)=="number" then
						txt=txt:char()
					end
					content=content..txt
				end,
				writeLine=(mode=="w" or mode=="a") and function(txt)
					check_open()
					content=content..(#content>0 and "\n" or "")..txt
				end
			}
		elseif write_modes[mode] or fs.exists(tmp) then
			if write_modes[mode] then
				local tmpdir=filesystem.getDir(path)
				filesystem.makeDir(tmpdir)
			end
			file = fs.open(tmp, mode)
			if file then
				local org_close = file.close
				if write_modes[mode] then
					file.close = function() send_event(tmp,"open") org_close() end
				end
			else
				-- error(tmp)
				return false
			end
		else
			return false
		end
		return file
	end or nil
	filesystem.complete = function(file, parent_path, include_files, include_slashes)
		local to_return = {}
		local include_rom
		local file_table = {}
		local file = file or ""
		for k in (file..":"):gmatch("[^/]+") do
			file_table[#file_table+1]=k
		end
		if file:sub(1,1)=="/" then
			parent_path=""
		end
		file_table[#file_table]=file_table[#file_table]:sub(1,-2)
		if #file_table > 1 then
			file = file:sub(1,-find_in_string(file:reverse(),"/")-1)
		else
			file = ""
		end
		include_files = include_files == nil or include_files
		include_slashes = include_slashes == nil or include_slashes
		local tmp = file_table[#file_table]
		if parent_path ~= "" and (not tmp or tmp == "" or tmp == ".") then
			if include_slashes then
				to_return[#to_return + 1] = "."
			end
			to_return[#to_return + 1] = ".." .. (include_slashes and "" or "/")
		end
		local rc=rom_checking(get_path(parent_path .. "/" .. file))
		if not rc then
			local path = get_path(parent_path)
			parent_path = root_path .. "/" .. path
			include_rom = get_path(file) == ""
		end
		local _list = call(not rc and is_remote,"exists",parent_path .. "/" .. file) and call(not rc and is_remote,"isDir",parent_path .. "/" .. file) and call(not rc and is_remote,"list",parent_path .. "/" .. file) or {}
		if include_rom and term then
			_list[#_list + 1] = "rom"
			local drives = getDrives()
			for i = 1, #drives do
				_list[#_list + 1] = _peri_call(drives[i], "getMountPath")
			end
		end
		local tmp1 = file_table[#file_table]
		local _length = #tmp1
		local _temp
		for i = 1, #_list do
			_temp = include_rom and term and _list[i] == "rom" or call(not rc and is_remote,"isDir",parent_path .. "/" .. file .. "/" .. _list[i])
			if include_files or _temp then
				if #_list[i] >= _length and _list[i]:sub(1, _length) == tmp1 then
					tmp = _list[i]:sub(_length + 1)
					to_return[#to_return + 1] = tmp .. (_temp and "/" or "")
					if _temp and include_slashes then
						to_return[#to_return + 1] = tmp
					end
				end
			end
		end
		return to_return
	end
	for i = 1, #to_complete_ do -- copy / move
		local tmp = to_complete_[i]
		filesystem[tmp] = function(path1, path2)
			local file1=filesystem.open(path1,"r")
			local file2=filesystem.open(path2,"w")
			file2.write(file1.readAll())
			file1.close()
			file2.close()
			if tmp=="move" then
				filesystem.delete(path1)
			end
			return true
		end
	end
	for i = 1, #to_complete do
		if fs[to_complete[i]] then
			local tmp = to_complete[i]
			filesystem[tmp] = function(path)
				local path = event_active and get_path(path) or path
				local rc=rom_checking(path)
				path = rc and path or root_path .. "/" .. path
				send_event(path, tmp)
				return call(not rc and is_remote,tmp,path) 
			end
		end
	end
	return filesystem
end