-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local term = term
local w, h = term.getSize()
local width, offset, running, user_settings, col, generated, advanced = (" "):rep(w), 0, true, {}, {}, {}, term.isColor()
for i = 0, 15 do
	col[2 ^ i] = i
end
local list = {
	{ "Calender", {
		{"Background", "color", "", 256},
		{"Text", "color", "", 1},
		{"Text Highlight", "color", "", 128},
	}, },
	{ "Clock", {
		{"24h", "boolean", "clock_format", false},
		{"Background Active", "color", "clock_back_active", 256},
		{"Text Active", "color", "clock_text_active", 1},
		{"Background Inactive", "color", "clock_back_inactive", 128},
		{"Text Inactive", "color", "clock_text_inactive", 1},
		{"Visible", "boolean", "clock_visible", true},
	}, },
	{ "Color Filters", {
		{ "Color Mode", "select", "color_mode", {"Off", "Achromatomaly", "Achromatopsia / Gray", "Deuteranomaly", "Deuteranopia", "Protanomaly", "Protanopia", "Sepia", "Tritanomaly", "Tritanopia"} },
		{"Invert", "boolean", "invert_colors", false},
		{"Original", "boolean", "original_colors", false},
	}, },
	{ "Computer", {
		{"Computer Label", "text", "", ""},
		{"Computer ID", "label", "", os.getComputerID()},
	}, },
	{ "Context-Menu", {
		{"Background", "color", "context_menu_background", 128},
		{"Text", "color", "context_menu_text", 1},
		{"Items Align", "select", "context_menu_items_align", {"left", "middle", "right"}},
	}, },
	{ "Desktop",	{
			{"Background", "color", "desktop_back",  2},
	}, },
	{ "Desktop-Dialogs", {
		{"Bar-Background", "color", "dialog_bar_background", 1},
		{"Bar-Textcolor", "color", "dialog_bar_text", 32768},
		{"Background", "color", "dialog_background", 16},
		{"Button-Background", "color", "dialog_button_background", 32},
		{"Button-Textcolor", "color", "dialog_button_text", 1},
	}, },
	{ "Mouse", {
		{"Inactive window scroll", "boolean", "mouse_inactive_window_scroll", true},
		{"Left-handed", "boolean", "mouse_left_handed", false},
	}, },
	{ "Search", {
		{"Background", "color", "search_background", 16},
		{"Entry Background", "color", "search_entry_background", 1},
		{"Entry Shadow Background", "color", "search_entry_shadow", 128},
		{"Entry Text", "color", "search_entry_text", 32768},
		{"Searchbar Background", "color", "search_bar_background", 1},
		{"Searchbar Text", "color", "search_bar_text", 32768},
	}, },
	{ "Startmenu", {
		{"Background", "color", "startmenu_back", 256},
		{"Text", "color", "startmenu_text", 1},
		{"Button Active Background", "color", "startmenu_button_active_back", 256},
		{"Button Active Text", "color", "startmenu_button_active_text", 1},
		{"Button Inactive Background", "color", "startmenu_button_inactive_back", 128},
		{"Button Inactive Text", "color", "startmenu_button_inactive_text", 1},
		{"Items Align", "select", "startmenu_items_align", {"left", "middle", "right"}},
	}, },
	{ "Taskbar", {
		{"Background", "color", "taskbar_back", 128},
		{"Items Active Background", "color", "taskbar_items_active_back", 256},
		{"Items Active Text", "color", "taskbar_items_active_text", 1},
		{"Items Inactive Background", "color", "taskbar_items_inactive_back", 128},
		{"Items Inactive Text", "color", "taskbar_items_inactive_text", 1},
	}, },
	{ "Window (Active)", {
		{"Bar Background", "color", "window_bar_active_back", 128},
		{"Bar Text", "color", "window_bar_active_text", 1},
		{"Close Button Background", "color", "window_close_button_active_back", 128},
		{"Close Button Text", "color", "window_close_button_active_text", 2048},
		{"Maximize Button Background", "color", "window_maximize_button_active_back", 128},
		{"Maximize Button Text", "color", "window_maximize_button_active_text", 8},
		{"Minimize Button Background", "color", "window_minimize_button_active_back", 128},
		{"Minimize Button Text", "color", "window_minimize_button_active_text", 512},
		{"Resize Border Background", "color", "window_resize_border_back", 128},
		{"Resize Border Text", "color", "window_resize_border_text", 128},
		{"Resize Button Background", "color", "window_resize_button_back", 128},
		{"Resize Button Text", "color", "window_resize_button_text", 256},
	}, },
	{ "Window (Inactive)", {
		{"Bar Background", "color", "window_bar_inactive_back", 128},
		{"Bar Text", "color", "window_bar_inactive_text", 1},
		{"Close Button Background", "color", "window_close_button_inactive_back", 128},
		{"Close Button Text", "color", "window_close_button_inactive_text", 256},
		{"Maximize Button Background", "color", "window_maximize_button_inactive_back", 128},
		{"Maximize Button Text", "color", "window_maximize_button_inactive_text", 256},
		{"Minimize Button Background", "color", "window_minimize_button_inactive_back", 128},
		{"Minimize Button Text", "color", "window_minimize_button_inactive_text", 256},
	}, },
}
local function generate()
	for i = 1, #list do
		generated[#generated + 1] = {list[i][1], "header", false, i}
	end
end
local function addItems(line, id)
	local content = list[id][2]
	for i = #content, 1, -1 do
		if advanced or content[i][2] ~= "color" then
			if content[i][2] == "select" then
				for j = #content[i][4], 1, -1 do
					table.insert(generated, line + 1, {content[i][4][j], "select", j == 1, content[i][1]})
				end
				table.insert(generated, line + 1, {content[i][1], "label"})
			else
				table.insert(generated, line + 1, content[i])
			end
		end
	end
end
local function removeItems(line)
	local tmp = true
	while tmp do
		if generated[line + 1] and generated[line + 1][2] ~= "header" then
			table.remove(generated, line + 1)
		else
			tmp = false
		end
	end
end
local function draw(line)
	local label_line = 0
	for i = line or 1, line or h do
		term.setCursorPos(1, i)
		local tmp = generated[i + offset]
		if tmp then
			local a = user_settings[tmp[3]] or tmp[4]
			term.setBackgroundColor(tmp[2] == "header" and 128 or 256)
			if tmp[2] == "header" then
				term.write((tmp[3] and " ^ " or " v ") .. tmp[1] .. width)
			elseif tmp[2] == "color" then
				term.write("   " .. tmp[1] .. (" "):rep(w - 7 - #tmp[1]) .. "<")
				term.setBackgroundColor(a)
				term.write(" ")
				term.setBackgroundColor(256)
				term.write("> ")
			elseif tmp[2] == "boolean" then
				term.write("   " .. tmp[1] .. (" "):rep(w - 7 - #tmp[1]))
				if a then
					term.setBackgroundColor(1)
					term.write("  ")
					term.setBackgroundColor(32)
					term.write(" ")
				else
					term.setBackgroundColor(16384)
					term.write(" ")
					term.setBackgroundColor(1)
					term.write("  ")
				end
				term.setBackgroundColor(256)
				term.write(" ")
			elseif tmp[2] == "text" then
				term.write("   " .. tmp[1] .. ": " .. a .. width)
			elseif tmp[2] == "select" then
				local a = user_settings[tmp[4]] or 1
				term.write("   " .. (a == i - label_line and "x " or "o ") .. tmp[1] .. width)
			elseif tmp[2] == "label" then
				term.write("   " .. tmp[1] .. (a and ": " .. a or "") .. width)
				label_line = i
			end
		else
			term.setBackgroundColor(256)
			term.write(width)
		end
	end
end
generate()
draw()
while running do
	local e, d, x, y = coroutine.yield()
	if e == "mouse_click" then
		local tmp = generated[y + offset]
		if tmp then
			if tmp[2] == "header" then
				tmp[3] = not tmp[3]
				local abcd = tmp[3] and addItems or removeItems
				abcd(y + offset, tmp[4])
				draw()
			elseif tmp[2] == "boolean" then
				if user_settings[tmp[3]] then
					user_settings[tmp[3]] = not user_settings[tmp[3]]
				else
					user_settings[tmp[3]] = not tmp[4]
				end
				draw(y)
			elseif tmp[2] == "color" then
				local a = col[user_settings[tmp[3]] and user_settings[tmp[3]] or tmp[4]]
				if x == w - 3 then
					user_settings[tmp[3]] = 2 ^ (a - 1 == -1 and 15 or a - 1)
				elseif x == w - 1 then
					user_settings[tmp[3]] = 2 ^ (a + 1 == 16 and 0 or a + 1)
				end
				draw(y)
			elseif tmp[2] == "select" then
				local a = 0
				for i = y + offset, 1, -1 do
					if generated[i][2] == "label" then
						a = y + offset - i
						break
					end
				end
				user_settings[tmp[4]] = a
				draw()
			end
		end
	elseif e == "mouse_scroll" then
		if d == 1 and #generated - offset > h then
			offset = offset + 1
			draw()
		elseif d == -1 and offset > 0 then
			offset = offset - 1
			draw()
		end
	elseif e == "term_resize" then
		w, h = term.getSize()
		width = (" "):rep(w)
		draw()
	end
end
