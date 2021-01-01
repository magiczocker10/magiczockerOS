-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
-- variables
local term = term
local textutils = textutils
local component = component
local peripheral = peripheral
local fs = fs
local w, h = term.getSize()
local changelog_scroll = 0
local color_selection = math.random(1, 4)
local menu_open = false
local menu_scroll = 0
local menu_selection = 1
local menu_width = 0
local menu_select = not term.isColor and "-" or term.isColor() and " " or textutils and type(textutils.complete) == "function" and " " or "-"
local name = "Server"
local offset = 0
local running = true
local timer
local version = "Ver. 1.0"
local view = 0 -- 0-1 = list; 2 = textfield
local key_maps = {}
local items
local filter = ""
local list_scroll = 0
local selected = ""
local cursor = 0
local is_blackwhite = not term.isColor or not term.isColor()
local use_old
local my_computer_id = os and os.getComputerID and os.getComputerID() or nil
local server_folder_name = "magiczockerOS_server"
local my_protocol_name = "magiczockerOS-server"
local max_file_size = 30000
local cur_view
local filter_items
-- tables
local changelog = {
	"(c) magiczocker", 
	"", 
	"Version 1.0", 
	" First release", 
}
local cache = {}
local menu = {
	[0] = {func = function() view = -1 end}, 
	[1] = {txt = "Reload", func = function() cache.items = nil end}, 
	[2] = {txt = "Close", func = function() running = false end},
}
local views = {"list", "field"}
views[0] = "list"
local active_sessions = {}
local drive_blacklist = {}
local cached_settings = {}
local theme = {top = {128, 2, 2048, 512}, bottom = {256, 16, 8, 8}}
local random_areas = {{48, 57}, {65, 90}, {97, 122}}
local available_sides = {"top", "bottom", "left", "right", "front", "back"}
local modem_side
local loaded_drives
-- functions
local function _ceil(a)
	local b = a % 1
	return ("%.0f"):format(a + (b > 0 and 1 or 0) - b) + 0
end
local function _floor(a)
	return ("%.0f"):format(a - a % 1) + 0
end
local function toggle_menu(new_state)
	menu_open = new_state
	timer = os.startTimer(0)
end
local function background_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function write_text(a, b, c, d)
	term.write(not term.isColor and a or term.isColor() and d or textutils and type(textutils.complete) == "function" and c or b)
end
local function fallback_serialise(data, processed)
	local processed = processed or {}
	local seen = {}
	local to_return = ""
	if type(data) == "string" then
		return ("%q"):format( data )
	elseif type(data) == "number" or type(data) == "boolean" then
		return data
	elseif type(data) ~= "table" then
		error("Can't serialize type \"" .. type(data) .. "\"!")
	end
	for k, v in next, data do
		if not seen[k] and not processed[v] then
			processed[v] = processed[v] or type(v) == "table"
			seen[k] = true
			local _k = k
			local serialised = fallback_serialise(v, processed)
			if type(_k) == "string" then
				_k = ("%q"):format( _k )
			end
			to_return = to_return .. (#to_return == 0 and "" or ", ") .. "[" .. _k .. "]=" .. tostring(serialised)
		end
	end
	return "{" .. to_return .. "}"
end
local function send_message(side, receiver, content)
	if use_old then
		peripheral.call(side, "send", receiver, fallback_serialise(content))
	else
		peripheral.call(side, "transmit", receiver, 0, content)
	end
end
local function search_modem()
	modem_side = ""
	if component then
		for a in component.list("modem") do
			modem_side = a
			my_computer_id = a
			break
		end
	else
		for i = 1, #available_sides do
			if peripheral.getType(available_sides[i]) == "modem" then
				modem_side = available_sides[i]
				break
			end
		end
	end
	if #modem_side > 0 then
		if component then
			component.invoke(modem_side, "open", 65535)
		else
			peripheral.call(modem_side, "open", my_computer_id)
		end
	else
		background_color(32768, 32768, 32768)
		text_color(1, 1, 1)
		term.setCursorPos(1, 1)
		error"Please attach a modem."
	end
end
local function load_drives()
	loaded_drives = {}
	if component then
		for a in component.list("disk_drive") do
			loaded_drives[#loaded_drives + 1] = component.invoke(a, "media")
		end
	else
		if not peripheral then
			error("Please use ComputerCraft 1.2 or newer.")
		end
		local sides = peripheral.getNames and peripheral.getNames() or {"bottom", "top", "back", "front", "right", "left"}
		for i = #sides, 1, -1 do
			for j = 1, #drive_blacklist do
				if sides[i] == drive_blacklist[j] then
					for k = i, #sides - 1 do
						sides[k] = sides[k + 1]
					end
					sides[#sides] = nil
				end
			end
		end
		for i = 1, #sides do
			if peripheral.getType(sides[i]) and peripheral.getType(sides[i]) == "drive" and peripheral.call(sides[i], "isDiskPresent") then
				loaded_drives[#loaded_drives + 1] = sides[i]
			end
		end
	end
	if #loaded_drives == 0 then
		error("Error:\n  No drive(s) found.", 0)
	end
end
local function get_file(path)
	local data_to_return = {}
	if type(path) == "string" then
		for i = 1, #loaded_drives do
			local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
			if fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/") and fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. "/") and fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/" .. path) then
				if fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. "/" .. path) then
					return true
				else
					local file = fs.open("/" .. mount_path .. "/" .. server_folder_name .. "/" .. path, "r")
					if file then
						for line in file.readLine do
							data_to_return[#data_to_return + 1] = line
						end
						file.close()
						return data_to_return
					end
				end
			end
		end
	end
	return false
end
local function get_random_code()
	local number = ""
	local number2
	for _ = 1, 10 do
		number2 = math.random(0, 2)
		number = number .. ("" .. math.random(random_areas[number2 + 1][1], random_areas[number2 + 1][1])):char()
	end
	return number
end
local function seperate_path(path)
	local content_to_return = {}
	path = path:gsub("\\", "/")
	for k in path:gmatch("[^/$] + ") do
		content_to_return[#content_to_return + 1] = k
	end
	return content_to_return
end
local function get_all_copies(path)
	local content_to_return = {}
	for i = 1, #loaded_drives do
		local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
		if fs.exists("/" .. mount_path .. "/" .. path) then
			local file
			if not fs.isDir("/" .. mount_path .. "/" .. path) then
				file = fs.open("/" .. mount_path .. "/" .. path, "r")
			end
			content_to_return[mount_path] = file and not fs.isDir("/" .. mount_path .. "/" .. path) and #file.readAll() or 500
			if file then
				file.close()
			end
		end
	end
	return content_to_return
end
local function add_file(path, content, ...)
	path = (path or ""):gsub("/ + $", "")
	if type(path) == "string" and type(content) == "string" and #content <= max_file_size and path ~= "/" and #path > 0 then
		local copies = get_all_copies("/" .. server_folder_name .. "/" .. path)
		local path_pieces = seperate_path(path)
		local needed_space = 0
		local path_to_check = ""
		local wants_to_check = {...}
		local file_exists = {}
		local choosen_drive
		local need_exists
		for i = 1, #wants_to_check do
			if type(wants_to_check[i]) == "boolean" then
				need_exists = wants_to_check[i]
			else
				file_exists[wants_to_check[i]] = {false, need_exists}
			end
		end
		for i = 1, #loaded_drives do
			if not choosen_drive then
				local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
				local tmp = fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/")
				needed_space = #content + (not tmp and 500 or 0)
				path_to_check = ""
				if not (tmp and not fs.isDir("/" .. mount_path .. "/" .. server_folder_name)) then
					for j = 1, #path_pieces do
						path_to_check = path_to_check .. "/" .. path_pieces[j]
						if not fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/" .. path_to_check) or not fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. "/" .. path_to_check) and j ~= #path_pieces then
							needed_space = needed_space + (#path_pieces - j + 1) * 500 - (copies[mount_path] or 0)
							if needed_space < 0 then
								needed_space = 0
							end
							break
						end
					end
					if fs.getFreeSpace("/" .. mount_path) >= needed_space then
						choosen_drive = mount_path
					end
					for k in next, file_exists do
						if not file_exists[k][1] and fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/" .. k) then
							file_exists[k][1] = true
						end
					end
				end
			end
		end
		for k in next, file_exists do
			if file_exists[k][1] ~= file_exists[k][2] then
				return false
			end
		end
		if choosen_drive then
			local cdrive = choosen_drive
			local file = fs.open("/" .. cdrive .. "/" .. server_folder_name .. "/" .. path, "w")
			if file then
				file.write(content)
				file.close()
			else
				return false
			end
			for j = 1, #path_pieces do
				local tmp = table.concat(path_pieces, "/", 1, j)
				if fs.exists("/" .. cdrive .. "/" .. server_folder_name .. "/" .. tmp) then
					if not fs.isDir("/" .. cdrive .. "/" .. server_folder_name .. "/" .. tmp) and j ~= #path_pieces then
						fs.delete("/" .. cdrive .. "/" .. server_folder_name .. "/" .. tmp)
					end
				else
					break
				end
			end
			copies[cdrive] = nil
			for k in next, copies do
				for i = #path_pieces, 1, -1 do
					local sPath = "/" .. k .. "/" .. server_folder_name .. "/" .. table.concat(path_pieces, "/", 1, i)
					if fs.exists(sPath) and (not fs.isDir(sPath) or #fs.list(sPath) == 0) then
						fs.delete(sPath)
					else
						break
					end
					if #fs.list("/" .. k .. "/" .. server_folder_name) == 0 then
						fs.delete("/" .. k .. "/" .. server_folder_name)
					end
				end
			end
			return cdrive
		end
	end
	return false
end
local function check_sessioncode(user, id, code)
	if type(user) == "string" and type(code) == "string" then
		return active_sessions[id] and active_sessions[id][user] and (active_sessions[id][user].code or "") == code or false
	end
	return false
end
local function get_items()
	local to_return = {}
	if view == 0 then
		if not cache.items or #cache.items == 0 then
			cache.cache = {}
			cache.items = cache.items or {}
			for i = 1, #loaded_drives do
				local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
				if fs.exists("/" .. mount_path .. "/" .. server_folder_name .. "/usernames/") and fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. "/usernames/") then
					local _files = fs.list("/" .. mount_path .. "/" .. server_folder_name .. "/usernames/") or {}
					for j = 1, #_files do
						if not cache.cache[_files[j]] and not fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. "/usernames/" .. _files[j]) then
							local file = fs.open("/" .. mount_path .. "/" .. server_folder_name .. "/usernames/" .. _files[j], "r")
							if file then
								cache.cache[_files[j]] = file.readLine() or ""
								cache.items[#cache.items + 1] = _files[j]
								file.close()
							end
						end
					end
				end
			end
		end
		table.sort(cache.items)
		to_return[1] = {"New user", function() cur_view = "newuser" view = 2 end}
		for i = 1, #cache.items do
			to_return[#to_return + 1] = {cache.items[i], function() selected = cache.items[i] view = 1 end}
		end
	elseif view == 1 then -- cache.cache[selected]
		to_return[#to_return + 1] = {"Change Password", function() cur_view = "chpass" view = 2 end}
		to_return[#to_return + 1] = {"Change Username", function() cur_view = "chname" view = 2 end}
		to_return[#to_return + 1] = {
		"Delete",
		function()
			view = 0
			local paths = {
				"/" .. server_folder_name .. "/userfiles/" .. cache.cache[selected], 
				"/" .. server_folder_name .. "/usernames/" .. selected, 
				"/" .. server_folder_name .. "/userpasswords/" .. cache.cache[selected], 
			}
			for i = 1, #loaded_drives do
				local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
				for i = 1, #paths do
					if fs.exists("/" .. mount_path .. paths[i]) then
						fs.delete("/" .. mount_path .. paths[i])
					end
				end
			end
			cache.items = {}
			items = filter_items(filter)
		end, }
	else -- view == 2
		if cur_view == "newuser" then
			to_return[#to_return + 1] = {watermark = "Username", text = "", cursor = 1, offset = 0}
			to_return[#to_return + 1] = {watermark = "Password", text = "", cursor = 1, offset = 0}
			to_return[#to_return + 1] = {watermark = "Repeat Password", text = "", cursor = 1, offset = 0}
		else
			to_return[#to_return + 1] = {watermark = cur_view == "chpass" and "New Password" or "New Name", text = "", cursor = 1, offset = 0}
		end
	end
	return to_return
end
local function correct_scroll()
	if list_scroll > 0 then
		if cursor * 3 + 6 - list_scroll + (cursor > #items and 2 or 0) > h then
			list_scroll = cursor * 3 + 6 + (cursor > #items and 2 or 0) - h
		elseif (cursor - 1) * 3 - list_scroll < 1 then
			list_scroll = (cursor - 1) * 3 + 1
		end
	end
end
function filter_items(filter)
	local filter = filter:lower()
	local to_return = {}
	local data = get_items()
	for _, v in next, data do
		if views[view] == "field" or #filter == 0 or v[1]:lower():match(filter) then
			to_return[#to_return + 1] = v
		end
	end
	list_scroll = 0
	cursor = is_blackwhite and 1 or 0
	return to_return
end
local function draw_text_line(blink)
	local cur_textfield = items[cursor] or {}
	local y = (cursor - 1) * 3 + 6
	if y - list_scroll < 4 then
		return
	end
	term.setCursorPos(offset + 3, y - list_scroll)
	background_color(1, 128, theme.top[color_selection])
	text_color(1, 1, 1)
	local tmp = cur_textfield.text or ""
	tmp = #tmp == 0 and cur_textfield.watermark or tmp
	term.write((tmp .. ((not term.isColor or not term.isColor()) and "_" or " "):rep(w - 3)):sub(1 + cur_textfield.offset, w - 3 + cur_textfield.offset))
	if blink then
		term.setCursorPos(3 - 1 + offset + cur_textfield.cursor - cur_textfield.offset, y - list_scroll)
		term.setCursorBlink(true)
	end
end
local function set_cursor(blink, not_draw)
	local cur_textfield = items[cursor] or {}
	if cur_textfield.cursor - 1 > #cur_textfield.text then
		cur_textfield.cursor = #cur_textfield.text + 1
	end
	if cur_textfield.cursor <= cur_textfield.offset then
		cur_textfield.offset = cur_textfield.cursor - 1
	elseif cur_textfield.cursor > w - 5 + cur_textfield.offset then
		cur_textfield.offset = cur_textfield.cursor - w + 5
	end
	if cur_textfield.offset < 0 then
		cur_textfield.offset = 0
	end
	if not not_draw then
		draw_text_line(blink)
	end
end
local function save()
	if cur_view == "chpass" then
		local tmp = "/userpasswords/" .. cache.cache[selected]
		if add_file(tmp, items[1].text, true, tmp) then
			view = 0
		end
	elseif cur_view == "newuser" then
		if #items[1].text > 0 and items[2].text == items[3].text then
			local tmp = get_random_code()
			if add_file("/usernames/" .. items[1].text, tmp, false, "/usernames/" .. items[1].text, "/userpasswords/" .. tmp) and add_file("/userpasswords/" .. tmp, items[2].text) then
				view = 0
				cache.items = {}
				items = filter_items(filter)
			end
		end
	else -- chname
		local tmp1 = "/usernames/" .. items[1].text
		local tmp2 = "/usernames/" .. cache.cache[selected]
		if add_file(tmp1, items[1].text, true, tmp2) then
			view = 0
			cache.items = {}
			items = filter_items(filter)
		end
	end
end
local function draw_bottom()
	term.setCursorBlink(false)
	background_color(32768, 256, theme.bottom[color_selection])
	text_color(1, 1, 1)
	local _width = (" "):rep(w)
	for i = (views[view] or "") == "list" and 6 or 4, h do
		term.setCursorPos(1 + offset, i)
		local tmp = (views[view] or "") == "field" and (i - 4 + list_scroll) % 3 or (views[view] or "") == "list" and (i - 6 + list_scroll) % 3 or 0
		local tmprow = (views[view] or "") == "field" and _ceil((i - 4 + list_scroll) / 3) or (views[view] or "") == "list" and _ceil((i - 6 + list_scroll) / 3) or 0
		if items[tmprow] then
			local is_sel = cursor == tmprow
			text_color(32768, is_sel and 1 or 128, is_sel and 1 or 128)
			write_text(is_sel and ">" or " ", " ", " ", " ")
			background_color(1, is_sel and 128 or 1, is_sel and theme.top[color_selection] or 1)
			if tmp == 2 then
				local tmp = views[view] == "field" and items[tmprow].text or items[tmprow][1]
				if views[view] == "field" then
					if #tmp == 0 then
						text_color(32768, is_sel and 1 or 256, is_sel and 1 or 256)
						tmp = items[tmprow].watermark or ""
					end
					tmp = tmp:sub(items[tmprow].offset + 1)
				end
					term.write((" " .. tmp .. _width):sub(1, w - 3))
			elseif tmp == 0 and items[tmprow + 1] and (cursor == 0 or is_blackwhite or not (is_sel or cursor == tmprow + 1)) then
				text_color(32768, 256, 256)
				term.write(("_"):rep(w - 3))
			else
				term.write(_width:sub(4))
			end
			background_color(32768, 256, theme.bottom[color_selection])
			if tmprow > 1 or tmp ~= 1 then
				background_color(32768, 128, 128)
				write_text("|", " ", " ", " ")
			else
				term.write" "
			end
			background_color(32768, 256, theme.bottom[color_selection])
			write_text(is_sel and "<" or " ", " ", " ", " ")
		elseif view >= 0 and not items[tmprow] and items[tmprow - 1] and tmp == 1 then
			term.write"  "
			background_color(32768, 128, 128)
			local tmp = _width:sub(4)
			write_text(("-"):rep(w - 5) .. " ", tmp, tmp, tmp)
			background_color(32768, 256, theme.bottom[color_selection])
			term.write" "
		elseif view >= 0 and (views[view] or "") == "field" and (items[tmprow - 1] and not items[tmprow] and tmp < 2 or items[tmprow - 2] and not items[tmprow - 1] and tmp > 0) then
			term.write(_width:sub(1, -8))
			term.setTextColor(1)
			background_color(1, 128, theme.top[color_selection])
			term.write((is_blackwhite and cursor > #items and "-" or " ") .. (tmp == 1 and "Save" or (cursor > #items and "----" or "    ")) .. (is_blackwhite and cursor > #items and "-" or " "))
			background_color(32768, 256, theme.bottom[color_selection])
			term.write" "
		else
			term.write(_width)
		end
	end
	if (views[view] or "") == "field" and cursor > 0 and cursor <= #items then
		term.setCursorPos(items[cursor].cursor - items[cursor].offset + 2 + offset, (cursor - 1) * 3 + 6 - list_scroll)
		text_color(32768, 1, 1)
		term.setCursorBlink(true)
	end
end
local function draw_changelog()
	local _width = (" "):rep(w)
	background_color(32768, 256, theme.bottom[color_selection])
	text_color(1, 1, 1)
	term.setCursorPos(1 + offset, 4)
	term.write(_width)
	for i = 5, h - 1 do
		term.setCursorPos(1 + offset, i)
		term.write(changelog[i - 4 + changelog_scroll] and " " .. changelog[i - 4 + changelog_scroll] .. _width or _width)
	end
	term.setCursorPos(1 + offset, h)
	term.write(_width)
end
local function draw_menu()
	for a = 1, h do
    term.setCursorPos(1, a)
    if offset > 0 then
			local d
			if a > 1 and a < h - 2 and menu[a - 1 + menu_scroll] then
				text_color(32768, a - 1 + menu_scroll == menu_selection and 1 or 256, 1)
				local c = (menu_width - #menu[a - 1 + menu_scroll].txt) * 0.5
				d = (a - 1 + menu_scroll == menu_selection and menu_select or " ") .. (" "):rep(_floor(c) - 1) .. menu[a - 1 + menu_scroll].txt .. (" "):rep(_ceil(c) - 1) .. (a - 1 + menu_scroll == menu_selection and menu_select or " ")
			elseif a == h - 1 then
				text_color(32768, 0 == menu_selection and 1 or 256, 1)
				local c = (menu_width - #version) * 0.5
				d = (0 == menu_selection and menu_select or " ") .. (" "):rep(_floor(c) - 1) .. version .. (" "):rep(_ceil(c) - 1) .. (0 == menu_selection and menu_select or " ")
			else
				d = (" "):rep(offset)
			end
			background_color(1, 128, 128)
			term.write(d:sub(-offset))
    end
	end
end
local function draw_top()
	local _width = (" "):rep(w)
	background_color(1, 128, theme.top[color_selection])
	text_color(32768, 1, 1)
	term.setCursorPos(1 + offset, 1)
	term.write(_width)
	term.setCursorPos(1 + offset, 2)
	if view == -1 or view > 0 then
		term.write(" < " .. name .. (#selected > 0 and " - " .. selected or "") .. _width)
	else
		term.write(" = " .. name .. _width)
	end
	if (views[view] or "") == "list" then
		term.setCursorPos(1 + offset, 3)
		term.write(_width)
		term.setCursorPos(1 + offset, 4)
		text_color(32768, 256, theme.bottom[color_selection])
		term.write(" " .. (#filter > 0 and filter:sub(-w + 2) or "Type to search .. ") .. _width)
	end
	term.setCursorPos(1 + offset, (views[view] or "") == "list" and 5 or 3)
	write_text(("_"):rep(w), _width, _width, _width)
end
local function set_menu_width()
	menu_width = 0
	for i = 1, #menu do
		if #menu[i].txt > menu_width then
			menu_width = #menu[i].txt
		end
	end
	if #version > menu_width then
		menu_width = #version
	end
	menu_width = menu_width + 2
end
-- start
do
	local a = tonumber(({(_HOST or ""):match("%s*(%S+)$"):reverse():sub(2):reverse():gsub("%.", "")})[1] or "") or 0 >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 258 or 15] = "tab"
	key_maps[a and 259 or 14] = "backspace"
	key_maps[a and 261 or 211] = "delete"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
if is_blackwhite then
	cursor = 1
end
search_modem()
local methods = peripheral and peripheral.getMethods(modem_side) or {}
for i = 1, #methods do
	if methods[i] == "send" then
		use_old = true -- version 1.2
		break
	end
end
load_drives()
items = filter_items(filter)
set_menu_width()
draw_top()
draw_bottom()
-- events
repeat
	local e, d, x, y, message = coroutine.yield() -- event, side, receiver, sender, data
	if type(message) == "string" then
		message = textutils.unserialize(message) or message
	end
	if e == "modem_message" and x == my_computer_id and type(message) == "table" and (message.protocol == "filetransfer-client" or message.protocol == "magiczockerOS-client") and type(message.mode) == "string" and type(message.my_id) == "number" then
		local to_return
		local answer_send = false
		local user_data = check_sessioncode(message.username, y, message.session_id) and active_sessions[y][message.username] or nil
		if message.mode == "login" then
			local tmp = get_file("/usernames/" .. message.username)
			if tmp then
				active_sessions[y] = active_sessions[y] or {}
				active_sessions[y][message.username] = {code = get_random_code(), usercode = tmp[1] or ""}
				message.data = {active_sessions[y][message.username].code}
			else
				message.data = {false}
			end
			message.success = true
		elseif not user_data then
		elseif message.mode == "execute" and message.command and (fs[message.command] or message.command == "send_file" or message.command == "get_file") then
			if message.command == "list" then
				local path = "/userfiles/" .. user_data.usercode .. "/" .. (message.data[1] or "/")
				to_return = {}
				for i = 1, #loaded_drives do
					local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
					if fs.exists("/" .. mount_path .. "/" .. server_folder_name .. path) and fs.isDir("/" .. mount_path .. "/" .. server_folder_name .. path) then
						local _files = fs.list("/" .. mount_path .. "/" .. server_folder_name .. path) or {}
						for j = 1, #_files do
							to_return[#to_return + 1] = _files[j]
						end
					end
				end
			elseif message.command == "isDir" then
				local tmp = get_file("/userfiles/" .. user_data.usercode .. "/" .. (message.data[1] or "/"))
				to_return = type(tmp) == "boolean"
			elseif message.command == "exists" then
				local tmp = message.data[1] == "/" or get_file("/userfiles/" .. user_data.usercode .. "/" .. (message.data[1] or "/"))
				to_return = tmp and true or false
			elseif message.command == "get_file" then
				local content = get_file("/userfiles/" .. user_data.usercode .. "/" .. (message.data[1] or "/"))
				if content then
					to_return = table.concat(content, "\n")
				end
			elseif message.command == "delete" then
				local path = "/userfiles/" .. user_data.usercode .. "/" .. (message.data[1] or "/")
				for i = 1, #loaded_drives do
					local mount_path = component and loaded_drives[i] or peripheral.call(loaded_drives[i], "getMountPath")
					if fs.exists("/" .. mount_path .. "/" .. server_folder_name .. path) then
						fs.delete("/" .. mount_path .. "/" .. server_folder_name .. path)
						to_return = true
					end
				end
			elseif message.command == "isReadOnly" then
				to_return = false
			elseif message.command == "getFreeSpace" then
				to_return = 12345 -- temporary
			elseif message.command == "send_file" then
				to_return = add_file("/userfiles/" .. user_data.usercode .. "/" .. message.data[1], message.data[2] or "")
			else
				to_return = false
			end
			if type(to_return) ~= "nil" then
				message.data = {to_return}
				message.success = true
			end
		elseif message.mode == "get_settings" then
			message.data = cached_settings[message.username] or {["desktop_back"] = 32}
			cached_settings[message.username] = message.data
			message.success = true
		elseif message.mode == "update_settings" then
			cached_settings[message.username] = message.data
			message.success = true
		end
		if not answer_send then
			message.protocol = message.protocol == "filetransfer-client" and "filetransfer-server" or my_protocol_name
			message.mode = message.mode .. "-answer"
			local tmp = message.return_id
			message.return_id = my_computer_id
			send_message(modem_side, tmp, message.success and message or {protocol = message.protocol, success = false})
		end
	elseif e == "char" then
		if (views[view] or "") == "list" then
			filter = filter .. d
			items = filter_items(filter)
			draw_top()
			draw_bottom()
		elseif items[cursor] then
			local tmp = items[cursor]
			tmp.text = tmp.text:sub(1, tmp.cursor - 1) .. d .. tmp.text:sub(tmp.cursor)
			tmp.cursor = tmp.cursor + 1
			set_cursor(true)
		end
	elseif e == "key" and (views[view] or "") == "field" and key_maps[d] and items[cursor] and (key_maps[d] == "backspace" or key_maps[d] == "delete" or key_maps[d] == "left" or key_maps[d] == "right") then
		local _key = key_maps[d]
		local f = items[cursor]
		if _key == "backspace" and f.cursor > 1 then
			f.text = f.text:sub(1, f.cursor - 2) .. f.text:sub(f.cursor)
			f.cursor = f.cursor - 1
			set_cursor(true)
		elseif _key == "delete" then
			f.text = f.text:sub(1, f.cursor - 1) .. f.text:sub(f.cursor + 1)
			set_cursor(true)
		elseif _key == "left" and f.cursor > 1 then
			f.cursor = f.cursor - 1
			set_cursor(true)
		elseif _key == "right" and f.cursor <= #f.text then
			f.cursor = f.cursor + 1
			set_cursor(true)
		end
	elseif e == "key" and (views[view] or "") == "list" and #filter > 0 and (key_maps[d] or "") == "backspace" then
		filter = filter:sub(1, -2)
		items = filter_items(filter)
		draw_top()
		draw_bottom()
	elseif e == "key" and key_maps[d] and (not term.isColor or not term.isColor()) then
		local _key = key_maps[d]
		if _key == "backspace" and (view == -1 or view > 0) then -- backspace
			if view > 0 then
				cursor = is_blackwhite and 1 or 0
				if view == 2 and cur_view == "newuser" then
					view = 0
				else
					view = view - 1
				end
				filter = ""
				items = filter_items(filter)
			else
				view = 0
			end
			draw_top()
			draw_bottom()
		elseif _key == "tab" and view == 0 then -- open/close menu
			toggle_menu(not menu_open)
		elseif _key == "enter" then
			if menu_open then
				menu[menu_selection].func()
				toggle_menu(false)
			elseif (views[view] or "") == "list" and items[cursor] then
				items[cursor][2]()
				cursor = is_blackwhite and 1 or 0
				filter = ""
				items = filter_items(filter)
				draw_top()
				draw_bottom()
			elseif (views[view] or "") == "field" and not items[cursor] and items[cursor - 1] then
				save()
				draw_top()
				draw_bottom()
			end
		elseif _key == "up" then
			if menu_open then
				menu_selection = menu_selection > 0 and menu_selection - 1 or #menu
				if menu_selection == #menu and #menu > h - 4 then
					menu_scroll = #menu - (h - 4)
				elseif menu_selection > 0 and menu_selection - menu_scroll == 0 then
					menu_scroll = menu_scroll - 1
				end
				draw_menu()
			elseif view == -1 and changelog_scroll > 0 then
				changelog_scroll = changelog_scroll - 1
				draw_changelog()
			elseif views[view] and cursor > 1 then
				cursor = cursor - 1
				correct_scroll()
				draw_bottom()
			end
		elseif _key == "down" then
			if menu_open then
				menu_selection = menu_selection < #menu and menu_selection + 1 or 0
				if menu_selection == 1 then
					menu_scroll = 0
				elseif menu_selection - menu_scroll == h - 3 then
					menu_scroll = menu_scroll + 1
				end
				draw_menu()
			elseif view == -1 and #changelog - changelog_scroll > h - 5 then
				changelog_scroll = changelog_scroll + 1
				draw_changelog()
			elseif views[view] and cursor < #items + (views[view] == "field" and 1 or 0) then
				cursor = cursor + 1
				correct_scroll()
				draw_bottom()
			end
		end
	elseif e == "mouse_click" then
		x = x - offset
		if d == 1 then -- left click
			if x == 2 and y == 2 and not menu_open then -- open menu
				if view == -1 or view > 0 then
					if view > 0 then
						cursor = is_blackwhite and 1 or 0
						if view == 2 and cur_view == "newuser" then
							view = 0
						else
							view = view - 1
						end
						filter = ""
						items = filter_items(filter)
					else
						view = 0
					end
					draw_top()
					draw_bottom()
				elseif view == 0 then
					toggle_menu(true)
				end
			elseif x < 1 and y == h - 1 and menu_open then -- changelog
				menu[0].func()
				toggle_menu(false)
			elseif x < 1 and y > 1 and y < h - 2 and menu_open then -- menu entries
				if menu[y - 1 + menu_scroll] then
					menu[y - 1 + menu_scroll].func()
					toggle_menu(false)
				end
			elseif x > 0 and menu_open then -- close menu
				toggle_menu(false)
			elseif (views[view] or "") == "list" and y > 5 then
				local tmp = _ceil((y - 6 + list_scroll) / 3)
				if tmp > 0 and tmp <= #items then
					cursor = is_blackwhite and 1 or 0
					items[tmp][2]()
					filter = ""
					items = filter_items(filter)
					draw_top()
					draw_bottom()
				end
			elseif (views[view] or "") == "field" and y > 3 then
				local tmp = _ceil((y - 4 + list_scroll) / 3)
				if tmp > 0 and tmp <= #items then
					cursor = tmp
					local tmp = items[cursor]
					tmp.cursor = x - 2 + tmp.offset
					if tmp.cursor > #tmp.text + 1 then
						tmp.cursor = #tmp.text + 1
					elseif tmp.cursor < 1 then
						tmp.cursor = 1
					end
					draw_bottom()
				elseif x > w - 7 and x < w and _ceil((y - 6 + list_scroll) / 3) == #items + 1 then
					save()
					draw_top()
					draw_bottom()
				end
			end
		end
	elseif e == "mouse_scroll" then
		x = x - offset
		if menu_open and x < 1 and (d == 1 and #menu - menu_scroll > h - 4 or d == -1 and menu_scroll > 0) then -- menu
			menu_scroll = menu_scroll + d
			draw_menu()
		elseif view == -1 and y >= 4 and x > 0 and (d == 1 and #changelog - changelog_scroll > h - 5 or d == -1 and changelog_scroll > 0) then -- changelog
			changelog_scroll = changelog_scroll + d
			draw_changelog()
		elseif views[view] and y > 5 and (d == 1 and #items * 3 + (views[view] == "field" and 4 or 2) - list_scroll > h - 6 or d == -1 and list_scroll > 0) then
			list_scroll = list_scroll + d
			draw_bottom()
		end
	elseif e == "term_resize" then
		w, h = term.getSize()
		draw_menu()
		draw_top()
		if view == -1 then
			draw_changelog()
		elseif view >= 0 then
			if (view[view] or "") == "field" then
				local cursor_ = cursor
				for i = 1, #items do
					cursor = i
					set_cursor(nil, true)
				end
				cursor = cursor_
			end
			correct_scroll()
			draw_bottom()
		end
	elseif e == "timer" and d == timer then
		if menu_open and offset < menu_width or not menu_open and offset > 0 then
			offset = offset + (menu_open and 1 or -1)
			draw_menu()
			draw_top()
			if view == -1 then
				draw_changelog()
			elseif view == 0 then
				draw_bottom()
			end
			timer = os.startTimer(0)
		end
	end
until not running
background_color(32768, 32768, 32768)
text_color(1, 1, 1)
term.clear()
term.setCursorPos(1, 1)