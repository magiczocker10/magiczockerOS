-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local hex, get_color = {}, {}
local _tconcat = table.concat
local apis, textutils = apis, textutils
for i = 1, 16 do
	local tmp = 2 ^ (i - 1)
	hex[tmp] = ("0123456789abcdef"):sub(i, i)
	get_color[hex[tmp]] = tmp
end
local fallback_pixel = {b = 32768, t = 1, s = " "}
local native_conv = {} -- for term.nativePaletteColor
for i = 0, 15 do
	native_conv[2 ^ i] = i + 1
end
local last_palette, color_palette = {mode = 0, inverted = false, original = false}, {
	new = {
		{240, 240, 240}, -- white
		{242, 178, 51}, -- orange
		{229, 127, 216}, -- magenta
		{153, 178, 242}, -- lightBlue
		{222, 222, 108}, -- yellow
		{127, 204, 25}, -- lime
		{242, 178, 204}, -- pink
		{76, 76, 76}, -- gray
		{153, 153, 153}, -- lightGray
		{76, 153, 178}, -- cyan
		{178, 102, 229}, -- purple
		{51, 102, 204}, -- blue
		{127, 102, 76}, -- brown
		{87, 166, 78}, -- green
		{204, 76, 76}, -- red
		{17, 17, 17}, -- black
	},
	original = {
		{240, 240, 240}, -- white
		{235, 136, 68}, -- orange
		{195, 84, 205}, -- magenta
		{102, 137, 211}, -- lightBlue
		{222, 222, 108}, -- yellow
		{65, 205, 52}, -- lime
		{216, 129, 152}, -- pink
		{67, 67, 67}, -- gray
		{153, 153, 153}, -- lightGray
		{40, 118, 151}, -- cyan
		{123, 47, 190}, -- purple
		{37, 49, 146}, -- blue
		{81, 48, 26}, -- brown
		{59, 81, 26}, -- green
		{179, 49, 44}, -- red
		{0, 0, 0}, -- black
	},
}
local cp = {
	{0, 0, 0, 0, 0, 0, 0, 0, 0}, -- normal
	{.618, .320, .062, .163, .775, .062, .163, .320, .516}, -- achromatomaly *
	{.299, .587, .114, .299, .587, .114, .299, .587, .114}, -- achromatopsia / gray | https://de.wikipedia.org/wiki/YUV-Farbmodell
	{.8, .2, 0, .258, .742, 0, 0, .142, .858}, -- deuteranomaly *
	{.625, .375, 0, .7, .3, 0, 0, .3, .7}, -- deuteranopia *
	{.817, .183, 0, .333, .667, 0, 0, .125, .875}, -- protanomaly *
	{.567, .433, 0, .558, .442, 0, 0, .242, .758}, -- protanopia *
	{.393, .769, .189, .349, .686, .168, .272, .534, .131}, -- sepia
	{.967, .033, 0, 0, .733, .267, 0, .183, .817}, -- tritanomaly *
	{.95, .05, 0, 0, .433, .567, 0, .475, .525}, -- tritanopia *
} -- * https://www.reddit.com/r/gamedev/comments/2i9edg/code_to_create_filters_for_colorblind/
local function round(a)
	return a % 1 >= 0.5 and math.ceil(a) or math.floor(a)
end
local function expect(a, b, c, ...)
	local d, e = {...}, type(b)
	for i = 1, #d do
		if e == d[i] then
			return true
		end
	end
	return error(a .. ": Invalid arg #" .. c .. " (" .. (#d > 1 and _tconcat(d, ", ", 1, #d - 1) .. " or " or "") .. d[#d] .. " expected)")
end
function reload_color_palette(settings)
	if apis.buffer.is_colored() and apis.buffer.has_palette() then
		if cp[settings.color_mode] and ((settings.color_mode or 1) ~= last_palette.mode or (settings.invert_colors or false) ~= last_palette.inverted or (settings.original_colors or false) ~= last_palette.original) then
			last_palette = {mode = settings.color_mode or 1, inverted = settings.invert_colors, original = settings.original_colors}
			local a = settings.original_colors and "original" or "new"
			for i = 1, 16 do
				local temp_color, b, c = {
					color_palette[a][i][1],
					color_palette[a][i][2],
					color_palette[a][i][3],
				}, cp[settings.color_mode], settings.color_mode and settings.color_mode > 1
				local red, green, blue = round(temp_color[1] * b[1] + temp_color[2] * b[2] + temp_color[3] * b[3]), round(temp_color[1] * b[4] + temp_color[2] * b[5] + temp_color[3] * b[6]), round(temp_color[1] * b[7] + temp_color[2] * b[8] + temp_color[3] * b[9])
				temp_color = {
					c and (red > 255 and 255 or red) or temp_color[1],
					c and (green > 255 and 255 or green) or temp_color[2],
					c and (blue > 255 and 255 or blue) or temp_color[3],
				}
				c = settings.invert_colors
				temp_color = {
					c and 255 - temp_color[1] or temp_color[1],
					c and 255 - temp_color[2] or temp_color[2],
					c and 255 - temp_color[3] or temp_color[3],
				}
				for j = 1, apis.buffer.get_mode() == "extend" and #apis.buffer.get_devices() or 1 do
					apis.buffer.send_term(j, "setPaletteColor", 2 ^ (i - 1), 1 / 255 * temp_color[1], 1 / 255 * temp_color[2], 1 / 255 * temp_color[3])
				end
			end
		end
	end
end
function create(x, y, width, height, visible, header, data)
	local header_tmp
	local data = data
	local header = header
	local last_header_first
	local last_header_width
	local maximized = false
	local my_border = false
	local my_blink = true
	local cur_blink = false
	local my_data = {32768, 1, 1, 1} -- back, text, cursor x, cursor y
	local my_pos = {x or 1, y or 1}
	local my_screen = {}
	local my_size = {width, height}
	local my_visible = type(visible) ~= "boolean" or visible
	local window = {}
	local last_header
	local last_cur_id = 0
	if header then
		my_pos[2] = my_pos[2] + 1
	end
	local function gs(a)
		return data.get_setting(data.user_data().settings, a)
	end
	local function get_size()
		local w, h
		if maximized then
			w, h = apis.buffer.get_size()
		end
		return maximized and w or my_size[1], maximized and h - 1 or my_size[2]
	end
	local function get_pos(with_header)
		return maximized and 1 or my_pos[1], (maximized and 3 or my_pos[2]) - (with_header and header and 1 or 0)
	end
	local function write_to_global_buffer(cur_id, line, pos_start, pos_end)
		local w, h = get_size()
		if my_visible and line > (header and -1 or 0) and line <= h then
			pos_start = pos_start and pos_end and (pos_start < 1 and 1 or pos_start) or nil
			pos_end = pos_start and pos_end and (pos_end > w and w or pos_end) or nil
			local ceiled_w, ceiled_h = my_border and math.ceil(w * 0.5), my_border and math.ceil(h * 0.5)
			local x, y = get_pos()
			local _ypos = y + line - 1
			my_screen[line] = my_screen[line] or {}
			for i = pos_start or 1, pos_end or w do
				local _xpos = x + i - 1
				local is_border = my_border and line > 0 and (line == h or (i == 1 or i == w))
				apis.buffer.write(_xpos, _ypos, {
					t = is_border and gs("window_resize_border_text") or my_screen[line][i] and my_screen[line][i].t or 1,
					b = is_border and gs("window_resize_border_back") or my_screen[line][i] and my_screen[line][i].b or 32768,
					s = is_border and (line == ceiled_h and "|" or i == ceiled_w and "-" or " ") or my_screen[line][i] and my_screen[line][i].s or " ",
					id = last_cur_id,
				})
			end
		end
	end
	local function redraw(cur_id)
		local w, h = get_size()
		for i = header and 0 or 1, my_visible and h or 0 do
			write_to_global_buffer(cur_id, i, 1, w)
		end
	end
	local function create_header()
		if not header then return end
		local w = get_size()
		local colored = apis.buffer.is_colored()
		local foreground = data.id < 0 or data.is_top()
		if last_header and foreground == last_header_first and last_header_width == w then
			my_screen[0] = last_header
			return
		end
		last_header_first, last_header_width = foreground, w
		local b = {"", "", "", "", "", "", "", "", ""}
		local my_buttons = data.buttons
		if colored then
			for i = 1, last_cur_id > 0 and #my_buttons or 1 do
				local a = my_buttons[i]
				b[1], b[2], b[3] = b[1] .. (foreground and hex[gs("window_" .. a[1] .. "_button_active_back") or a[2]] or hex[gs("window_" .. a[1] .. "_button_inactive_back") or a[3]]), b[2] .. "o", b[3] .. (foreground and hex[gs("window_" .. a[1] .. "_button_active_text") or a[4]] or hex[gs("window_" .. a[1] .. "_button_inactive_text") or a[5]])
			end
		end
		b[4] = ((colored and " " or "=") .. data.label.name .. (colored and " " or "="):rep(last_header_width)):sub(1, colored and last_header_width - (last_cur_id > 0 and #my_buttons or 0) - 1 or last_header_width)
		local __ = foreground
		if colored then
			b[5], b[6] = hex[gs("window_bar_" .. (__ and "" or "in") .. "active_back")], hex[gs("window_bar_" .. (__ and "" or "in") .. "active_text")]
		elseif textutils and textutils.complete then
			b[5], b[6] = "7",  __ and "0" or "8"
		else
			b[5], b[6] = __ and "0" or "f", __ and "f" or "0"
		end
		b[7], b[8], b[9] = colored and hex[gs("window_resize_button_back")] or b[7], colored and (foreground and not maximized and last_cur_id > 0 and "o" or " ") or b[8], colored and hex[gs("window_resize_button_text")] or b[9]
		header_tmp = {
			_tconcat({b[1], 
			b[5]:rep(#b[4]), 
			b[7]}),
			_tconcat({b[2], b[4], b[8]}),
			_tconcat({b[3], b[6]:rep(#b[4]), b[9]}),
		}
		my_screen[0] = {}
		for i = 1, last_header_width do
			local t = my_screen[0]
			t[i] = {
				b = get_color[header_tmp[1]:sub(i, i) or "0"],
				s = header_tmp[2]:sub(i, i),
				t = get_color[header_tmp[3]:sub(i, i) or "f"],
			}
		end
		last_header = my_screen[0]
	end
	local function set_cursor()
		if not apis.buffer.is_visible() then return nil end
		local w, h = get_size()
		local x, y = get_pos()
		local _x, _y = x - 1 + my_data[3], y - 1 + my_data[4]
		local success = (data.id < 0 or data.is_top()) and (not my_border or my_border and my_data[3] > 1 and my_data[3] < w and my_data[4] > 0 and my_data[4] < h)
		local only_off = my_data[3] < 1 or my_data[3] > w or my_data[4] < 1 or my_data[4] > h or false
		if success and (not only_off or not my_blink) then
			local tmpy = my_data[4]
			local mon_order = apis.buffer.get_devices()
			local screen = my_screen[tmpy]
			for i = apis.buffer.get_mode() == "extend" and #mon_order or 1, 1, -1 do
				if _x > mon_order[i].offset then
					if apis.buffer.has_cursor_blink() then
						if cur_blink and data.is_top() then
							apis.buffer.send_term(i, "setTextColor", my_data[2])
							apis.buffer.send_term(i, "setCursorPos", _x - mon_order[i].offset, _y)
						end
						apis.buffer.send_term(i, "setCursorBlink", cur_blink)
					elseif screen[my_data[3]] then
						if my_blink and cur_blink then
							apis.buffer.send_term(i, "setBackgroundColor", screen[my_data[3]].b)
							apis.buffer.send_term(i, "setTextColor", my_data[2])
							apis.buffer.send_term(i, "setCursorPos", _x - mon_order[i].offset, _y)
							apis.buffer.send_term(i, "write", "#")
						elseif not cur_blink then
							apis.buffer.send_term(i, "setBackgroundColor", screen[my_data[3]].b)
							apis.buffer.send_term(i, "setTextColor", screen[my_data[3]].t)
							apis.buffer.send_term(i, "setCursorPos", _x - mon_order[i].offset, _y)
							apis.buffer.send_term(i, "write", screen[my_data[3]].s)
						end
					end
					break
				end
			end
		end
	end
	local function _blit(sText, sTextColor, sBackgroundColor)
		local text_len = #sText
		local w, h = get_size()
		if my_data[4] < 1 or my_data[4] > h then my_data[3] = my_data[3] + text_len return end
		local cur = my_data[3] - 1
		local _y = my_data[4]
		my_screen[_y] = my_screen[_y] or {}
		for i = math.max(1, #my_screen[_y]), math.min(w, cur) do
			my_screen[_y][i] = my_screen[_y][i] or {b = fallback_pixel.b, s = fallback_pixel.s, t = fallback_pixel.t}
		end
		local a = 1
		for i = math.max(1, cur + 1), math.min(w, my_data[3] + text_len - 1) do
			my_screen[_y][i] = {s = sText:sub(a, a), t = get_color[sTextColor:sub(a, a)], b = get_color[sBackgroundColor:sub(a, a)]}
			a = a + 1
		end
		local x, y = get_pos()
		local buffer_x = x - 1 + cur
		local buffer_y = y - 1 + _y
		write_to_global_buffer(nil, _y, cur, cur + text_len)
		apis.buffer.redraw_global_cache_line(true, buffer_y, buffer_x, buffer_x + text_len)
		my_data[3] = my_data[3] + text_len
		set_cursor()
	end
	window.blit = function(a, b, c) -- text, textcolor, backgroundcolor
		expect("blit", a, 1, "string")
		expect("blit", b, 2, "string")
		expect("blit", c, 3, "string")
		if #a == #b and #b == #c then
			_blit(a, b, c)
		end
	end
	window.clear = function()
		for i = 1, ({get_size()})[2] do
			my_screen[i] = {}
		end
		set_cursor()
	end
	window.clearLine = function()
		local w, h = get_size()
		if my_data[4] > 0 and my_data[4] <= h then
			my_screen[my_data[4]] = {}
			write_to_global_buffer(nil, my_data[4], 1, w)
			local x, y = get_pos()
			apis.buffer.redraw_global_cache_line(false, y - 1 + my_data[4], x, x - 1 + w)
			set_cursor()
		end
	end
	window.current = function()
		return window
	end
	window.force_header_update = function()
		last_header = nil
		if header then
			create_header()
			write_to_global_buffer(nil, 0, 1, ({get_size()})[1])
			set_cursor()
		end
	end
	window.getBackgroundColor = function()
		return my_data[1]
	end
	window.getCursorBlink = function()
		return cur_blink
	end
	window.getCursorPos = function()
		return my_data[3], my_data[4]
	end
	window.get_data = function()
		local x, y = get_pos(true)
		local w, h = get_size()
		return x, y, w, h + (header and 1 or 0)
	end
	window.getPosition = function()
		return my_pos[1], my_pos[2]
	end
	window.getSize = function()
		return get_size()
	end
	window.getTextColor = function()
		return my_data[2]
	end
	window.get_visible = function()
		return my_visible
	end
	window.has_header = function()
		return header
	end
	window.isColor = function()
		return apis.buffer.is_colored()
	end
	window.is_maximized = function()
		return maximized
	end
	window.native = window.current
	window.nativePaletteColor = function(num)
		local tmp = color_palette[gs("original_colors") and "original" or "new"]
		local n = tmp[native_conv[num] or -1]
		if n then
			return n[1], n[2], n[3]
		end
		return 0, 0, 0
	end
	window.redraw = function(id)
		if id and last_cur_id ~= id then
			last_header = nil
		end
		last_cur_id = id or last_cur_id
		if header then
			create_header()
		end
		redraw(last_cur_id)
	end
	window.reposition = function(a, b, c, d)
		expect("reposition", a, 1, "number", "nil")
		expect("reposition", b, 2, "number", "nil")
		expect("reposition", c, 3, "number", "nil")
		expect("reposition", d, 4, "number", "nil")
		my_pos[1], my_pos[2] = a or my_pos[1], b + (header and 1 or 0) or my_pos[2]
		my_size[1], my_size[2] = c or my_size[1], d - (header and 1 or 0) or my_size[2]
		for i = #my_screen + 1, my_size[2] do
			my_screen[i] = my_screen[i] or {}
		end
	end
	window.restore_cursor = function()
		set_cursor()
	end
	window.scroll = function(a)
		expect("scroll", a, 1, "number")
		local _, h = get_size()
		if a < 0 then
			for _ = a, -1, -1 do
				my_screen[h] = nil
				table.insert(my_screen, 1, {})
			end
		elseif a > 0 then
			for _ = 1, a do
				table.remove(my_screen, 1)
				my_screen[h] = {}
			end
		end
		redraw()
		apis.buffer.redraw_global_cache(true)
	end
	window.set_header_vis = function(a)
		if header == a then return end
		header = a
		my_pos[2] = my_pos[2] + (a and 1 or -1)
		--my_size[2] = my_size[2] + (a and -1 or 1)
		local w, h = get_size()
		for i = 1, h do
			write_to_global_buffer(nil, i, 1, w)
		end
		apis.buffer.redraw_global_cache(true)
		set_cursor()
	end
	window.setBackgroundColor = function(a)
		expect("setBackgroundColor", a, 1, "number")
		if hex[a] then
			my_data[1] = a
		end
	end
	window.setCursorBlink = function(a)
		expect("setCursorBlink", a, 1, "boolean")
		my_blink, cur_blink = true, a
		set_cursor()
	end
	window.setCursorPos = function(a, b)
		expect("setCursorPos", a, 1, "number")
		expect("setCursorPos", b, 2, "number")
		local mb = my_blink
		if not apis.buffer.has_cursor_blink() then
			my_blink = false
			set_cursor()
		end
		my_data[3], my_data[4], my_blink = math.floor(a), math.floor(b), mb
	end
	window.set_maximized = function(a)
		expect("setMaximized", a, 1, "boolean")
		maximized = a
		create_header(true)
		window.redraw()
		apis.buffer.redraw_global_cache(true)
	end
	if apis.buffer.has_palette() then
		window.getPaletteColor = function(a)
			expect("getPaletteColor", a, 1, "number")
			if color_codes[a] == nil then
				error("Invalid color (got " .. a .. ")", 2)
			end
			return color_codes[a][1], color_codes[a][2], color_codes[a][3]
		end
	end
	window.setTextColor = function(a)
		expect("setTextColor", a, 1, "number")
		if hex[a] then
			my_data[2] = a
		end
	end
	window.set_visible = function(a)
		my_visible = a
	end
	window.setVisible = function(a)
		expect("setVisible", a, 1, "boolean")
		my_visible = a
	end
	window.toggle_border = function(a)
		if my_border ~= a then
			my_border = a
			local w, h = get_size()
			for i = 1, h - 1 do
				write_to_global_buffer(nil, i, 1, 1)
				write_to_global_buffer(nil, i, w, w)
			end
			write_to_global_buffer(nil, h, 1, w)
			apis.buffer.redraw_global_cache(true)
			set_cursor()
		end
	end
	window.toggle_cursor_blink = function()
		if cur_blink or my_blink then
			my_blink = not my_blink
			set_cursor()
		end
	end
	window.write = function(a)
		expect("write", a, 1, "string", "number")
		a = a .. ""
		_blit(a, hex[my_data[2]]:rep(#a), hex[my_data[1]]:rep(#a))
	end
	-- Add British spelling
	window.getBackgroundColour = window.getBackgroundColor
	window.getPaletteColour = window.getPaletteColor
	window.getTextColour = window.getTextColor
	window.isColour = window.isColor
	window.setBackgroundColour = window.setBackgroundColor
	window.setTextColour = window.setTextColor
	window.clear()
	return window
end