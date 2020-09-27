-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local current_settings = settings or {}
local layout, posX, posY
local special, mode = { ["<--"] = "<--", ["BACKSPACE"] = "<--", ["TAB"] = "Tab", ["SHIFT"] = "Shift", ["LSHIFT"] = "Shift", ["RSHIFT"] = "Shift", ["CTRL"] = "Ctrl", ["LCTRL"] = "Ctrl", ["RCTRL"] = "Ctrl", ["ALT"] = "Alt", ["LALT"] = "Alt", ["RALT"] = "Alt", ["<-"] = "<-", ["ENTER"] = "<-", ["CAPS"] = "Caps", ["SPACE"] = "---SPACE---" }, 1 -- 1 = normal, 2 = shift, 3 = caps
local function loadKeys()
	posX, posY, layout = 0, 1, {{}}
	local width, width2 = 0, 0
	local file = fs.open("/magiczockerOS/key_mappings/cc_qwerty.map", "r")
	for line in file.readLine do
		local count = 1
		posX = posX + 1
		layout[posY][posX] = {}
		for word in line:gmatch("[^%s]+") do
			if special[word] then
				layout[posY][posX] = {special[word], special[word], tonumber(line:sub(#word+2,#line))}
				width = width + #special[word] + 1
				break
			elseif word == "NEWLINE" then
				layout[posY][posX] = nil
				posX, posY = 0, posY + 1
				layout[posY] = {}
				width2 = width > width2 and width or width2
				width = 0
			else
				layout[posY][posX][count] = count>2 and tonumber(word) or word
				width = width + (count == 1 and #word + 1 or 0)
				count = count + 1
			end
		end
	end
	set_size(width2 - 1, #layout + 1)
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
	local b = current_settings.window_bar_active_back or 128
	back_color(32768, 32768, b)
	text_color(1, 1, b == 1 and 32768 or current_settings.window_bar_active_text or 1)
	for y = 1, #layout do
		term.setCursorPos(1, y)
		for x = 1, #layout[y] do
			term.write(layout[y][x][mode > 1 and 2 or 1] .. " ")
		end
	end
end
loadKeys()
draw()
while true do
	local e, _, x, y = coroutine.yield()
	if e == "mouse_click" then
		local count, l = 0, layout[y]
		for entry = 1, #l do
			if count < x and count + #l[entry][1] >= x then
				if l[entry][1] == "---SPACE---" then -- space temporary
					send_event("char", " ")
				elseif not special[l[entry][1]:upper()] then
					send_event("char", mode == 1 and l[entry][1] or l[entry][2])
				end
				send_event("key", (mode == 1 or l[entry][4] == nil) and l[entry][3] or l[entry][4])
				if mode == 2 then
					mode = 1
					draw()
				elseif l[entry][1] == "Shift" or l[entry][1] == "Caps" then
					mode = mode == 1 and (l[entry][1] == "Shift" and 2 or l[entry][1] == "Caps" and 3) or 1
					draw()
				end
				break
			else
				count = count + #l[entry][1] + 1
			end
		end
	elseif e == "refresh_settings" then
		current_settings = get_settings()
		loadKeys()
		draw()
	end
end