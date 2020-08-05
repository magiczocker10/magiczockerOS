-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
-- numbers
local w, h = term.getSize()
-- strings
local field = "username"
local L1=" Login "
local L2=">Login<"
-- tables
local fields = {
	username = {
		cursor = 1,
		height = 3,
		offset = 0,
		text = "",
	},
	password = {
		cursor = 1,
		height = 6,
		offset = 0,
		symbol = "*",
		text = "",
	},
}
local key_maps = {}
-- functions
local function back_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function set_blink()
	if #field > 0 then
		local cur_field = fields[field]
		local length = w - 2
		if cur_field.cursor > #cur_field.text + 1 then
			cur_field.cursor = #cur_field.text + 1
		end
		if cur_field.cursor - cur_field.offset > length then
			cur_field.offset = cur_field.offset + 1
		elseif cur_field.cursor - cur_field.offset < 1 then
			cur_field.offset = cur_field.offset - 1
		end
		if cur_field.offset > 0 and #cur_field.text - cur_field.offset < length then
			cur_field.offset = #cur_field.text - length + 1 > 0 and #cur_field.text - length + 1 or 0
		end
		text_color(32768, 32768, 32768)
		term.setCursorPos(1 + fields[field].cursor - fields[field].offset, fields[field].height)
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end
end
local function draw_field(a)
	if fields[a] then
		local b = ((not term.isColor or not term.isColor) and (not textutils or not textutils.serialize) and "_" or " "):rep(w)
		local c = fields[a].text:sub(1 + fields[a].offset, w - 2 + fields[a].offset)
		term.setCursorPos(2, fields[a].height)
		back_color(1, 1, 1)
		text_color(32738, 32768, 32768)
		term.write(((fields[a].symbol and c:gsub(".", "*") or c) .. b):sub(1, w - 2))
		back_color(32768, 128, 2048)
		text_color(1, 1, 1)
	end
end
local function draw()
	local line = (" "):rep(w - 9)
	text_color(1, 1, 1)
	back_color(32768, 128, 2048)
	for y = 1, h do
		term.setCursorPos(1,y)
		if y == 2 or y == 5 then
			term.write((y==2 and " Username" or " Password")..line)
		elseif y == 3 or y == 6 then
			term.write" "
			draw_field(y==3 and "username" or "password")
			term.write" "
		elseif y == 8 then
			term.write((" "):rep(w-8))
			term.setBackgroundColor(256)
			if field == "" then
				term.write(not term.isColor and L2 or term.isColor() and L1 or textutils and type(textutils.complete) == "function" and L1 or L2)
			else
				term.write(L1)
			end
			back_color(32768, 128, 2048)
			term.write(" ")
		else
			term.write(line.."         ")
		end
	end
	set_blink()
end
local function reset()
	fields.password = {
		cursor = 1,
		height = 6,
		offset = 0,
		text = "",
	}
	draw_field("password")
end
local function login()
	field = "username"
	if fields.username.text:find("\\") then
		local tmp = fields.username.text
		local found= tmp:find("\\")
		signin_user(tonumber(tmp:sub(1,found-1)),tmp:sub(found+1))
	elseif fields.username.text:match("[a-zA-Z0-9]") and fs.exists("/magiczockerOS/users/" .. fields.username.text) and fs.isDir("/magiczockerOS/users/" .. fields.username.text) then
		local a = ""
		local file = fs.exists("/magiczockerOS/users/" .. fields.username.text .. "/password.txt") and fs.open("/magiczockerOS/users/" .. fields.username.text .. "/password.txt", "r")
		if file then
			a = "" --file.readLine() or ""
			file.close()
		end
		if #a == 0 or a == fields.password.text then
			reset()
			switch_user(false, fields.username.text)
		end
	else
		reset()
	end
end
local function load_keys()
	local number_to_check
	if #(_HOST or "") > 1 then -- Filter from https://forums.coronalabs.com/topic/71863-how-to-find-the-last-word-in-string/
		number_to_check = tonumber(({_HOST:match("%s*(%S+)$"):reverse():sub(2):reverse():gsub("%.", "")})[1] or "")
	end
	if number_to_check and type(number_to_check) == "number" and number_to_check >= 1132 then -- GLFW
		key_maps[32] = "space"
		key_maps[257] = "enter"
		key_maps[258] = "tab"
		key_maps[259] = "backspace"
		key_maps[261] = "delete"
		key_maps[262] = "right"
		key_maps[263] = "left"
	else -- LWJGL
		key_maps[14] = "backspace"
		key_maps[15] = "tab"
		key_maps[28] = "enter"
		key_maps[57] = "space"
		key_maps[203] = "left"
		key_maps[205] = "right"
		key_maps[211] = "delete"
	end
end
-- start
load_keys()
fields.username.text = "test" -- 1\\
draw()
-- events
while true do
	local a, b, c, d = coroutine.yield()
	local cur_field = fields[field]
	if a == "char" and cur_field then
		if b:match("[a-zA-Z%d-_.]") then
			cur_field.text = cur_field.text:sub(1, cur_field.cursor - 1) .. b .. cur_field.text:sub(cur_field.cursor)
			cur_field.cursor = cur_field.cursor + 1
			draw_field(field)
			set_blink()
		end
	elseif a == "key" then
		_key = key_maps[b]
		if _key == "backspace" and cur_field and cur_field.cursor > 1 and #field > 0 then
			cur_field.text = cur_field.text:sub(1, cur_field.cursor - 2) .. cur_field.text:sub(cur_field.cursor)
			cur_field.cursor = cur_field.cursor - 1
		elseif _key == "tab" then
			field = field == "username" and "password" or field == "password" and "" or "username"
			draw()
		elseif (_key == "space" or _key == "enter") and #field == 0 then
			login()
		elseif _key == "left" and cur_field and cur_field.cursor > 1 and #field > 0 then
			cur_field.cursor = cur_field.cursor - 1
		elseif _key == "right" and cur_field and cur_field.cursor <= #cur_field.text and #field > 0 then
			cur_field.cursor = cur_field.cursor + 1
		elseif _key == "delete" and cur_field and #field > 0 then
			cur_field.text = cur_field.text:sub(1, cur_field.cursor - 1) .. cur_field.text:sub(cur_field.cursor + 1)
		end
		if _key ~= "tab" then
			draw_field(field)
			set_blink()
		end
	elseif a == "mouse_click" then
		if c > 1 and c < w and (d == 3 or d == 6) then
			field = d==3 and "username" or "password"
			fields[field].cursor = c - 1 + fields[field].offset
			draw_field(field)
		elseif c > w - 9 and c < w and d == 8 then
			login()
		else
			field = ""
		end
		set_blink()
	elseif a == "modem_message" then
		if c then
			reset()
			switch_user(false, fields.username.text,c)
		else
			error"Invalid user"
		end
	elseif a == "term_resize" then
		w, h = term.getSize()
		draw()
	end
end