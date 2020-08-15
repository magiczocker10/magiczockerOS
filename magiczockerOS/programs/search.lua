-- ToDo: sorting, opening files

-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local data=user_data()
if not data.server then
	fs.set_root_path("/magiczockerOS/users/" .. data.name .. "/files/")
end

local w, h = term.getSize()
local user = user or ""
local results = {}
local results_scroll
local user_input = ""
local key_maps = {}
local textline_width = w - 2
local textline_offset = 0
local user_input_cursor = 1
local entry_selected
local settings = settings or {}
local function return_text(a, b, c, d)
	return not term.isColor and a or term.isColor() and d or textutils and textutils.complete and c or b
end
local function background_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function write_text(a, b, c, d)
	term.write(not term.isColor and a or term.isColor() and d or textutils and textutils.complete and c or b)
end
local function search(search_term)
	local search_term = search_term:lower()
	local to_return = {}
	local to_search = {"/"}
	for i = 1, #to_search do
		local files_to_search = {to_search[i]}
		for _, v in next, files_to_search do
			if fs.isDir(v) then
				local files = fs.list(v)
				for j = 1, #files do
					files_to_search[#files_to_search + 1] = v .. "/" .. files[j]
				end
			else
				local tmp = v
				if tmp:lower():find(search_term) then
					if not tmp:find("/") then
						tmp = "/" .. tmp
					end
					local _tmp = tmp:reverse():find("/")
					local _file = tmp:sub(#tmp - _tmp + 2)
					local _path = tmp:sub(1, #tmp - _tmp)
					if #_path == 0 then
						_path = "/"
					end
					if _path:sub(1, 1) ~= "/" then
						_path = "/" .. _path
					end
					if _path:sub(1, 2) == "//" then
						_path = _path:sub(2)
					end
					to_return[#to_return + 1] = _file .. "|" .. _path
				end
			end
		end
	end
	table.sort(to_return)
	return to_return
end
local function prepare_list()
	local tmp_results = search(user_input)
	entry_selected = 1
	results = {}
	results_scroll = 0
	for i = 1, #tmp_results do
		local _found = tmp_results[i]:find("|")
		local _file = tmp_results[i]:sub(1, _found - 1)
		local _folder = tmp_results[i]:sub(_found + 1)
		local _on_click = multishell.launch and function() multishell.launch({}, _folder .. "/" .. _file) end
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "empty_line", first = true}
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "text", text = _file}
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "text", text = _folder}
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "empty_line"}
		results[#results + 1] = {entry_no = i, type = "shadow"}
		results[#results + 1] = {entry_no = i, type = "empty", last = true}
	end
end
local function draw_text_line(blink)
	if not blink then
		term.setCursorPos(2, 2)
	end
	background_color(1, 1, 1)
	text_color(32768, 32768, 32768)
	term.write((user_input .. (not term.isColor and "_" or " "):rep(textline_width)):sub(1 + textline_offset, textline_width + textline_offset))
	if not blink then
		term.setCursorPos(1 + user_input_cursor - textline_offset, 2)
	end
end
local function set_cursor(blink)
	if user_input_cursor - 1 > #user_input then
		user_input_cursor = #user_input + 1
	end
	if user_input_cursor <= textline_offset then
		textline_offset = user_input_cursor - 1
	elseif user_input_cursor > textline_width + textline_offset then
		textline_offset = user_input_cursor - textline_width
	end
	if textline_offset < 0 then
		textline_offset = 0
	end
	draw_text_line(blink)
end
local function correct_entries_scroll()
	if results_scroll > 0 then
		local tmp = #results - results_scroll
		if tmp < h - 3 then
			results_scroll = #results-h+3
		end
	end
	if results_scroll < 0 then
		results_scroll = 0
	end
end
local function scroll_to_result(dir)
	for i = 1, #results do
		if results[i].entry_no == entry_selected and (dir == "down" and results[i].last ~= nil or dir == "up" and results[i].first ~= nil) then
			local tmp = i - results_scroll
			if tmp < 1 then
				results_scroll = i - 1
			end
			if tmp > h - 3 then
				results_scroll = i + 3 - h
			end
			break
		end
	end
	if results_scroll < 0 then
		results_scroll = 0
	end
end
local function draw()
	term.setCursorBlink(false)
	local empty = (" "):rep(w)
	local empty_line = empty:sub(4)
	local shadow
	local shadow_border
	background_color(32768, 256, settings.search_background or 16)
	term.setCursorPos(1, 1)
	term.write(empty)
	term.setCursorPos(1, 2)
	term.write" "
	background_color(1, 1, settings.search_bar_background or 1)
	text_color(32768, 32768, settings.search_bar_text or 32768)
	set_cursor(true)
	background_color(32768, 256, settings.search_background or 16)
	term.write" "
	term.setCursorPos(1, 3)
	term.write(empty)
	for i = 4, h do
		term.setCursorPos(1, i)
		background_color(32768, 256, settings.search_background or 16)
		if results[i - 3 + results_scroll] then
			local temp = results[i - 3 + results_scroll]
			if entry_selected == temp.entry_no then
				text_color(1, 1, 1)
			end
			if temp.type == "empty" then
				term.write(empty)
			elseif temp.type == "empty_line" then
				write_text(entry_selected == temp.entry_no and ">" or " ", entry_selected == temp.entry_no and ">" or " ", " ", " ")
				background_color(1, entry_selected == temp.entry_no and 128 or 1, settings.search_entry_background or 1)
				term.write(empty_line)
			elseif temp.type == "shadow" then
				if not shadow then
					local tmp = ("-"):rep(w - 5) .. " "
					local tmp2 = empty_line:sub(2)
					shadow = return_text(tmp, tmp, tmp2, tmp2)
				end
				write_text(entry_selected == temp.entry_no and ">" or " ", entry_selected == temp.entry_no and ">" or " ", " ", " ")
				term.write" "
				background_color(32768, entry_selected == temp.entry_no and 32768 or 128, settings.search_entry_shadow or 128)
				term.write(shadow)
			else
				write_text(entry_selected == temp.entry_no and ">" or " ", entry_selected == temp.entry_no and ">" or " ", " ", " ")
				background_color(1, entry_selected == temp.entry_no and 128 or 1, settings.search_entry_background or 1)
				text_color(32768, entry_selected == temp.entry_no and 1 or 32768, settings.search_entry_text or 32768)
				term.write((" " .. temp.text .. empty_line):sub(1, w - 3))
			end
			if not results[i - 4 + results_scroll] or results[i - 4 + results_scroll].type == "empty" then -- no shadow
				background_color(32768, 256, settings.search_background or 16)
				term.write(" ")
				write_text(entry_selected == temp.entry_no and "<" or " ", entry_selected == temp.entry_no and "<" or " ", " ", " ")
			else -- shadow
				if not shadow_border then
					shadow_border = return_text("|", "|", " ", " ")
				end
				text_color(1, 1, 1)
				background_color(32768, entry_selected == temp.entry_no and 32768 or 128, settings.search_entry_shadow or 128)
				term.write(temp.type == "shadow" and " " or shadow_border)
				background_color(32768, 256, settings.search_background or 16)
				write_text(entry_selected == temp.entry_no and "<" or " ", entry_selected == temp.entry_no and "<" or " ", " ", " ")
			end
		else
			term.write(empty)
		end
	end
	text_color(32768, 32768, settings.search_bar_text or 32768)
	term.setCursorPos(1 + user_input_cursor - textline_offset, 2)
	term.setCursorBlink(true)
end
local function update_title()
	multishell.setTitle(multishell.getCurrent(), #user_input == 0 and "Search" or "Search - \"" .. user_input .. "\"")
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 259 or 14] = "backspace"
	key_maps[a and 261 or 211] = "delete"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
prepare_list()
update_title()
draw()
while true do
	local e, d, x, y = coroutine.yield()
	if e == "char" then
		user_input = user_input:sub(1, user_input_cursor - 1) .. d .. user_input:sub(user_input_cursor)
		user_input_cursor = user_input_cursor + 1
		update_title()
		prepare_list()
		draw()
	elseif e == "key" and #user_input > 0 and (
		key_maps[d] == "backspace" or
		key_maps[d] == "left" or
		key_maps[d] == "right" or
		key_maps[d] == "delete"
	) then
		local _key = key_maps[d]
		if _key == "backspace" and user_input_cursor > 1 then
			user_input_cursor = user_input_cursor - 1
			user_input = user_input:sub(1, user_input_cursor - 1) .. user_input:sub(user_input_cursor + 1)
			update_title()
			prepare_list()
			draw()
		elseif _key == "left" and user_input_cursor > 1 then
			user_input_cursor = user_input_cursor - 1
			set_cursor()
		elseif _key == "right" and user_input_cursor <= #user_input then
			user_input_cursor = user_input_cursor + 1
			set_cursor()
		elseif _key == "delete" and user_input_cursor <= #user_input then
			user_input = user_input:sub(1, user_input_cursor - 1) .. user_input:sub(user_input_cursor + 1)
			update_title()
			prepare_list()
			set_cursor()
		end
	elseif e == "key" and key_maps[d] and (not term or not term.isColor or not term.isColor()) then
		local _key = key_maps[d]
		if _key == "enter" then
			for i = 1, #results do
				if results[i].entry_no and results[i].entry_no == entry_selected then
					if results[i].on_click then
						results[i].on_click()
					end
					break
				end
			end
		elseif _key == "up" and entry_selected > 1 then
			entry_selected = entry_selected - 1
			scroll_to_result("up")
			draw()
		elseif _key == "down" then
			for i = 1, #results do
				if results[i].last and results[i].entry_no and results[i].entry_no - 1 == entry_selected then
					entry_selected = entry_selected + 1
					scroll_to_result("down")
					draw()
					break
				end
			end
		end
	elseif e == "mouse_click" and x > 1 and x < w-1 and y > 3 and results[y - 3 + results_scroll] and results[y - 3 + results_scroll].on_click then
		results[y - 3 + results_scroll].on_click()
	elseif e == "mouse_scroll" and y > 3 and y <= h and (d > 0 and #results - results_scroll > h - 3 or d < 0 and results_scroll > 0) then
		results_scroll = results_scroll + d
		correct_entries_scroll()
		draw()
	elseif e == "term_resize" then
		w, h = term.getSize()
		textline_width = w - 2
		correct_entries_scroll()
		draw()
	elseif e == "refresh_settings" then
		settings = get_settings()
		draw()
	end
end