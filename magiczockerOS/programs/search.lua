-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local term = term
local data = user_data()
if not data.server then
	fs.set_root_path("/magiczockerOS/users/" .. data.name .. "/files/")
end
local w, h = term.getSize()
local user, results, key_maps, settings, reposed, last_pos = user or "", {}, {}, user_data().settings or {}, false, {0, 0, 0, 0}
local results_scroll, entry_selected
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local field = {
	allowed_pattern = "[a-zA-Z0-9-/%.+_%(%)%s]",
	cursor = 1,
	endx = w - 1,
	offset = 0,
	startx = 2,
	text = "",
}
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function write_text(a, b, c, d)
	term.write(not term.isColor and a or term.isColor() and d or textutils and textutils.complete and c or b)
end
local function set_position(a)
	local wt, ht = get_total_size()
	local w, h = math.floor(wt * 0.5), math.min(math.floor(ht * 0.5), 3 + #results)
	local x, y = math.floor((wt - w) * 0.5), 4
	w = wt - x * 2
	x = x + 1
	reposed = true
	if last_pos[1] ~= x or last_pos[2] ~= y or last_pos[3] ~= w or last_pos[4] ~= h then
		last_pos[1], last_pos[2], last_pos[3], last_pos[4] = x, y, w, h
		set_pos(x, y, w, h, a)
	end
end
local function search(search_term)
	local search_term = search_term:lower()
	local to_return = {}
	local to_search = {{folder = "/", file = ""}}
	for i = 1, #to_search do
		local files_to_search = {to_search[i]}
		for _, v in next, files_to_search do
			if fs.isDir(v.folder .. v.file) then
				local files = fs.list(v.folder .. v.file)
				for j = 1, #files do
					files_to_search[#files_to_search + 1] = {folder = v.folder .. v.file .. "/", file = files[j]}
				end
			elseif #v.file > 0 then
				local tmp = v.folder .. v.file
				if tmp:lower():find(search_term) then
					to_return[#to_return + 1] = {path = v.folder:sub(2, -2), name = v.file}
				end
			end
		end
	end
	table.sort(to_return, function(a, b) return a.name == b.name and a.path < b.path or a.name < b.name end)
	return to_return
end
local function prepare_list()
	local tmp_results = search(field.text)
	entry_selected = 1
	results = {}
	results_scroll = 0
	for i = 1, #tmp_results do
		local _file = tmp_results[i].name
		local _folder = tmp_results[i].path
		local _on_click = multishell.launch and function() multishell.launch({}, _folder .. "/" .. _file) end
		results[#results + 1] = i == 1 and {type = "empty_line"} or nil
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "text", text = _file, first = true}
		results[#results + 1] = {entry_no = i, on_click = _on_click, type = "text", text = _folder, last = true}
		results[#results + 1] = {type = "empty_line"}
	end
	set_position()
end
local function draw_field(block_pos)
	local data = field
	if not block_pos then
		term.setCursorPos(2, 2)
	end
	local a = data.text or ""
	back_color(32768, 128, settings.search_back or 128)
	text_color(1, 1, settings.search_field_text or 1)
	if #a == 0 then
		a = data.watermark or ""
	end
	term.write((a .. ((not term.isColor or not term.isColor()) and "_" or " "):rep(w)):sub(1 + data.offset, w - 2 + data.offset))
end
local function set_cursor(block_pos)
	local data = field
	term.setCursorBlink(false)
	data.cursor = data.cursor - 1 > #data.text and #data.text + 1 or data.cursor
	if data.cursor <= data.offset then
		data.offset = data.cursor - 1
	elseif data.cursor > w - 2 + data.offset then
		data.offset = data.cursor - w + 2
	end
	data.offset = data.offset < 0 and 0 or data.offset
	draw_field(block_pos)
end
local function correct_entries_scroll()
	if results_scroll > 0 then
		local tmp = #results - results_scroll
		results_scroll = tmp < h - 4 and #results - h + 4 or results_scroll
	end
	results_scroll = results_scroll < 0 and 0 or results_scroll
end
local function scroll_to_result(dir)
	for i = 1, #results do
		if results[i].entry_no == entry_selected and (dir == "down" and results[i].last ~= nil or dir == "up" and results[i].first ~= nil) then
			local tmp = i - results_scroll
			results_scroll = tmp < 0 and i - 2 or results_scroll
			results_scroll = tmp > h - 4 and i + 4 - h or results_scroll
			break
		end
	end
	results_scroll = results_scroll < 0 and 0 or results_scroll
end
local function set_blink()
	text_color(1, 1, settings.search_field_text or 1)
	term.setCursorPos(1 + field.cursor - field.offset, 2)
	term.setCursorBlink(true)
end
local function draw()
	term.setCursorBlink(false)
	local empty = (" "):rep(w)
	back_color(32768, 128, settings.search_back or 128)
	term.setCursorPos(1, 1)
	term.write(empty)
	term.setCursorPos(1, 2)
	term.write" "
	set_cursor(true)
	term.write" "
	term.setCursorPos(1, 3)
	text_color(1, 256, settings.search_seperator_text or 256)
	term.write(#results == 0 and empty or empty:gsub(" ", "_"))
	for i = 4, h do
		term.setCursorPos(1, i)
		if results[i - 3 + results_scroll] then
			local temp = results[i - 3 + results_scroll]
			local selected = temp.entry_no == entry_selected
			selected = selected or entry_selected == (results[i - 4 + results_scroll] and results[i - 4 + results_scroll].entry_no or 0)
			selected = selected or entry_selected == (results[i - 2 + results_scroll] and results[i - 2 + results_scroll].entry_no or 0)
			local a, b = nil, ""
			if temp.type == "empty_line" then
				a = empty
			else
				text_color(1, selected and 1 or 256, settings.search_text or 1)
				a = (" " .. temp.text .. empty):sub(1, w)
			end
			if selected then
				b = a:gsub(" ", ".")
			end
			write_text(b, b, b, a)
			term.write(a)
		else
			term.write(empty)
		end
	end
	set_blink()
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
set_position()
draw()
while true do
	local e, d, x, y = coroutine.yield()
	if e == "char" or e == "paste" then
		local b = {}
		d = d:gsub("\\", "/")
		for char in d:gmatch(".") do
			b[#b + 1] = char:match(field.allowed_pattern) or nil
		end
		field.text = field.text:sub(1, field.cursor - 1) .. table.concat(b, "") .. field.text:sub(field.cursor)
		field.cursor = field.cursor + #b
		prepare_list()
		set_position()
		draw()
	elseif e == "key" and #field.text > 0 and (
		key_maps[d] == "backspace" or
		key_maps[d] == "left" or
		key_maps[d] == "right" or
		key_maps[d] == "delete"
	) then
		local _key = key_maps[d]
		if _key == "backspace" and field.cursor > 1 then
			field.text = field.text:sub(1, field.cursor - 2) .. field.text:sub(field.cursor)
			field.cursor = field.cursor - 1
			prepare_list()
			set_position()
			draw()
		elseif _key == "delete" and field.cursor <= #field.text then
			field.text = field.text:sub(1, field.cursor - 1) .. field.text:sub(field.cursor + 1)
			prepare_list()
			set_position()
			draw()
		elseif _key == "left" and field.cursor > 1 then
			field.cursor = field.cursor - 1
			set_cursor()
			set_blink()
		elseif _key == "right" and field.cursor <= #field.text then
			field.cursor = field.cursor + 1
			set_cursor()
			set_blink()
		end
	elseif (e == "mouse_click" or e == "mouse_drag") and y == 2 then
		field.cursor = math.min(#field.text + 1, x - 1)
		set_cursor()
		set_blink()
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
	elseif e == "mouse_click" and x > 1 and x < w - 1 and y > 3 and results[y - 3 + results_scroll] and results[y - 3 + results_scroll].on_click then
		results[y - 3 + results_scroll].on_click()
	elseif e == "mouse_scroll" and y > 3 and y <= h and (d > 0 and #results - results_scroll > h - 3 or d < 0 and results_scroll > 0) then
		results_scroll = results_scroll + d
		correct_entries_scroll()
		draw()
	elseif e == "term_resize" then
		if not reposed then
			set_position(true)
		end
		reposed = false
		w, h = term.getSize()
		correct_entries_scroll()
		draw()
	elseif e == "refresh_settings" then
		settings = user_data().settings or {}
		draw()
	end
end
