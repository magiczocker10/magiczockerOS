-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- numbers
local mode = 1
-- booleans
local send_key_up = true
local shift_active = false
local caps_active = false
-- tables
local current_settings = settings or {}
local E_
local map = {}
local registered_keys -- (reihe,{anzeige normal,shift},{key normal,shift},{key-neu normal,shift},char event name)
-- functions
local function back_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function create_map()
	local a = 0 -- max_width
	local b -- cur_width
	map = {{}, {}, {}, {}, {}}
	for i = 1, #registered_keys do
		b = 0
		for j = 1, #registered_keys[i] do
			for _ = 1, #(registered_keys[i][j][1][mode] or " ") do
				map[i][#map[i] + 1] = j
			end
			b = b + #(registered_keys[i][j][1][mode] or " ")
			if j < #registered_keys[i] then
				map[i][#map[i] + 1] = 0
				b = b + 1
			end
		end
		if a < b then
			a = b
		end
	end
	if a == 0 then
		a = 2
	end
	set_size(a, #registered_keys + 1)
end
local function draw()
	local a
	local b = current_settings["window_bar_active_back"] or 128
	back_color(32768, 32768, b)
	text_color(1, 1, b == 1 and 32768 or current_settings["window_bar_active_text"] or 1)
	for i = 1, #map do
		term.setCursorPos(1, i)
		a = 0
		for j = 1, #map[i] do
			if map[i][j] == 0 then
				term.write" "
			elseif a ~= map[i][j] then
				a = map[i][j]
				term.write(registered_keys[i][map[i][j]][1][mode] or " ")
			end
		end
	end
end
local function send(a, b)
	send_event(a and "key_up" or "key", b, not a and not textutils.complete or nil)
end
local function send_key(a, b)
	if type(b) == "function" then
		b()
	elseif type(b) == "table" then
		for i = 1, #b do
			send(a, b[i])
		end
	else
		send(a, b)
	end
end
local function load_keyboard_layout()
	if E_ and E_ == current_settings.osk_key_mapping then
		return
	end
	registered_keys = {}
	local file = fs.open("/magiczockerOS/key_mappings/"..(current_settings.osk_key_mapping or "qwerty")..".map","r")
	if file then
		local cur_line = 1
		for line in file.readLine do
			if line=="next_row" then
				cur_line = cur_line + 1
			elseif line:match("%s") then
				registered_keys[cur_line] = registered_keys[cur_line] or {}
				local data = {nil,nil,nil,nil,nil}
				local num=1
				for k in line:gmatch("[^%s]+") do
					if k:match("^space_%d") then
						data[num] = (" "):rep(tonumber(k:sub(7)) or 1)
					elseif k=="empty" then
						if num==3 or num==4 then
							data[num]=0
						end
					else
						data[num]=k
					end
					num=num+1
					if num==6 then
						break
					end
				end
				data[3]=tonumber(data[3] or "")
				data[4]=tonumber(data[4]) or data[3]
				local tmp = registered_keys[cur_line]
				tmp[#tmp+1] = {{data[1],data[2]},{data[3],data[4]},data[5]}
			end
		end
		file.close()
		create_map()
	end
end
-- start
load_keyboard_layout()
draw()
-- events
while true do
	local a, b, c, d = coroutine.yield()
	if a == "mouse_click" and map[d] and (map[d][c] or 0) > 0 then
		local f = registered_keys[d][map[d][c]] -- r_key
		local e = mode -- mode_old
		if f[1][mode] then
			-- Key
			send_key(false, f[2][e])
			-- Char
			local _char = f[3] or f[1][mode]
			if #_char == 1 then
				if type(_char) == "function" then
					_char()
				elseif _char then
					send_event("char", _char)
				end
			end
			-- Key up
			if send_key_up then
				send_key(true, f[2][e])
			end
			if f[1][mode]:lower() == "shift" then
				shift_active = not shift_active
			elseif f[1][mode]:lower() == "caps" then
				caps_active = not caps_active
			else
				shift_active = false
			end
			mode = (shift_active or caps_active) and shift_active ~= caps_active and 2 or 1
			if mode ~= e then
				create_map()
				draw()
			end
		end
	elseif a == "char" and b == "r" then
		E_ = nil
		load_keyboard_layout()
		draw()
	elseif a == "refresh_settings" then
		current_settings = get_settings()
		load_keyboard_layout()
		draw()
	elseif a ~= "user" then
		send_event(unpack(e))
	end
end