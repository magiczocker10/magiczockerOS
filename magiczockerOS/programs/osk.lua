-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- TODO: Fix some LWJGL keys; add char event

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local current_settings = user_data and user_data().settings or {}
local layout, posY, file
local window_width, a, mode, word = 0, _HOSTver or 0 >= 1132, 1, ""
local codes = dofile("/magiczockerOS/key_mappings/data.lua")
local view = {{},{}}
local function load_lines()
	local file_line = 0
	for line in file.readLine do
		file_line = file_line + 1
		for word in line:gmatch("[^%s]+") do
			if codes[word] then
				layout[posY][#layout[posY]+1] = codes[word]
				view[1][posY] = view[1][posY] .. codes[word][1] .. " "
				view[2][posY] = view[2][posY] .. codes[word][2] .. " "
			elseif word == "##" then
			elseif word == "NEWLINE" then
				posY = posY + 1
				layout[posY] = {}
				view[1][posY] = ""
				view[2][posY] = ""
			elseif word == "NEWLINE_BASE" then
				posY = posY + 1
			elseif word == "PLACEHOLDER" then
				local tmp = (" "):rep(tonumber(line:sub(line:find("%s"),#line)))
				layout[posY][#layout[posY]+1] = {tmp, tmp, 0, 0}
				view[1][posY] = view[1][posY] .. tmp
				view[2][posY] = view[2][posY] .. tmp
			else
				error("Line "..file_line..": "..word)
			end
			break
		end
	end
end
local function loadKeys()
	posY, layout, view = 2, {{},{}}, {{"",""},{"",""}}
	file = fs.open("/magiczockerOS/key_mappings/" .. (current_settings.osk_key_mapping or "qwerty").. ".map", "r")
	load_lines()
	file.close()
	posY = 1
	file = fs.open("/magiczockerOS/key_mappings/base.map", "r")
	load_lines()
	file.close()
end
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function draw()
	window_width = 0
	local b = current_settings.window_bar_active_back or 128
	back_color(32768, 32768, b)
	text_color(1, 1, b == 1 and 32768 or current_settings.window_bar_active_text or 1)
	for y = 1, #layout do
		term.setCursorPos(1, y)
		term.write(view[mode == 1 and 1 or 2][y])
		window_width = #view[mode == 1 and 1 or 2][y] > window_width and #view[mode == 1 and 1 or 2][y] or window_width
	end
end
local function send_event(...)
	local proc = user_data and user_data().windows[1]
	if proc then
		proc.env.os.queueEvent(...)
	end
end
loadKeys()
draw()
while true do
	local e, _, x, y = os.pullEvent()
	if e == "mouse_click" then
		local count, l = 0, layout[y]
		for entry = 1, #l do
			if count < x and count + #l[entry][1] >= x then
				if l[entry][3] > 0 then
					send_event("key", mode == 1 and l[entry][3] or l[entry][4])
					if mode == 2 then
						mode = 1
						draw()
					elseif l[entry][1] == "Shift" or l[entry][1] == "Caps" then
						mode = mode == 1 and (l[entry][1] == "Shift" and 2 or l[entry][1] == "Caps" and 3) or 1
						draw()
					end
					break
				end
			else
				count = count + #l[entry][1] + 1
			end
		end
	elseif e == "refresh_settings" then
		current_settings = user_data().settings or {}
		loadKeys()
		draw()
		set_pos(nil, nil, width2 - 1, #layout + 1)
	end
end