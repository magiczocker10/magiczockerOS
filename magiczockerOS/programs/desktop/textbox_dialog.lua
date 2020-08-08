-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local running = true
local w,h = term.getSize()
local button_text = other[2]
local empty = (" "):rep(w)
local key_maps = {}
local settings = get_settings()
local btmp1, btmp2 = "#" .. button_text .. "#", " " .. button_text .. " "

-- Textfield variables
local user_input = ""
local user_input_cursor = 1
local textline_width = w - 2
local textline_offset = 0

multishell.setTitle(multishell.getCurrent(), title)
set_size(w, 6)

local data=user_data()
if not data.server then
	fs.set_root_path("/magiczockerOS/users/"..data.name.."/files/")
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
local function draw_text_line(blink)
	if not blink then
		term.setCursorPos(2, 2)
	end
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

local function draw()
	term.setCursorBlink(false)
	background_color(32768, 256, settings.dialog_background or 16)
	term.setCursorPos(1, 1)
	term.write(empty)
	term.setCursorPos(1, 2)
	term.write" "
	background_color(1, 1, settings.dialog_bar_background or 1)
	text_color(32768, 32768, settings.dialog_bar_text or 32768)
	set_cursor(true)
	background_color(32768, 256, settings.dialog_background or 16)
	term.write" "
	term.setCursorPos(1, 3)
	term.write(empty)
	term.setCursorPos(1, 4)
	term.write(empty:sub(1,-#button_text-4))
	background_color(1, 128, settings.dialog_button_background or 32)
	text_color(32768, 1, settings.dialog_button_text or 1)
	write_text(btmp1, btmp2, btmp2, btmp2)
	background_color(32768, 256, settings.dialog_background or 16)
	term.write" "
	term.setCursorPos(1, 5)
	term.write(empty)
	text_color(32768, 32768, settings.dialog_bar_text or 32768)
	term.setCursorPos(1 + user_input_cursor - textline_offset, 2)
	term.setCursorBlink(true)
end
do
	local a = (_HOSTver or 0) >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 259 or 14] = "backspace"
	key_maps[a and 261 or 211] = "delete"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
end
draw()
while running do
	local e, d, x, y = coroutine.yield()
	if e == "char" then
		user_input = user_input:sub(1, user_input_cursor - 1) .. d .. user_input:sub(user_input_cursor)
		user_input_cursor = user_input_cursor + 1
		draw()
	elseif e == "key" and #user_input > 0 and (
		key_maps[d] == "backspace" or
		key_maps[d] == "left" or
		key_maps[d] == "right" or
		key_maps[d] == "delete" or
		key_maps[d] == "enter"
	) then
		local _key = key_maps[d]
		if _key == "backspace" and user_input_cursor > 1 then -- backspace
			user_input_cursor = user_input_cursor - 1
			user_input = user_input:sub(1, user_input_cursor - 1) .. user_input:sub(user_input_cursor + 1)
			set_cursor()
			draw()
		elseif _key == "left" and user_input_cursor > 1 then -- left
			user_input_cursor = user_input_cursor - 1
			set_cursor()
		elseif _key == "right" and user_input_cursor <= #user_input then -- right
			user_input_cursor = user_input_cursor + 1
			set_cursor()
		elseif _key == "delete" and user_input_cursor <= #user_input then -- delete
			user_input = user_input:sub(1, user_input_cursor - 1) .. user_input:sub(user_input_cursor + 1)
			set_cursor()
		elseif _key == "enter" then
			os.queueEvent("textbox_done")
		end
	elseif e == "mouse_click" then
		if x >= w - #button_text - 2 and x < w and y == 4 and #user_input > 0 then
			os.queueEvent("textbox_done")
		end
	elseif e == "textbox_done" and not fs.exists("/desktop/" .. user_input) then
		if mode == "Rename" then
			fs.move("/desktop/" .. file, "/desktop/" .. user_input)
		else
			local file=fs.open("/desktop/" .. user_input, "w")
			if file then
				file.write("")
				file.close()
			end
		end
		running=false
	elseif e == "term_resize" then
		w,h = term.getSize()
		empty = (" "):rep(w)
		draw()
	elseif e == "refresh_settings" then
		settings = get_settings()
		draw()
	end
end
done=true