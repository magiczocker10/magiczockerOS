-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local w, h = term.getSize()
local field = 1
local L1 = " Login "
local fields = { -- cursor, height, offset, watermark, text, symbol
	{1, 2, 0, "Username..", "test"}, -- username
	{1, 4, 0, "Password..", "", "*"}, -- password
}
set_pos(nil, nil, nil, 7)
local key_maps = {}
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function draw_field(blink, data)
	term.setCursorPos(2, data[2])
	back_color(1, 1, 1)
	local a = data[5] or ""
	if #a == 0 then
		a = data[4] or ""
		text_color(32738, data[4] and 256 or 32768, data[4] and 256 or 32768)
	else
		a = data[6] and (data[6]):rep(#a) or a
		text_color(32738, 32768, 32768)
	end
	term.write((a .. ((not term.isColor or not term.isColor()) and "_" or " "):rep(w)):sub(1 + data[3], w - 2 + data[3]))
	back_color(32768, 128, 2048)
end
local function set_cursor(field, blink)
	local data = fields[field]
	term.setCursorBlink(false)
	data[1] = data[1] - 1 > #data[5] and #data[5] + 1 or data[1]
	if data[1] <= data[3] then
		data[3] = data[1] - 1
	elseif data[1] > w - 2 + data[3] then
		data[3] = data[1] - w
	end
	data[3] = data[3] < 0 and 0 or data[3]
	draw_field(blink, data)
end
local function set_blink()
	if field > 0 then
		local a = fields[field]
		local length = w - 2
		a[1] = a[1] > #a[4] + 1 and #a[4] + 1 or a[1]
		a[3] = a[1] - a[3] > length and a[3] + 1 or a[1] - a[3] < 1 and a[3] - 1 or a[3]
		a[3] = a[3] > 0 and #a[4] - a[3] < length and (#a[4] - length + 1 > 0 and #a[4] - length + 1 or 0) or a[3]
		text_color(32768, 32768, 32768)
		term.setCursorPos(1 + a[1] - a[3], a[2])
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end
end
local function draw()
	local line = (" "):rep(w - 9)
	text_color(1, 1, 1)
	back_color(32768, 128, 2048)
	for y = 1, h do
		term.setCursorPos(1, y)
		if y == 2 or y == 4 then
			term.write" "
			set_cursor(y == 2 and 1 or 2)
			term.write" "
		elseif y == 6 then
			term.write((" "):rep(w - 8))
			back_color(1, 256, 256)
			text_color(1, 1, 1)
			if field < 1 then
				term.write(term.isColor and term.isColor() and L1 or textutils and type(textutils.complete) == "function" and L1 or ">Login<")
			else
				term.write(L1)
			end
			back_color(32768, 128, 2048)
			term.write(" ")
		else
			term.write("         " .. line)
		end
	end
	set_blink()
end
local function reset()
	local a = fields[2]
	a[1] = 1
	a[3] = 0
	a[5] = ""
	set_cursor(2)
end
local function login()
	field = 1
	local un, pw = fields[1][5], fields[2][5]
	if un:find("\\") then
		local found = un:find("\\")
		signin_user(tonumber(un:sub(1, found - 1)), un:sub(found + 1), pw)
	elseif un:match("[a-zA-Z0-9]") and fs.exists("/magiczockerOS/users/" .. un) and fs.isDir("/magiczockerOS/users/" .. un) then
		local a = ""
		local file = fs.exists("/magiczockerOS/users/" .. un .. "/password.txt") and fs.open("/magiczockerOS/users/" .. un .. "/password.txt", "r")
		if file then
			a = file.readLine() or ""
			file.close()
		end
		if #a == 0 or a == pw then
			reset()
			switch_user(false, un)
		end
	else
		reset()
	end
end
local function events(a, b, c, d)
	local e = fields[field]
	if a == "char" and e then
		if b:match("[a-zA-Z%d-_.]") then
			e[5] = e[5]:sub(1, e[1] - 1) .. b .. e[5]:sub(e[1])
			e[1] = e[1] + 1
			set_cursor(field)
			set_blink()
		end
	elseif a == "key" then
		local _key = key_maps[b] or ""
		if _key == "backspace" and e and e[1] > 1 and field > 0 then
			e[5] = e[5]:sub(1, e[1] - 2) .. e[5]:sub(e[1])
			e[1] = e[1] - 1
		elseif _key == "tab" then
			field = field == 2 and 0 or field + 1
			draw()
		elseif (_key == "space" or _key == "enter") and field == 0 then
			login()
		elseif _key == "left" and e and e[1] > 1 and field > 0 then
			e[1] = e[1] - 1
		elseif _key == "right" and e and e[1] <= #e[5] and field > 0 then
			e[1] = e[1] + 1
		elseif _key == "delete" and e and field > 0 then
			e[5] = e[5]:sub(1, e[1] - 1) .. e[5]:sub(e[1] + 1)
		end
		if _key ~= "tab" then
			set_cursor(field)
			set_blink()
		end
	elseif a == "mouse_click" then
		if c > 1 and c < w and (d == 2 or d == 4) then
			field = d == 2 and 1 or 2
			fields[field][1] = c - 1 + fields[field][3]
			set_cursor(field)
		elseif c > w - 8 and c < w and d == 6 then
			login()
		else
			field = 0
		end
		set_blink()
	elseif a == "modem_message" then
		if c then
			reset()
			switch_user(false, fields[1][4], c)
		else
			error"Invalid user"
		end
	elseif a == "term_resize" then
		w, h = term.getSize()
		draw()
	end
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 32 or 57] = "space"
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 258 or 15] = "tab"
	key_maps[a and 259 or 14] = "backspace"
	key_maps[a and 261 or 211] = "delete"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
end
draw()
while true do
	events(coroutine.yield())
end