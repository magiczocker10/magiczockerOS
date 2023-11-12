-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
-- variables
local _x, _y, cur_col
local changelog_scroll = 0
local color_selection = math.random(1, 4)
local draw_bottom
local draw_top
local filter_colors = false
local generate_list
local list_scroll = 0
local load_settings
local menu
local menu_open = false
local menu_scroll = 0
local menu_selection = 1
local menu_width = 0
local name = "Settings"
local offset = 0
local reset_user_settings
local setup_entries
local sys_set
local timer
local version = "Ver. 1.0"
local view = 0
local w, h = term.getSize()
local filter_calendar = not fs.exists("/magiczockerOS/programs/calendar.lua")
local filter_contextmenu = not fs.exists("/magiczockerOS/programs/contextmenu.lua")
local filter_desktop = not fs.exists("/magiczockerOS/programs/desktop.lua")
local filter_login = not fs.exists("/magiczockerOS/programs/login.lua")
local filter_osk = not fs.exists("/magiczockerOS/programs/osk.lua")
local filter_search = not fs.exists("/magiczockerOS/programs/search.lua")
local key_map_setting
local events
if not term.isColor or not term.isColor() then
	filter_colors = true
end
-- tables
local mon_settings = {
	mon_cursor = 1,
	mon_selected = 1,
	list_scroll = 0,
	list_entries = {},
	mon_order = {
	-- "right",
	-- "left",
	-- ...
	},
}
local monitor_used = {}
local textfield_variables = {}
local cur_textfield = {}
local categories = {
	{
		active = not filter_calendar,
		title = "Calendar",
		entries = {
			{title = "Background", type = "color", value = "calendar_back"},
			{title = "Text", type = "color", value = "calendar_text"},
			{title = "Text Highlight", type = "color", value = "calendar_text_highlight"},
		}
	},
	{
		active = os.time ~= nil,
		title = "Clock",
		entries = {
			{title = "24h", type = "boolean", value = "clock_format"},
			{title = "Background Active", type = "color", value = "clock_back_active"},
			{title = "Text Active", type = "color", value = "clock_text_active"},
			{title = "Background Inactive", type = "color", value = "clock_back_inactive"},
			{title = "Text Inactive", type = "color", value = "clock_text_inactive"},
			{title = "Visible", type = "boolean", value = "clock_visible"},
		},
	},
	{
		active = not ((filter_colors or not term.setPaletteColor) and true or false),
		title = "Color Filters",
		entries = {
			{title = "Color Mode", type = "drop-down", value = "color_mode", entries = {"Off", "Achromatomaly", "Achromatopsia / Gray", "Deuteranomaly", "Deuteranopia", "Protanomaly", "Protanopia", "Sepia", "Tritanomaly", "Tritanopia"}},
			{title = "Invert: ", type = "boolean", value = "invert_colors"},
			{title = "Color palette", type = "drop-down", value = "color_palette", entries = {"Default", "Original", "Custom (setColorPalette)"}},
		},
	},
	{
		title = "Computer",
		entries = {
			{title = "Computer Label: ", default = os.getComputerLabel, on_save = function(label)
				os.setComputerLabel(label or nil)
				load_settings()
			end, type = "label", changeable = os.setComputerLabel ~= nil},
			{title = "Computer ID: " .. (os.getComputerID() or "Unknown ID"), type = ""},
		},
	},
	{
		active = not filter_contextmenu,
		title = "Context-Menu",
		entries = {
			{title = "Background", type = "color", value = "context_menu_background"},
			{title = "Text", type = "color", value = "context_menu_text"},
			{title = "Items Align", type = "drop-down", value = "context_menu_items_align", entries = {"left", "middle", "right"}},
		},
	},
	{
		active = not filter_desktop,
		title = "Desktop",
		entries = {
			{title = "Background", value = "desktop_back", type = "color"},
		},
	},
	{
		active = not filter_desktop,
		title = "Desktop-Dialogs",
		entries = {
			{title = "Bar-Background", value = "dialog_bar_background", type = "color"},
			{title = "Bar-Textcolor", value = "dialog_bar_text", type = "color"},
			{title = "Background", value = "dialog_background", type = "color"},
			{title = "Button-Background", value = "dialog_button_background", type = "color"},
			{title = "Button-Textcolor", value = "dialog_button_text", type = "color"},
		},
	},
	{
		active = not filter_osk,
		title = "Key-Mapping",
		entries = {
			{title = "Mapping", type = "drop-down", value = "osk_key_mapping", entries = {}},
		},
	},
	{
		active = set_monitor_settings and peripheral and term and term.isColor and term.isColor(),
		title = "Monitor (Global Settings)",
		entries = {
			{title = "Mode", system_setting = true, type = "drop-down", value = "monitor_mode", entries = {"normal", "duplicate", "extend"}},
			{title = "Manage Screens", system_setting = true, default = "", type = "label", display_text = "Manage >", changeable = true, on_click = function()
				view = 2
				if view == 2 then
					mon_settings.mon_order = sys_set.devices or {}
					monitor_used = {}
					for i = 1, #mon_settings.mon_order do
						monitor_used[mon_settings.mon_order[i]] = true
					end
				end
				mon_settings.mon_cursor = 1
				mon_settings.mon_selected = 1
				setup_entries()
				draw_top()
				draw_bottom()
			end, },
		},
	},
	{
		title = "Mouse",
		entries = {
			{title = "Double-click speed", value = "mouse_double_click_speed", steps = 0.1, type = "number"},
			{title = "Inactive window scroll", value = "mouse_inactive_window_scroll", type = "boolean"},
			{title = "Left-handed", value = "mouse_left_handed", type = "boolean"},
		},
	},
	{
		active = not filter_search,
		title = "Search",
		entries = {
			{title = "Background", value = "search_back", type = "color"},
			{title = "Text", value = "search_text", type = "color"},
			{title = "Seperator-Text", value = "search_seperator_text", type = "color"},
			{title = "Searchfield Text", value = "search_field_text", type = "color"},
			{title = "Taskbar Button Back (Active)", value = "search_button_active_back", type = "color"},
			{title = "Taskbar Button Text (Active)", value = "search_button_active_text", type = "color"},
			{title = "Taskbar Button Back (Inactive)", value = "search_button_inactive_back", type = "color"},
			{title = "Taskbar Button Text (Inactive)", value = "search_button_inactive_text", type = "color"},
		},
	},
	{
		title = "Startmenu",
		entries = {
			{title = "Background", value = "startmenu_back", type = "color"},
			{title = "Text", value = "startmenu_text", type = "color"},
			{title = "Button Active Background", value = "startmenu_button_active_back", type = "color"},
			{title = "Button Active Text", value = "startmenu_button_active_text", type = "color"},
			{title = "Button Inactive Background", value = "startmenu_button_inactive_back", type = "color"},
			{title = "Button Inactive Text", value = "startmenu_button_inactive_text", type = "color"},
			{title = "Items Align", type = "drop-down", value = "startmenu_items_align", entries = {"left", "middle", "right"}},
		},
	},
	{
		title = "Taskbar",
		entries = {
			{title = "Background", value = "taskbar_back", type = "color"},
			{title = "Items Active Background", value = "taskbar_items_active_back", type = "color"},
			{title = "Items Active Text", value = "taskbar_items_active_text", type = "color"},
			{title = "Items Inactive Background", value = "taskbar_items_inactive_back", type = "color"},
			{title = "Items Inactive Text", value = "taskbar_items_inactive_text", type = "color"},
		},
	},
	{
		active = not user_data().server,
		title = "User",
		entries = {},
	},
	{
		active = not filter_login and not user_data().server,
		title = "Users",
		entries = {},
	},
	{
		title = "Window (Active)",
		entries = {
			{title = "Bar Background", value = "window_bar_active_back", type = "color"},
			{title = "Bar Text", value = "window_bar_active_text", type = "color"},
			{title = "Close Button Background", value = "window_close_button_active_back", type = "color"},
			{title = "Close Button Text", value = "window_close_button_active_text", type = "color"},
			{title = "Maximize Button Background", value = "window_maximize_button_active_back", type = "color"},
			{title = "Maximize Button Text", value = "window_maximize_button_active_text", type = "color"},
			{title = "Minimize Button Background", value = "window_minimize_button_active_back", type = "color"},
			{title = "Minimize Button Text", value = "window_minimize_button_active_text", type = "color"},
			{title = "Resize Border Background", value = "window_resize_border_back", type = "color"},
			{title = "Resize Border Text", value = "window_resize_border_text", type = "color"},
			{title = "Resize Button Background", value = "window_resize_button_back", type = "color"},
			{title = "Resize Button Text", value = "window_resize_button_text", type = "color"},
		},
	},
	{
		title = "Window (Inactive)",
		entries = {
			{title = "Bar Background", value = "window_bar_inactive_back", type = "color"},
			{title = "Bar Text", value = "window_bar_inactive_text", type = "color"},
			{title = "Close Button Background", value = "window_close_button_inactive_back", type = "color"},
			{title = "Close Button Text", value = "window_close_button_inactive_text", type = "color"},
			{title = "Maximize Button Background", value = "window_maximize_button_inactive_back", type = "color"},
			{title = "Maximize Button Text", value = "window_maximize_button_inactive_text", type = "color"},
			{title = "Minimize Button Background", value = "window_minimize_button_inactive_back", type = "color"},
			{title = "Minimize Button Text", value = "window_minimize_button_inactive_text", type = "color"},
		},
	},
	{
		title = "About",
		entries = {
			{title = os.version(), default = "", on_save = nil, type = "label", changeable = false},
		},
	},
}
local changelog = {
	"(c) magiczocker",
	"",
	"Version 1.0",
	" First release",
}
local color_palette = {}
for i = 0, 15 do
	color_palette[i + 1] = 2 ^ i
end
local cursor = {1, 0, 0}
local key_maps = {}
local list = {}
local settings = {}
local total_entries = {}
local theme = {top = {128, 2, 2048, 512}, bottom = {256, 16, 8, 8}}
-- functions
local a = term and term.isColor and term.isColor() and 3 or textutils and textutils.complete and 2 or 1
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function write_text(a, b, c, d)
	term.write(not term.isColor and a or term.isColor() and d or textutils and type(textutils.complete) == "function" and c or b)
end
local function write_t(s)
	local tmp = #s
	if _x > w then
		return
	end
	local tt = theme.top[color_selection]
	local tb = theme.bottom[color_selection]
	if _y == 4 and _x == 1 and mon_settings.mon_cursor > 1 then
		term.setTextColor(cur_col == tt and tb or tt)
		term.write"<"
		term.write(s:sub(2))
	elseif _y == 4 and _x == w then
		term.setTextColor(cur_col == tt and tb or tt)
		term.write">"
	elseif _y == 4 and _x + tmp > w then
		term.setTextColor(cur_col == tt and tb or tt)
		term.write(s:sub(1, w - _x - tmp) .. ">")
	else
		term.write(s)
	end
	_x = _x + tmp
end
function setup_entries()
	mon_settings.list_scroll = 0
	mon_settings.list_entries = {}
	local entries = mon_settings.list_entries
	if mon_settings.mon_selected <= #mon_settings.mon_order then
		if mon_settings.mon_selected > 1 then
			entries[#entries + 1] = "Move 1 left"
			entries[#entries + 1] = "Move left"
		end
		if mon_settings.mon_selected < #mon_settings.mon_order then
			entries[#entries + 1] = "Move 1 right"
			entries[#entries + 1] = "Move right"
		end
		entries[#entries + 1] = "Delete"
	else
		local __ = peripheral.getNames()
		for i = 1, #__ do
			if peripheral.getType(__[i]) == "monitor" and not monitor_used[__[i]] and peripheral.call(__[i], "isColor") then
				entries[#entries + 1] = __[i]
			end
		end
		table.sort(entries)
		if not monitor_used["computer"] then
			for i = #entries, 1, -1 do
				entries[i + 1] = entries[i]
			end
			entries[1] = "computer"
		end
	end
end
local function load_users()
	for i = 1, #categories do
		if categories[i].title == "User" and (categories[i].active==nil or categories[i].active) then
			categories[i].entries = {}
			local _temp = categories[i].entries
			_temp[#_temp + 1] = {default = "Change Password", on_save = function(new_pass)
				local file = fs.open("/magiczockerOS/users/" .. user .. "/password.txt", "w")
				if file then
					file.write(new_pass)
					file.close()
				end
			end, type = "label", changeable = true, user = true, display_text = "Change"}
		elseif categories[i].title == "Users" and (categories[i].active==nil or categories[i].active) then
			categories[i].entries = {}
			local _temp = categories[i].entries
			local files = fs.list("/magiczockerOS/users") or {}
			_temp[#_temp + 1] = {default = "Add user", on_save = function(name)
				if fs.exists("/magiczockerOS/users/" .. name) then
					view = 1
				else
					fs.makeDir("/magiczockerOS/users/" .. name .. "/desktop")
				end
				generate_list()
			end, type = "label", changeable = true, user = true, display_text = "+"}
			for k = 1, #files do
				if files[k] ~= user then
					_temp[#_temp + 1] = {default = files[k], deleteable = true, on_save = function(username)
						logout_user(username)
						if fs.exists("/magiczockerOS/users/" .. username) then
							fs.delete("/magiczockerOS/users/" .. username)
						end
						generate_list()
						draw_bottom()
					end, type = "label", changeable = true, user = true, display_text = "Delete"}
				end
			end
		end
	end
end
local function load_key_mapping()
	local tmp = type(settings.osk_key_mapping)=="string" and settings.osk_key_mapping or nil
	for i = 1, #categories do
		if categories[i].title == "Key-Mapping" then
			categories[i].entries[1].default = 1
			key_map_setting = key_map_setting or i
			categories[i].entries[1].entries={}
			local _temp = categories[i].entries[1].entries
			for k, v in next, fs.list("/magiczockerOS/key_mappings/") do
				if k ~= "n" and v:sub(-4) == ".map" and v ~= "base.map" then
					_temp[#_temp + 1] = v:sub(1, -5)
					if _temp[#_temp] == (tmp or "") then
						settings.osk_key_mapping = #_temp
					end
					if _temp[#_temp] == "qwerty" then
						categories[i].entries[1].default = #_temp
					end
				end
			end
			break
		end
	end
end
local function draw_text_line(blink)
	if cur_textfield.org_y - cur_textfield.scroll < 4 then
		return
	end
	term.setCursorPos(offset + cur_textfield.org_x, cur_textfield.org_y - cur_textfield.scroll)
	back_color(32768, 1, 1)
	text_color(1, 32768, 32768)
	term.write(((cur_textfield.value or "") .. ((not term.isColor or not term.isColor()) and "_" or " "):rep(cur_textfield.width)):sub(1 + cur_textfield.offset, cur_textfield.width + cur_textfield.offset))
	if blink then
		term.setCursorPos(cur_textfield.org_x - 1 + offset + cur_textfield.cursor - cur_textfield.offset, cur_textfield.org_y - cur_textfield.scroll)
		term.setCursorBlink(true)
	end
end
local function set_cursor(blink, data, block_pos)
	term.setCursorBlink(false)
	local a = cur_textfield
	a.cursor = a.cursor - 1 > #a.value and #a.value + 1 or a.cursor
	if a.cursor <= a.offset then
		a.offset = a.cursor - 1
	elseif a.cursor > a.width + a.offset then
		a.offset = a.cursor - a.width
	end
	a.offset = a.offset < 0 and 0 or a.offset
	draw_text_line(blink)
end
function generate_list()
	load_key_mapping()
	load_users()
	list = {}
	total_entries = {}
	local success
	local temp = 0
	for i = 1, #categories do
		temp = temp + 1
		total_entries[#total_entries + 1] = {id = temp, data = {}, category = i}
		list[#list + 1] = {id = temp, type = "empty", no_shadow = temp == 1, category = i}
		list[#list + 1] = {id = temp, type = "category_title", category = i}
		list[#list + 1] = {id = temp, type = "category_bottom", category = i}
		local _te = total_entries[#total_entries].data
		success = false
		if categories[i].active == nil or categories[i].active then
			if categories[i].expanded then
				for j = 1, #categories[i].entries do
					local tmp = categories[i].entries[j]
					if not (filter_colors and tmp.type == "color") then
						success = true
						_te[#_te + 1] = {j}
						list[#list + 1] = {id = temp, type = "empty", category = i, entry = j}
						list[#list + 1] = {id = temp, type = "entry_title", category = i, entry = j}
						if tmp.type == "drop-down" then
							list[#list + 1] = {id = temp, type = "empty", category = i, entry = j}
							for k = 1, #tmp.entries do
								list[#list + 1] = {id = temp, type = "entry_drop-down", category = i, entry = j, entry_no = k}
							end
						elseif tmp.type == "color" then
							list[#list + 1] = {id = temp, type = "empty", category = i, entry = j}
							list[#list + 1] = {id = temp, type = "color_palette", category = i, entry = j}
						end
						list[#list + 1] = {id = temp, type = (j < #categories[i].entries and "entry" or "category") .. "_bottom", category = i, entry = j}
					end
				end
			else
				for j = 1, #categories[i].entries do
					if not filter_colors or filter_colors and categories[i].entries[j].type ~= "color" then
						success = true
						break
					end
				end
			end
		end
		if not success then
			temp = temp - 1
			total_entries[#total_entries] = nil
			list[#list] = nil
			list[#list] = nil
			list[#list] = nil
		end
		if i == #categories and #list > 0 then
			list[#list].type = "empty"
			list[#list + 1] = {type = "shadow"}
		end
	end
end
local function draw_cursor(y,force_not)
	if not term.isColor or not term.isColor() and not force_not then
		term.write(total_entries[cursor[1]].id == list[y].id and ((cursor[2] or 0)==(list[y].entry or 0) or total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][1] == list[y].entry) and (cursor[3] or 0) == (list[y].entry_no or 0) and ">" or " ")
	else
		term.write" "
	end
end
function draw_bottom(line)
	if line and line<4 then
		return
	end
	if view == 1 and not textfield_variables["values_set"] then
		cur_textfield.org_x = 3
		textfield_variables["values_set"] = true
		for i = 1, #textfield_variables["values"] do
			textfield_variables["org_y"][i] = 5 * i + 1
		end
		cur_textfield.org_y = textfield_variables["org_y"][textfield_variables["selected"]]
	end
	local _width = (" "):rep(w)
	for i = line or 4, line or h do
		back_color(32768, 256, theme.bottom[color_selection])
		if not line then
			term.setCursorPos(1 + offset, i)
		end
		if view == 0 and list[i - 4 + list_scroll] then
			text_color(1, 1, 1)
			local line=i - 4 + list_scroll
			if list[line].type == "category_title" then
				draw_cursor(line)
				text_color(32768, 128, 128)
				back_color(1, 1, 1)
				term.write((" " .. (categories[list[line].category].expanded and "^" or "v") .. " " .. categories[list[line].category].title .. _width):sub(1, w - 3))
			elseif list[line].type == "category_bottom" then
				if list[line].entry then
					if categories[list[line].category].entries[list[line].entry].type ~= "drop-down" and (not term.isColor or not term.isColor()) then
						term.write(total_entries[cursor[1]].id == list[line].id and total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][1] == list[line].entry and ">" or " ")
					else
						term.write" "
					end
				else
					draw_cursor(line)
				end
				back_color(1, 1, 1)
				text_color(32768, 128, 128)
				term.write(("_"):rep(w - 3))
			elseif list[line].type == "entry_title" then
				local category = categories[list[line].category].entries[list[line].entry]
				local _value = category.system_setting and sys_set or settings
				draw_cursor(line,category.type == "drop-down")
				back_color(1, 1, 1)
				text_color(32768, 256, 256)
				if category.type == "text" then
					term.write((" " .. category.title .. _width):sub(1, w - 5) .. "> ")
				elseif category.type == "number" or category.type == "boolean" then
					local __ = _value[category.value]
					if __ == nil then
						__ = category.default
					end
					if category.type == "number" then
						term.write((" " .. category.title .. _width):sub(1, w - 9 - #(__ .. "")) .. " - " .. __ .. " + ")
					else
						term.write((" " .. category.title .. _width):sub(1, w - 6))
						text_color(32768, 256, __ and 32 or 16384)
						term.write(__ and "-O" or "O-")
						term.write" "
					end
				else
					local temp = ""
					local __
					if category.type == "label" then
						temp = " " .. (category.changeable and (category.display_text or "Change") or "") .. " "
						__ = _value[category.value] and category.value or category.default
						if type(__) == "function" then
							__ = __()
						end
					end
					term.write((" " .. (category.title or "") .. (__ or "") .. _width):sub(1, w - 3 - #temp))
					text_color(1, 128, theme.top[color_selection])
					term.write(temp)
				end
			elseif list[line].type == "entry_bottom" then
				draw_cursor(line,(categories[list[line].category].entries[list[line].entry].type or "") == "drop-down")
				back_color(1, 1, 1)
				text_color(32768, 256, 256)
				term.write(("_"):rep(w - 3))
			elseif list[line].type == "empty" then
				if list[line].category and list[line].entry then
					draw_cursor(line,(categories[list[line].category].entries[list[line].entry].type or "") == "drop-down")
				else
					draw_cursor(line)
				end
				back_color(1, 1, 1)
				term.write(_width:sub(1,-4))
			elseif list[line].type == "entry_drop-down" then
				local category = categories[list[line].category].entries[list[line].entry]
				local __ = category.system_setting and sys_set[category.value] or not category.system_setting and settings[category.value]
				if __ == nil then
					__ = category.default
				end
				draw_cursor(line)
				back_color(1, 1, 1)
				text_color(32768, 256, 256)
				term.write((" " .. (__ == list[line].entry_no and "X " or "O ") .. category.entries[list[line].entry_no] .. _width):sub(1, w - 3))
			elseif list[line].type == "color_palette" then
				local category = categories[list[line].category].entries[list[line].entry]
				local __ = category.system_setting and system_setting[category.value] or not category.system_setting and settings[category.value]
				if __ == nil then
					__ = category.default
				end
				draw_cursor(line)
				back_color(1, 1, 1)
				term.write" "
				for j = 1, #color_palette do
					term.setBackgroundColor(color_palette[j])
					term.setTextColor(color_palette[j] == 1 and 32768 or 1)
					term.write(__ == color_palette[j] and "X" or __ == (color_palette[j+1] or 0) and ">" or __ == (color_palette[j-1] or 0) and "<" or " ")
				end
				back_color(1, 1, 1)
				term.write(_width:sub(1,-5-#color_palette))
			elseif list[line].type == "shadow" then
				local tmp1 = ("-"):rep(w - 4) .. " "
				local tmp2 = _width:sub(1,-4)
				term.write"  "
				back_color(1, 128, 128)
				write_text(tmp1, tmp1 .. " ", tmp2, tmp2)
				back_color(32768, 256, theme.bottom[color_selection])
				term.write" "
			end
			if list[line].type ~= "shadow" then
				if list[line].no_shadow then
					back_color(32768, 256, theme.bottom[color_selection])
					term.write" "
				else
					back_color(32768, 128, 128)
					text_color(1, 256, 256)
					write_text("|", "|", " ", " ")
				end
				back_color(32768, 256, theme.bottom[color_selection])
				term.write" "
			end
		elseif view == 1 then
			back_color(32768, 256, theme.bottom[color_selection])
			if i - 3 + cur_textfield.scroll <= 5 * #textfield_variables["values"] then
				local tmp = (i - 3 + cur_textfield.scroll) % 5
				if tmp == 0 then -- shadow
					term.write"  "
					back_color(1, 128, 128)
					term.write(_width:sub(1,-4))
					back_color(32768, 256, theme.bottom[color_selection])
					term.write" "
				elseif tmp == 1 then -- empty line
					term.write(_width)
				elseif tmp == 2 or tmp == 4 then -- first line (empty)
					term.write" "
					back_color(1, 1, 1)
					term.write(_width:sub(1,-4))
					if tmp == 2 then
						back_color(32768, 256, theme.bottom[color_selection])
					else
						back_color(32768, 128, 128)
					end
					term.write" "
					back_color(32768, 256, theme.bottom[color_selection])
					term.write" "
				elseif tmp == 3 then -- second line (text)   --set_cursor((i-1+cur_textfield.scroll)*0.2,i)
					local __ = (i - 1 + cur_textfield.scroll) * 0.2
					text_color(1, 128, theme.bottom[color_selection])
					term.write(textfield_variables["selected"] == __ and ">" or " ")
					back_color(1, 1, 1)
					term.write" "
					text_color(1, 32768, 32768)
					if __ > 0 and textfield_variables["values"][__] then
						term.write((textfield_variables["values"][__] .. ((not term.isColor or not term.isColor()) and "_" or " "):rep(w - 5)):sub(1 + textfield_variables.offset[__], w - 5 + textfield_variables.offset[__]))
					else
						term.write(((not term.isColor or not term.isColor()) and "_" or " "):rep(w - 5))
					end
					term.write" "
					back_color(32768, 128, 128)
					term.write" "
					back_color(32768, 256, theme.bottom[color_selection])
					text_color(1, 128, theme.bottom[color_selection])
					term.write(textfield_variables["selected"] == __ and "<" or " ")
				end
			elseif i - 4 + cur_textfield.scroll > 5 * #textfield_variables["values"] and i - 4 + cur_textfield.scroll <= 5 * #textfield_variables["values"] + 3 then
				local tmp = (i - 4 + cur_textfield.scroll - 5 * #textfield_variables["values"]) % 3
				if tmp == 0 or tmp == 1 then
					term.write((" "):rep(w - #textfield_variables["button_text"] - 3))
					back_color(1, 128, theme.top[color_selection])
					text_color(32768, 1, 1)
					term.write((" "):rep(#textfield_variables["button_text"]) .. "  ")
					back_color(32768, 256, theme.bottom[color_selection])
					term.write" "
				elseif tmp == 2 then
					term.write((" "):rep(w - #textfield_variables["button_text"] - 3))
					back_color(1, 128, theme.top[color_selection])
					text_color(1, 1, 1)
					term.write(textfield_variables["selected"] == #textfield_variables["values"] + 1 and ">" or " ")
					text_color(32768, 1, 1)
					term.write(textfield_variables["button_text"])
					text_color(1, 1, 1)
					term.write(textfield_variables["selected"] == #textfield_variables["values"] + 1 and "<" or " ")
					back_color(32768, 256, theme.bottom[color_selection])
					term.write" "
				end
			else
				back_color(32768, 256, theme.bottom[color_selection])
				term.write(_width)
			end
		elseif view == 2 and sys_set.monitor_mode > 1 then
			_x = 1
			_y = i
			if i < 13 then
				local tmp = 0
				for j = mon_settings.mon_cursor, #mon_settings.mon_order do
					tmp = tmp + 10
					local __ = j == mon_settings.mon_selected
					local _col = __ and theme.top[color_selection] or theme.bottom[color_selection]
					back_color(__ and 32768 or 1, __ and  128 or 256, __ and theme.top[color_selection] or theme.bottom[color_selection])
					if i == 4 or i == 10 or i == 12 then -- empty space
						write_t("          ")
					elseif i == 5 or i == 9 then -- top/bottom monitor border
						term.write(" ")
						term.setBackgroundColor(_col == 16 and 2 or 16)
						term.write("        ")
						term.setBackgroundColor(_col)
						term.write(" ")
					elseif i > 5 and i < 9 then -- monitor screen (black part)
						term.write(" ")
						term.setBackgroundColor(_col == 16 and 2 or 16)
						term.write(" ")
						term.setBackgroundColor(32768)
						term.write"      "
						term.setBackgroundColor(_col == 16 and 2 or 16)
						term.write(" ")
						term.setBackgroundColor(_col)
						term.write(" ")
					elseif i == 11 then -- text-line
						term.setTextColor(__ and theme.bottom[color_selection] or theme.top[color_selection])
						term.write((" " .. mon_settings.mon_order[j] .. _width):sub(1, 10))
					end
					if _x > w then
						break
					end
				end
				if _x < w then
					local __ = mon_settings.mon_selected > #mon_settings.mon_order
					local tt = theme.top[color_selection]
					local tb = theme.bottom[color_selection]
					if i == 6 or i == 8 then
						term.setBackgroundColor(__ and tt or tb)
						term.write("  ")
						term.setBackgroundColor(__ and tb or tt)
						term.write(" ")
						term.setBackgroundColor(__ and tt or tb)
						term.write("  ")
					elseif i == 7 then
						term.setBackgroundColor(__ and tt or tb)
						term.write(" ")
						term.setBackgroundColor(__ and tb or tt)
						term.write("   ")
						term.setBackgroundColor(__ and tt or tb)
						term.write(" ")
					elseif i == 11 then
						term.setBackgroundColor(__ and tt or tb)
						term.setTextColor(__ and tb or tt)
						term.write(" Add ")
					else
						back_color(32768, 32768, mon_settings.mon_selected > #mon_settings.mon_order and tt or tb)
						write_t("     ")
					end
				end
				if _x + 5 < w then
					back_color(1, 1, tb)
					write_t((" "):rep(w - tmp - 5))
				end
			else
				term.setBackgroundColor(theme.top[color_selection])
				term.setTextColor(theme.bottom[color_selection])
				term.write((" " .. (mon_settings.list_entries[i - 13 + mon_settings.list_scroll] or "") .. _width):sub(1, w))
			end
		else
			text_color(1, 1, 1)
			term.write(_width)
		end
	end
	if view == 1 and textfield_variables["selected"] <= #textfield_variables["values"] then
		set_cursor(true)
	end
end
local function draw_changelog(line)
	if line and line<4 then
		return
	end
	local _cursor=term.setCursorPos
	if line then
		_cursor=function() end
	end
	local _width = (" "):rep(w)
	back_color(32768, 256, theme.bottom[color_selection])
	text_color(1, 1, 1)
	_cursor(1 + offset, 4)
	if (line or 4)==4 then
		term.write(_width)
	end
	if (line or 1)<h then
		for i = line or 5, line or h - 1 do
			_cursor(1 + offset, i)
			term.write(changelog[i - 4 + changelog_scroll] and " " .. changelog[i - 4 + changelog_scroll] .. _width or _width)
		end
	end
	_cursor(1 + offset, h)
	if (line or h)==h then
		term.write(_width)
	end
end
local function draw_menu(a)
	for a=a or 1,a or h do
		term.setCursorPos(1, a)
		if offset > 0 then
			local d
			if a > 1 and a < h - 2 and menu[a - 1 + menu_scroll] then
				text_color(32768, a - 1 + menu_scroll == menu_selection and 1 or 256, 1)
				local c = (menu_width - #menu[a - 1 + menu_scroll].txt) * 0.5
				d = (a - 1 + menu_scroll == menu_selection and menu_select or " ") .. (" "):rep(math.floor(c) - 1) .. menu[a - 1 + menu_scroll].txt .. (" "):rep(math.ceil(c) - 1) .. (a - 1 + menu_scroll == menu_selection and menu_select or " ")
			elseif a == h - 1 then
				text_color(32768, 0 == menu_selection and 1 or 256, 1)
				local c = (menu_width - #version) * 0.5
				d = (0 == menu_selection and menu_select or " ") .. (" "):rep(math.floor(c) - 1) .. version .. (" "):rep(math.ceil(c) - 1) .. (0 == menu_selection and menu_select or " ")
			else
				d = (" "):rep(offset)
			end
			back_color(1, 128, 128)
			term.write(d:sub(-offset))
		end
	end
end
function draw_top(line)
	local _cursor=term.setCursorPos
	if line then
		_cursor=function() end
	end
	local _width = (" "):rep(w)
	back_color(1, 128, theme.top[color_selection])
	text_color(32768, 1, 1)
	_cursor(1 + offset, 1)
	if (line or 1)==1 then
		term.write(_width)
	end
	_cursor(1 + offset, 2)
	if (line or 2)==2 then
		if view == -1 or view == 1 or view == 2 then
			term.write(" < " .. name .. _width)
		elseif view == 0 then
			term.write(" = " .. name .. _width)
		end
	end
	_cursor(1 + offset, 3)
	if (line or 3)==3 then
		write_text(("_"):rep(w), _width, _width, _width)
	end
end
local function redraw()
	for i=1,h do
		draw_menu(i)
		draw_top(i)
		if view == -1 then
			draw_changelog(i)
		elseif view == 0 or view == 1 then
			draw_bottom(i)
		end
	end
end
local function setup_textfield(count, setting)
	view = 1
	if count <= 0 then
		count = 1
	end
	local t_var = textfield_variables
	t_var.values_set = false
	t_var.values = {}
	t_var.org_y = {}
	t_var.offset = {}
	t_var.cursor = {}
	for _ = 1, count do
		t_var.values[#t_var.values + 1] = ""
		t_var.org_y[#t_var.org_y + 1] = 0
		t_var.offset[#t_var.offset + 1] = 0
		t_var.cursor[#t_var.cursor + 1] = 1
	end
	t_var.selected = 1
	t_var.button_text = "Change"
	t_var.button_on_click = function()
		local setting = setting
		view = 0
		setting.on_save(unpack(t_var.values))
		redraw()
	end
	cur_textfield.cursor = 1
	cur_textfield.offset = 0
	cur_textfield.value = ""
	cur_textfield.org_x = 3
	cur_textfield.org_y = 0
	cur_textfield.scroll = 0
	cur_textfield.width = w - 4
	redraw()
end
local function set_menu_width()
	menu_width = 0
	for i = 1, #menu do
		if #menu[i].txt > menu_width then
			menu_width = #menu[i].txt
		end
	end
	if #version > menu_width then
		menu_width = #version
	end
	menu_width = menu_width + 2
end
local function scroll_to_cursor(go_up)
	local from, to, dir = go_up and #list or 1, go_up and 1 or #list, go_up and -1 or 1
	local success = false
	for i = from, to, dir do
		if (cursor[2] == 0 and not list[i].entry and list[i].id == total_entries[cursor[1]].id) or
		   (cursor[2] > 0 and (total_entries[cursor[1]].id or 0) == list[i].id and 
		   total_entries[cursor[1]].data[cursor[2]] and 
		   (total_entries[cursor[1]].data[cursor[2]][1] or 0) == (list[i].entry or 0) and 
		   (cursor[3] or 0) == (list[i].entry_no or 0)) then
			list_scroll = i - list_scroll < 1 and i - 1 or list_scroll
			list_scroll = i - list_scroll > h - 4 and i + 4 - h or list_scroll
			success = true
		elseif success then
			break
		end
	end
	if list_scroll < 0 then
		list_scroll = 0
	end
end
local function correct_scroll()
	local tmp = #list
	list_scroll = list_scroll > 0 and tmp - list_scroll < h - 5 and tmp - h + 5 or list_scroll
	list_scroll = list_scroll < 0 and 0 or list_scroll
end
function load_settings()
	settings = user_data().settings or {}
end
local function change_mon_setting(num)
	local tmp = categories[num].entries[2]
	if sys_set.monitor_mode > 1 and sys_set.monitor_mode < 4 then
		tmp.title = "Manage Screens"
		tmp.default = ""
		tmp.value = nil
		tmp.type = "label"
	else
		tmp.type = "drop-down"
		tmp.title = "Please select"
		tmp.default = 1
		tmp.value = "monitor"
		tmp.entries = {}
		local category = tmp.entries
		local __ = peripheral.getNames and peripheral.getNames() or {}
		for i = 1, #__ do
			if peripheral.getType(__[i]) == "monitor" and peripheral.call(__[i], "isColor") then
				category[#category + 1] = __[i]
			end
		end
		table.sort(category)
		for i = #category, 1, -1 do
			category[i + 1] = category[i]
		end
		category[1] = "computer"
		if #sys_set.devices > 0 then
			for i = 1, #category do
				if category[i] == sys_set.devices[1] then
					sys_set.monitor = i
					break
				end
			end
		end
	end
end
local function save_user_settings()
	local tmp = settings.osk_key_mapping or nil
	settings.osk_key_mapping = settings.osk_key_mapping and categories[key_map_setting].entries[1].entries[settings.osk_key_mapping] or nil
	save_settings(settings)
	settings.osk_key_mapping = tmp
end
local function save_system_settings(not_set)
	if not fs.exists("/magiczockerOS/settings.json") or fs.exists("/magiczockerOS/settings.json") and not fs.isReadOnly("/magiczockerOS/settings.json") then
		local file = fs.open("/magiczockerOS/settings.json", "w")
		if file then
			local id
			for i = 1, #categories do
				if categories[i].title == "Monitor (Global Settings)" then
					id = i
					break
				end
			end
			local mode = sys_set.monitor_mode
			local __ = sys_set.monitor
			if sys_set.monitor_mode then
				if sys_set.monitor_mode == 2 then
					sys_set.monitor_mode = "duplicate"
				elseif sys_set.monitor_mode == 3 then
					sys_set.monitor_mode = "extend"
				else
					if id and sys_set.monitor then
						sys_set.devices = {
							categories[id].entries[2].entries[sys_set.monitor],
						}
					end
					sys_set.monitor_mode = "normal"
				end
			end
			sys_set.monitor = nil
			if view == 2 then
				sys_set.devices = mon_settings.mon_order
			end
			file.write(textutils.serialize(sys_set))
			file.close()
			if not not_set and set_monitor_settings then
				set_monitor_settings(sys_set.monitor_mode, unpack(sys_set.devices))
			end
			sys_set.monitor = __
			sys_set.monitor_mode = mode
			if id then
				change_mon_setting(id)
				generate_list()
			end
			events("term_resize")
		end
	end
end
local function load_default_settings()
	for i = 1, #categories do
		for _, v in next, categories[i].entries do
			v.default = get_setting(nil, v.value) or v.default
		end
	end
end
local function load_system_settings()
	sys_set = nil
	if fs.exists("/magiczockerOS/settings.json") then
		local file = fs.open("/magiczockerOS/settings.json", "r")
		if file then
			local content = file.readAll()
			if content then
				sys_set = unserialise(content)
				if sys_set and sys_set.monitor_mode then
					local tmp = sys_set.monitor_mode
					tmp = tmp == "duplicate" and 2 or tmp == "extend" and 3 or 1
					sys_set.monitor_mode = tmp
				end
			end
			file.close()
		end
	end
	if not sys_set or type(sys_set) ~= "table" then
		sys_set = {monitor_mode = 1,devices = {}}
	end
	if #sys_set.devices == 0 then
		sys_set.devices = {"computer"}
		save_system_settings(true)
	end
	for i = 1, #categories do
		if categories[i].title == "Monitor (Global Settings)" then
			change_mon_setting(i)
			break
		end
	end
end
function reset_user_settings()
	save_settings({})
	set_settings()
	settings = user_data().settings or {}
end
local function load_sidemenu()
	menu = {[0] = {func = function() view = -1 end}}
	if view == 1 then
		menu[#menu + 1] = {txt = "< Back", func = function() view = 0 load_sidemenu() end}
	else
		menu[#menu + 1] = {txt = "Reset all", func = function() reset_user_settings() end}
	end
	set_menu_width()
end
local function scroll_field_cursor(dir)
	local tmp
	local t_var = textfield_variables
	if t_var.selected <= #t_var.values then
		tmp = t_var.org_y[t_var.selected] - 4
	else
		tmp = dir == "up" and 5 * #t_var.values or 5 * #t_var.values + 3
	end
	local c_t = cur_textfield
	if tmp - c_t.scroll > h - 4 then
		c_t.scroll = tmp + 4 - h
	end
	if tmp - c_t.scroll < 1 then
		c_t.scroll = tmp - 1
	end
end
-- start
do
	local a = _HOSTver >= 1132
	key_maps[a and 45 or 12] = "minus"
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 258 or 15] = "tab"
	key_maps[a and 259 or 14] = "backspace"
	key_maps[a and 261 or 211] = "delete"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
	key_maps[a and 334 or 13] = "add"
	key_maps[a and -1 or 78] = "add"
end
load_default_settings()
load_settings()
load_system_settings()
generate_list()
load_sidemenu()
redraw()
-- events
function events(...)
	local e = {...}
	if e[1] == "char" and view == 1 then
		cur_textfield.value = cur_textfield.value:sub(1, cur_textfield.cursor - 1) .. e[2] .. cur_textfield.value:sub(cur_textfield.cursor)
		cur_textfield.cursor = cur_textfield.cursor + 1
		set_cursor(true)
	elseif e[1] == "key" and offset == 0 and view == 1 and (key_maps[e[2]] == "backspace" or key_maps[e[2]] == "left" or key_maps[e[2]] == "right" or key_maps[e[2]] == "delete") then
		local _key = key_maps[e[2]]
		if _key == "backspace" and cur_textfield.cursor > 1 then
			cur_textfield.cursor = cur_textfield.cursor - 1
			cur_textfield.value = cur_textfield.value:sub(1, cur_textfield.cursor - 1) .. cur_textfield.value:sub(cur_textfield.cursor + 1)
			set_cursor(true)
		elseif _key == "left" and cur_textfield.cursor > 1 then
			cur_textfield.cursor = cur_textfield.cursor - 1
			set_cursor(true)
		elseif _key == "right" and cur_textfield.cursor <= #cur_textfield.value then
			cur_textfield.cursor = cur_textfield.cursor + 1
			set_cursor(true)
		elseif _key == "delete" and cur_textfield.cursor <= #cur_textfield.value then
			cur_textfield.value = cur_textfield.value:sub(1, cur_textfield.cursor - 1) .. cur_textfield.value:sub(cur_textfield.cursor + 1)
			set_cursor(true)
		end
	elseif e[1] == "key" and key_maps[e[2]] and (not term.isColor or not term.isColor()) then
		if key_maps[e[2]] == "backspace" and (view == -1 or view == 2) then
			if view == 2 then
				save_system_settings()
			end
			view = 0
			redraw()
		elseif key_maps[e[2]] == "tab" and (view == 0 or view == 1) then -- open/close menu
			menu_open = not menu_open
			load_sidemenu()
			timer = os.startTimer(0)
		elseif view == 0 and (key_maps[e[2]] == "minus" or key_maps[e[2]]=="add") and cursor[2] > 0 then
			local category = categories[total_entries[cursor[1]].category].entries[total_entries[cursor[1]].data[cursor[2]][1]]
			if category.type == "number" then
				local _value = category.system_setting and sys_set or settings
				local __ = _value[category.value]
				if __ == nil then
					__ = category.default
				end
				if __ > 0 then
					_value[category.value] = (__ - (key_maps[e[2]]=="add" and 0 or category.steps) + (key_maps[e[2]]=="add" and category.steps or 0) .. "") + 0
					if category.system_setting then
						save_system_settings()
					else
						save_user_settings()
					end
					set_settings(user)
					draw_bottom()
				end
			end
		elseif key_maps[e[2]] == "enter" then
			if menu_open then
				menu[menu_selection].func()
				menu_open = false
				timer = os.startTimer(0)
			elseif view == 0 and cursor[3] > 0 then
				local category = categories[total_entries[cursor[1]].category].entries[total_entries[cursor[1]].data[cursor[2]][1]]
				local __ = category.system_setting and sys_set or settings
				__[category.value] = cursor[3]
				if category.system_setting then
					save_system_settings()
				else
					save_user_settings()
				end
				set_settings(user)
				draw_bottom()
			elseif view == 0 and cursor[2] == 0 then
				categories[total_entries[cursor[1]].category].expanded = not categories[total_entries[cursor[1]].category].expanded
				generate_list()
				correct_scroll()
				draw_bottom()
			elseif view == 0 and cursor[2] > 0 then
				local category = categories[total_entries[cursor[1]].category].entries[total_entries[cursor[1]].data[cursor[2]][1]]
				if category.type == "boolean" then
					local _value = category.system_setting and sys_set or settings
					if _value[category.value] == nil then
						_value[category.value] = not category.default
					else
						_value[category.value] = not _value[category.value]
					end
					if category.system_setting then
						save_system_settings()
					else
						save_user_settings()
					end
					set_settings(user)
					draw_bottom()
				elseif (category.type == "label" or category.user) and category.changeable then
					if category.deleteable then
						category.on_save(category.default)
					elseif category.on_click then
						category.on_click(category.default)
					else
						setup_textfield(1, category)
					end
				end
			elseif view == 1 then
				if textfield_variables.selected <= #textfield_variables.values then
					textfield_variables.selected = textfield_variables.selected + 1
					draw_bottom()
				else
					textfield_variables.button_on_click()
				end
			end
		elseif key_maps[e[2]] == "up" then
			if menu_open then
				menu_selection = menu_selection > 0 and menu_selection - 1 or #menu
				if menu_selection == #menu and #menu > h - 4 then
					menu_scroll = #menu - h + 4
				elseif menu_selection > 0 and menu_selection - menu_scroll == 0 then
					menu_scroll = menu_scroll - 1
				end
				draw_menu()
			elseif view == -1 and changelog_scroll > 0 then
				changelog_scroll = changelog_scroll - 1
				draw_changelog()
			elseif view == 0 and (cursor[1] > 1 or cursor[2] > 0) then
				if cursor[3] > 0 then
					cursor[3] = cursor[3] - 1
					if cursor[3] == 0 then
						cursor[2] = cursor[2] - 1
						if cursor[2] > 0 and total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][2] then
							cursor[3] = total_entries[cursor[1]].data[cursor[2]][2]
						end
					end
				elseif cursor[2] > 0 then
					cursor[2] = cursor[2] - 1
					if cursor[2] == 0 then
						cursor[3] = 0
					elseif total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][2] then
						cursor[3] = total_entries[cursor[1]].data[cursor[2]][2]
					end
				elseif cursor[1] > 1 then
					cursor[1] = cursor[1] - 1
					cursor[2] = #total_entries[cursor[1]].data
						if total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][2] then
							cursor[3] = total_entries[cursor[1]].data[cursor[2]][2]
						end
				end
				scroll_to_cursor(true)
				draw_bottom()
			elseif view == 1 and textfield_variables.selected > 1 then
				textfield_variables.selected = textfield_variables.selected - 1
				scroll_field_cursor("up")
				draw_bottom()
			end
		elseif key_maps[e[2]] == "down" then
			if menu_open then
				menu_selection = menu_selection < #menu and menu_selection + 1 or 0
				if menu_selection == 1 then
					menu_scroll = 0
				elseif menu_selection - menu_scroll == h - 3 then
					menu_scroll = menu_scroll + 1
				end
				draw_menu()
			elseif view == -1 and #changelog - changelog_scroll > h - 5 then
				changelog_scroll = changelog_scroll + 1
				draw_changelog()
			elseif view == 0 then
				if total_entries[cursor[1]] and 
				total_entries[cursor[1]].data[cursor[2]] and 
				total_entries[cursor[1]].data[cursor[2]][2] and 
				cursor[3] < total_entries[cursor[1]].data[cursor[2]][2] then
					cursor[3] = cursor[3] + 1
					scroll_to_cursor()
					draw_bottom()
				elseif cursor[2] < #total_entries[cursor[1]].data then
					cursor[2] = cursor[2] + 1
					cursor[3] = total_entries[cursor[1]].data[cursor[2]] and total_entries[cursor[1]].data[cursor[2]][2] and 1 or 0
					scroll_to_cursor()
					draw_bottom()
				elseif cursor[1] < #total_entries then
					cursor[1] = cursor[1] + 1
					cursor[2] = 0
					cursor[3] = 0
					scroll_to_cursor()
					draw_bottom()
				end
			elseif view == 1 and textfield_variables.selected <= #textfield_variables.values then
				textfield_variables.selected = textfield_variables.selected + 1
				scroll_field_cursor("down")
				draw_bottom()
			end
		end
	elseif e[1] == "mouse_click" then
		e[3] = e[3] - offset
		if e[2] == 1 then -- left click
			if e[3] == 2 and e[4] == 2 and not menu_open then -- open menu
				if view == -1 or view == 1 or view == 2 then
					if view == 2 then
						save_system_settings()
					end
					view = 0
					redraw()
				elseif view == 0 then
					menu_open = true
					load_sidemenu()
					timer = os.startTimer(0)
				end
			elseif e[3] < 1 and e[4] == h - 1 and menu_open then -- changelog
				menu[0].func()
				menu_open = false
				timer = os.startTimer(0)
			elseif e[3] < 1 and e[4] > 1 and e[4] < h - 2 and menu_open then -- menu entries
				if menu[e[4] - 1 + menu_scroll] then
					menu[e[4] - 1 + menu_scroll].func()
					menu_open = false
					timer = os.startTimer(0)
				end
			elseif e[3] > 0 and menu_open then -- close menu
				menu_open = false
				timer = os.startTimer(0)
			elseif view == 0 and e[3] > 1 and e[3] < w - 1 and e[4] > 3 and e[4] <= h and list[e[4] - 4 + list_scroll] then
				if list[e[4] - 4 + list_scroll].entry then
					local category = categories[list[e[4] - 4 + list_scroll].category].entries[list[e[4] - 4 + list_scroll].entry]
					if category.value then
						if category.type == "boolean" then
							local _value = category.system_setting and sys_set or settings
							if _value[category.value] == nil then
								_value[category.value] = not category.default
							else
								_value[category.value] = not _value[category.value]
							end
							if category.system_setting then
								save_system_settings()
							else
								save_user_settings()
							end
							set_settings(user)
							draw_bottom()
						elseif category.type == "drop-down" and list[e[4] - 4 + list_scroll].entry_no then
							local _value = category.system_setting and sys_set or settings
							_value[category.value] = list[e[4] - 4 + list_scroll].entry_no
							if category.system_setting then
								save_system_settings()
							else
								save_user_settings()
							end
							set_settings(user)
							draw_bottom()
						elseif list[e[4] - 4 + list_scroll].type == "color_palette" and e[3] < 19 then
							local _value = category.system_setting and sys_set or settings
							_value[category.value] = color_palette[e[3] - 2]
							if category.system_setting then
								save_system_settings()
							else
								save_user_settings()
							end
							set_settings(user)
							draw_bottom()
						elseif category.type == "number" then
							local _value = category.system_setting and sys_set or settings
							local __ = _value[category.value]
							if __ == nil then
								__ = category.default
							end
							if e[3] == w - 6 - #(__ .. "") and __ > 0 then
								_value[category.value] = (__ - category.steps .. "") + 0
								if category.system_setting then
									save_system_settings()
								else
									save_user_settings()
								end
								set_settings(user)
								draw_bottom()
							elseif e[3] == w - 3 then
								_value[category.value] = (__ + category.steps .. "") + 0
								if category.system_setting then
									save_system_settings()
								else
									save_user_settings()
								end
								set_settings(user)
								draw_bottom()
							end
						end
					elseif (category.type == "label" or category.user) and category.changeable then
						if category.deleteable then
							category.on_save(category.default)
						elseif category.on_click then
							category.on_click(category.default)
						else
							setup_textfield(1, category)
						end
					end
				elseif list[e[4] - 4 + list_scroll].category then
					categories[list[e[4] - 4 + list_scroll].category].expanded = not categories[list[e[4] - 4 + list_scroll].category].expanded
					generate_list()
					correct_scroll()
					draw_bottom()
				end
			elseif offset == 0 and view == 1 and e[3] > w - 3 - #textfield_variables.button_text and e[3] < w and e[4] - 4 + cur_textfield.scroll > 5 * #textfield_variables.values and e[4] - 4 + cur_textfield.scroll <= 5 * #textfield_variables.values + 3 then
				local continue = true
				for _ = 1, #textfield_variables.values do
					if #textfield_variables.values == 0 then
						continue = false
						break
					end
				end
				if continue then
					local t_var = textfield_variables
					t_var.cursor[t_var.selected] = cur_textfield.cursor
					t_var.offset[t_var.selected] = cur_textfield.offset
					t_var.values[t_var.selected] = cur_textfield.value
					t_var.org_y[t_var.selected] = cur_textfield.org_y
					t_var.button_on_click()
				end
			elseif offset == 0 and view == 1 then
				for i = 1, #textfield_variables["org_y"] do
					if e[4] >= textfield_variables["org_y"][i] - cur_textfield.scroll - 1 and e[4] <= textfield_variables["org_y"][i] - cur_textfield.scroll + 1 then
						local t_var = textfield_variables
						t_var.cursor[t_var.selected] = cur_textfield.cursor
						t_var.offset[t_var.selected] = cur_textfield.offset
						t_var.values[t_var.selected] = cur_textfield.value
						t_var.org_y[t_var.selected] = cur_textfield.org_y
						t_var.selected = i
						cur_textfield.cursor = t_var.cursor[i]
						cur_textfield.offset = t_var.offset[i]
						cur_textfield.value = t_var.values[i]
						cur_textfield.org_y = t_var.org_y[i]
						set_cursor(true)
						break
					end
				end
			elseif view == 2 and not menu_open and e[3] == 1 and e[4] == 4 and mon_settings.mon_cursor > 1 then
				mon_settings.mon_cursor = mon_settings.mon_cursor - 1
				draw_bottom()
			elseif view == 2 and not menu_open and e[3] == w and e[4] == 4 and (#mon_settings.mon_order - mon_settings.mon_cursor + 1) * 10 + 5 > w then
				mon_settings.mon_cursor = mon_settings.mon_cursor + 1
				draw_bottom()
			elseif view == 2 and not menu_open and e[4] > 3 and e[4] < 13 and e[3] <= (#mon_settings.mon_order - mon_settings.mon_cursor + 1) * 10 + 5 then
				mon_settings.mon_selected = math.ceil((e[3] + (mon_settings.mon_cursor - 1) * 10) * 0.1)
				setup_entries()
				draw_bottom()
			elseif view == 2 and not menu_open and e[4] > 12 and mon_settings.list_entries[e[4] - 13 + mon_settings.list_scroll] then
				local _setting = mon_settings.list_entries[e[4] - 13 + mon_settings.list_scroll]
				if _setting == "Move 1 left" then
					local tmp = mon_settings.mon_order[mon_settings.mon_selected]
					mon_settings.mon_order[mon_settings.mon_selected] = mon_settings.mon_order[mon_settings.mon_selected - 1]
					mon_settings.mon_order[mon_settings.mon_selected - 1] = tmp
					mon_settings.mon_selected = mon_settings.mon_selected - 1
					if mon_settings.mon_cursor > mon_settings.mon_selected then
						mon_settings.mon_cursor = mon_settings.mon_selected
					end
					setup_entries()
					draw_bottom()
				elseif _setting == "Move 1 right" then
					local tmp = mon_settings.mon_order[mon_settings.mon_selected]
					mon_settings.mon_order[mon_settings.mon_selected] = mon_settings.mon_order[mon_settings.mon_selected + 1]
					mon_settings.mon_order[mon_settings.mon_selected + 1] = tmp
					mon_settings.mon_selected = mon_settings.mon_selected + 1
					if (#mon_settings.mon_order - mon_settings.mon_cursor + 1) * 10 > w then
						mon_settings.mon_cursor = mon_settings.mon_cursor + math.ceil(((w-(#mon_settings.mon_order-mon_settings.cursor+1)*10)*0.1))
					end
					if mon_settings.mon_cursor > mon_settings.mon_selected then
						mon_settings.mon_cursor = mon_settings.mon_selected
					end
					setup_entries()
					draw_bottom()
				elseif _setting == "Move left" then
					for i = mon_settings.mon_selected, 2, -1 do
						mon_settings.mon_order[i] = mon_settings.mon_order[i - 1]
					end
					mon_settings.mon_order[1] = mon_settings.mon_order[mon_settings.mon_selected]
					mon_settings.mon_selected = 1
					mon_settings.mon_cursor = 1
					setup_entries()
					draw_bottom()
				elseif _setting == "Move right" then
					for i = mon_settings.mon_selected, #mon_settings.mon_order - 1 do
						mon_settings.mon_order[i] = mon_settings.mon_order[i + 1]
					end
					mon_settings.mon_order[#mon_settings.mon_order] = mon_settings.mon_order[mon_settings.mon_selected]
					mon_settings.mon_selected = #mon_settings.mon_order
					if (#mon_settings.mon_order - mon_settings.mon_cursor + 1) * 10 > w then
						mon_settings.mon_cursor = mon_settings.mon_cursor + math.ceil(((w-(#mon_settings.mon_order-mon_settings.cursor+1)*10)*0.1))
					end
					if mon_settings.mon_cursor > mon_settings.mon_selected then
						mon_settings.mon_cursor = mon_settings.mon_selected
					end
					setup_entries()
					draw_bottom()
				elseif _setting == "Delete" then
					for i = mon_settings.mon_selected, #mon_settings.mon_order - 1 do
						mon_settings.mon_order[i] = mon_settings.mon_order[i + 1]
					end
					monitor_used[mon_settings.mon_order[mon_settings.mon_selected]] = nil
					mon_settings.mon_order[#mon_settings.mon_order] = nil
					setup_entries()
					draw_bottom()
				elseif mon_settings.mon_selected > #mon_settings.mon_order then
					mon_settings.mon_order[#mon_settings.mon_order + 1] = _setting
					monitor_used[_setting] = true
					setup_entries()
					draw_bottom()
				end
			end
		end
	elseif e[1] == "mouse_scroll" and menu_open then -- menu
		e[3] = e[3] - offset
		if e[3] < 1 and (e[2] == 1 and #menu - menu_scroll > h - 4 or e[2] == -1 and menu_scroll > 0) then
			menu_scroll = menu_scroll + e[2]
			draw_menu()
		end
	elseif e[1] == "mouse_scroll" and view == -1 and offset == 0 then -- changelog
		if e[4] >= 4 and (e[2] > 0 and #changelog - changelog_scroll > h - 5 or e[2] < 0 and changelog_scroll > 0) then
			changelog_scroll = changelog_scroll + e[2]
			draw_changelog()
		end
	elseif e[1] == "mouse_scroll" and view == 0 and not menu_open and offset == 0 and (e[2] > 0 and list[h - 4 + list_scroll] ~= nil or e[2] < 0 and list_scroll > 0) then
		list_scroll = list_scroll + e[2]
		draw_bottom()
	elseif e[1] == "mouse_scroll" and view == 1 and offset == 0 and (e[2] > 0 and 5 * #textfield_variables.values + 3 - cur_textfield.scroll > h - 5 or e[2] < 0 and cur_textfield.scroll > 0) then
		cur_textfield.scroll = cur_textfield.scroll + e[2]
		draw_bottom()
	elseif e[1] == "mouse_scroll" and view == 2 and not menu_open then
		if e[4] > 3 and e[4] < 13 then
			if e[2] < 0 and mon_settings.mon_cursor > 1 or e[2] > 0 and (#mon_settings.mon_order - mon_settings.mon_cursor + 1) * 10 + 5 > w then
				mon_settings.mon_cursor = mon_settings.mon_cursor + e[2]
				draw_bottom()
			end
		elseif e[4] > 12 and (e[2] < 0 and mon_settings.list_scroll > 0 or e[2] > 0 and mon_settings.list_entries[h - 13 + mon_settings.list_scroll]) then
			mon_settings.list_scroll = mon_settings.list_scroll + e[2]
			draw_bottom()
		end
	elseif e[1] == "term_resize" then
		w, h = term.getSize()
		draw_menu()
		draw_top()
		correct_scroll()
		if not term.isColor or not term.isColor() then
			scroll_to_cursor()
		end
		if view == -1 then
			draw_changelog()
		elseif view == 0 or view == 1 then
			if view == 1 and cur_textfield then
				cur_textfield.width = w - 4
				scroll_field_cursor("up")
				scroll_field_cursor("down")
			end
			draw_bottom()
		elseif view == 2 then
			setup_entries()
			draw_bottom()
		end
	elseif e[1] == "timer" and e[2] == timer then
		if menu_open and offset < menu_width or not menu_open and offset > 0 then
			offset = offset + (menu_open and 1 or -1)
			redraw()
			timer = os.startTimer(0)
		end
	elseif e[1] == "peripheral_detach" then
		if view == 2 then
			if monitor_used[e[2]] then
				monitor_used[e[2]] = nil
				for i = 1, #mon_settings.mon_order do
					if mon_settings.mon_order[i] == e[2] then
						for j = i, #mon_settings.mon_order - 1 do
							mon_settings.mon_order[j] = mon_settings.mon_order[j + 1]
						end
						mon_settings.mon_order[#mon_settings.mon_order] = nil
						break
					end
				end
			end
			setup_entries()
			draw_bottom()
		end
		save_system_settings()
	elseif e[1] == "refresh_settings" then
		settings = user_data().settings or {}
		load_key_mapping()
		draw_bottom()
	elseif e[1] == "monitor_resize" and view == 2 and mon_settings.mon_selected > #mon_settings.mon_order then
		setup_entries()
		draw_bottom()
	end
end
while true do
	events(coroutine.yield())
end
