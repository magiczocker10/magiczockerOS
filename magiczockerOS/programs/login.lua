-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local w, h = term.getSize()
local field = 1
local L1 = " Login "
local fields = { -- cursor, height, offset, text, symbol
	{1, 3, 0, "test"}, -- username
	{1, 6, 0, "", "*"}, -- password
}
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
local function set_blink()
	if field > 0 then
		local a = fields[field]
		local length = w - 2
		a[1] = a[1] > #a[4] + 1 and #a[4] + 1 or a[1]
		a[3] = a[1] - a[3] > length and a[3] + 1 or a[1] - a[3] < 1 and a[3] - 1 or a[3]
		a[3] = a[3] > 0 and #a[4] - a[3] < length and (#a[4] - length + 1 > 0 and #a[4] - length + 1 or 0) or a[3]
		text_color(32768, 32768, 32768)
		term.setCursorPos(1 + fields[field][1] - fields[field][3], fields[field][2])
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end
end
local function draw_field(a)
	if fields[a] then
		local b = (not term.isColor and (not textutils or not textutils.serialize) and "_" or " "):rep(w)
		local c = fields[a][4]:sub(1 + fields[a][3], w - 2 + fields[a][3])
		term.setCursorPos(2, fields[a][2])
		back_color(1, 1, 1)
		text_color(32738, 32768, 32768)
		term.write(((fields[a][5] and c:gsub(".", fields[a][5]) or c) .. b):sub(1, w - 2))
		back_color(32768, 128, 2048)
		text_color(1, 1, 1)
	end
end
local function draw()
	local line = (" "):rep(w - 9)
	text_color(1, 1, 1)
	back_color(32768, 128, 2048)
	for y = 1, h do
		term.setCursorPos(1, y)
		if y == 3 or y == 6 then
			term.write" "
			draw_field(y == 3 and 1 or 2)
			term.write" "
		elseif y == 8 then
			term.write((" "):rep(w - 8))
			back_color(1, 256, 256)
			if field < 1 then
				term.write(term.isColor and term.isColor() and L1 or textutils and type(textutils.complete) == "function" and L1 or ">Login<")
			else
				term.write(L1)
			end
			back_color(32768, 128, 2048)
			term.write(" ")
		else
			term.write((y == 2 and " Username" or y == 5 and " Password" or "         ") .. line)
		end
	end
	set_blink()
end
local function reset()
	fields[2] = {1, 6, 0, "", "*"}
	draw_field(2)
end
local function login()
	field = 1
	if fields[1][4]:find("\\") then
		local tmp = fields[1][4]
		local found = tmp:find("\\")
		signin_user(tonumber(tmp:sub(1, found - 1)), tmp:sub(found + 1), fields[2][4])
	elseif fields[1][4]:match("[a-zA-Z0-9]") and fs.exists("/magiczockerOS/users/" .. fields[1][4]) and fs.isDir("/magiczockerOS/users/" .. fields[1][4]) then
		local a = ""
		local file = fs.exists("/magiczockerOS/users/" .. fields[1][4] .. "/password.txt") and fs.open("/magiczockerOS/users/" .. fields[1][4] .. "/password.txt", "r")
		if file then
			a = "" --file.readLine() or ""
			file.close()
		end
		if #a == 0 or a == fields[2][4] then
			reset()
			switch_user(false, fields[1][4])
		end
	else
		reset()
	end
end
local function events(a, b, c, d)
	local e = fields[field]
	if a == "char" and e then
		if b:match("[a-zA-Z%d-_.]") then
			e[4] = e[4]:sub(1, e[1] - 1) .. b .. e[4]:sub(e[1])
			e[1] = e[1] + 1
			draw_field(field)
			set_blink()
		end
	elseif a == "key" then
		local _key = key_maps[b] or ""
		if _key == "backspace" and e and e[1] > 1 and field > 0 then
			e[4] = e[4]:sub(1, e[1] - 2) .. e[4]:sub(e[1])
			e[1] = e[1] - 1
		elseif _key == "tab" then
			field = field == 2 and 0 or field + 1
			draw()
		elseif (_key == "space" or _key == "enter") and field == 0 then
			login()
		elseif _key == "left" and e and e[1] > 1 and field > 0 then
			e[1] = e[1] - 1
		elseif _key == "right" and e and e[1] <= #e[4] and field > 0 then
			e[1] = e[1] + 1
		elseif _key == "delete" and e and field > 0 then
			e[4] = e[4]:sub(1, e[1] - 1) .. e[4]:sub(e[1] + 1)
		end
		if _key ~= "tab" then
			draw_field(field)
			set_blink()
		end
	elseif a == "mouse_click" then
		if c > 1 and c < w and (d == 3 or d == 6) then
			field = d == 3 and 1 or 2
			fields[field][1] = c - 1 + fields[field][3]
			draw_field(field)
		elseif c > w - 8 and c < w and d == 8 then
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