-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local monitor_order = term and {{name = "computer", offset = 0}} or {}
local term = term or {isColor = function() return true end}
local w, h = term.getSize and term.getSize() or 51, 19
local total_size = {0, 0}
local monitor_mode = "normal"
local peri = apis.peripheral.create(true)
local _computer_only = component and {} or {"computer"}
local validate_modes = {
	["normal"] = true,
	["extend"] = true,
	["duplicate"] = true,
}
local process_data = {
	to_draw = {},
	last = nil,
	last_cursor = nil,
	last_screen = nil,
}
local global_cache
local global_cache_old
local global_visible = true
local com_term = term
local peri_call = nil
local peri_type = nil
local _tconcat = table.concat
local header_tmp = {"", "", ""}
-- both variables for get_nearest_scale
local _size = {0, 0}
local pixel_size = {6, 9}
local cdo_args = {0, 0}
local get_color = {}
local hex = {}
for i = 1, 16 do
	local tmp = 2 ^ (i - 1)
	hex[tmp] = ("0123456789abcdef"):sub(i, i)
	get_color[hex[tmp]] = tmp
end
local colored = com_term and com_term.isColor and com_term.isColor()
local last_palette = {mode = 1, inverted = false, original = false}
local color_palette = {
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
local function expect(a, b, c) -- number, to_check, expected
	local d = type(b)
	if d ~= c then
		return error("bad argument #" .. a .. " (expected " .. c .. ", got " .. d .. ")", 2)
	end
end
local function copy_table(a, b)
	local b, c = b or {}, {}
	b[a] = true
	for k, v in next, a do
		local d = type(v)
		if d == "table" and not b[a] then
			c[k] = copy_table(v, b)
		elseif d ~= "table" then
			c[k] = v
		end
	end
	return c
end
function set_peripheral(object)
	peri_call = object and object.call or nil
	peri_type = object and object.getType or nil
	if not peri_call then
		error("Method \"call\" is missing.")
	elseif not peri_type then
		error("Method \"type\" is missing.")
	end
end
function set_global_visible(status)
	if type(status) == "boolean" then
		global_visible = status
	end
end
function get_global_visible()
	return global_visible
end
function clear_cache()
	global_cache = {t = {}, b = {}, s = {}}
	global_cache_old = {t = {}, b = {}, s = {}}
end
local function set_term(device, mode, ...)
	for i = monitor_mode == "duplicate" and 1 or device or 1, monitor_mode == "duplicate" and #monitor_order or device or 1 do
		peri_call(monitor_order[i].name, mode, ...)
	end
end
local function get_nearest_scale(mode, device, length)
	local _mode = mode == "width" and 1 or 2
	peri_call(device, "setTextScale", 0.5)
	_size[1], _size[2] = peri_call(device, "getSize")
	local a = pixel_size[_mode] / (_size[_mode] or 1) * 2
	for i = 5, 0.5, -.5 do
		if length <= pixel_size[_mode] / (a * i) then
			return i
		end
	end
	return 0.5
end
local function calculate_device_offset()
	local cur_offset, total_width, mon_len = 0, 0, #monitor_order
	w, h = nil, nil
	for i = 1, mon_len do
		peri_call(monitor_order[i].name, "setTextScale", 0.5)
		_size[1], _size[2] = peri_call(monitor_order[i].name, "getSize")
		w = (not w or w > _size[1]) and _size[1] or w
		h = (not h or h > _size[2]) and _size[2] or h
	end
	for i = 1, mon_len do
		local mo = monitor_order[i]
		if mo.name ~= "computer" then
			local _w, _h = get_nearest_scale("width", mo.name, w), get_nearest_scale("height", mo.name, h)
			peri_call(mo.name, "setTextScale", 5) -- Force the event "monitor_resize" to fire
			local a = _w > _h and _h or _w
			cdo_args[1], cdo_args[2] = a - 0.5, a + 0.5
			cdo_args[1], cdo_args[2] = cdo_args[1] < 0.5 and 0.5 or cdo_args[1], cdo_args[2] > 5 and 5 or cdo_args[2]
			for j = cdo_args[2], cdo_args[1], -0.5 do
				peri_call(mo.name, "setTextScale", j)
				local tmp = {peri_call(mo.name, "getSize")}
				if tmp[1] >= w and tmp[2] >= h then
					break
				end
			end
		end
		_size = {peri_call(mo.name, "getSize")}
		mo.height = _size[2]
		mo.startx = cur_offset + 1
		mo.endx = cur_offset + _size[1]
		mo.offset = cur_offset
		cur_offset = monitor_mode == "extend" and cur_offset + _size[1] or 0
		total_width = total_width + _size[1]
		if monitor_mode ~= "extend" and i == 1 then
			w = _size[1]
			h = _size[2]
			total_size[1] = w
			total_size[2] = h
		end
		h = monitor_mode == "extend" and h > _size[2] and _size[2] or h
	end
	if monitor_mode == "extend" then
		w = total_width
		total_size[1], total_size[2] = total_width, h
	end
	if not w or not h or #monitor_order == 0 then
		error"Empty variable"
	end
end
function get_devices()
	return monitor_order
end
function get_size()
	return total_size[1], total_size[2]
end
function set_devices(mode, ...)
	monitor_mode = validate_modes[mode] and mode or "normal"
	local list = monitor_mode == "normal" and _computer_only or {...}
	local to_clear = {}
	for i = 1, type(monitor_order) == "table" and #monitor_order or 0 do
		to_clear[monitor_order[i].name] = true
	end
	monitor_order = {}
	local processed = {}
	local pd = process_data
	pd.last_backcolor = pd.last_backcolor or {}
	pd.last_textcolor = pd.last_textcolor or {}
	for i = 1, #list do
		if not processed[list[i]] and peri_type(list[i]) == "monitor" then
			pd.last_backcolor[list[i]] = -1
			pd.last_textcolor[list[i]] = -1
			peri_call(list[i], "setBackgroundColor", 32768)
			peri_call(list[i], "clear")
			to_clear[list[i]] = nil
			monitor_order[#monitor_order + 1] = {name = list[i]}
		end
		processed[list[i]] = true
	end
	for k in next, to_clear do
		if peri_call then
			peri_call(k, "setBackgroundColor", 32768)
			peri_call(k, "clear")
		end
	end
	monitor_order[#monitor_order + 1] = #monitor_order == 0 and {name = component and peri.find("monitor") or "computer"} or nil
	calculate_device_offset()
	clear_cache()
end
local function can_added(data, content, text, back, x)
	if #data[2] == 0 or data[1] == x - #data[2] and back == data[3] and (content == " " or data[4] == -1 or text == data[4]) then
		if #data[2] == 0 then
			data[1] = x
			data[3] = back
			data[4] = -1
		end
		data[4] = data[4] == -1 and content ~= " " and text or data[4]
		data[2][#data[2] + 1] = content
		return true
	end
	return false
end
function draw_text(screen, data, new, line, rdata)
	if #new[2] == 0 then return nil end
	if rdata then
		rdata[#rdata + 1] = {copy_table(data), copy_table(new), line}
	end
	if data[1] < 1 or data[1] ~= new[1] then
		set_term(screen, "setCursorPos", new[1] - monitor_order[screen].startx + 1, line)
		data[1] = new[1] + #new[2]
	end
	if data[2] ~= new[3] then
		data[2] = new[3]
		set_term(screen, "setBackgroundColor", new[3])
	end
	if new[4] > 0 and data[3] ~= new[4] then
		data[3] = new[4]
		set_term(screen, "setTextColor", new[4])
	end
	set_term(screen, "write", _tconcat(new[2]))
end
function redraw_global_cache_line(check_changes, line, startx, endx, return_data)
	if not global_visible or not line or line > h or not global_cache.s[line] then return nil end
	local monitor_mode_ = monitor_mode
	monitor_mode = return_data and "extend" or monitor_mode
	local startxorg = startx
	local endxorg = endx
	local to_repeat = {}
	local goto_limit = return_data and 1 or #monitor_order
	local s, startx, endx, limit_set, continue, to_draw, cur_data, _slineold, _tlineold, _blineold, _sline, _tline, _bline
	for screen = 1, goto_limit do
		s = monitor_order[screen]
		startx = startxorg or s.startx
		startx = startx < s.startx and s.startx or startx
		endx = endxorg or s.endx
		endx = endx > s.endx and s.endx or endx
		limit_set = return_data or startxorg and endxorg
		continue = endx >= startx and startx <= s.endx and s.startx <= endx
		to_draw = {-1, {}, -1, -1} -- x, text, bcol, tcol
		cur_data = {0, -1, -1} -- x, backc, textc
		_sline = global_cache.s[line]
		_bline = global_cache.b[line]
		_tline = global_cache.t[line]
		global_cache_old.s[line] = global_cache_old.s[line] or {}
		global_cache_old.b[line] = global_cache_old.b[line] or {}
		global_cache_old.t[line] = global_cache_old.t[line] or {}
		_slineold = global_cache_old.s[line]
		_blineold = global_cache_old.b[line]
		_tlineold = global_cache_old.t[line]
		startx, endx = not continue and 1 or startx, not continue and 0 or endx
		local tmp
		for i = startx, endx do
			local s, b, t, _s, _b, _t = _sline[i], _bline[i], _tline[i], _slineold[i], _blineold[i], _tlineold[i]
			if s and (not check_changes or not global_cache_old.s[line] or not global_cache_old.s[line][i] or (b ~= _b or t ~= _t or s ~= _s) and not (b == _b and s == " " and _s == " ")) then
				if not can_added(to_draw, s, t, b, i) then
					draw_text(screen, cur_data, to_draw, line, return_data and to_repeat)
					to_draw[2] = {}
					to_draw[4] = -1
					can_added(to_draw, s, t, b, i)
				end
				tmp = global_cache_old.b[line]
				tmp[i] = to_draw[3]
				tmp = global_cache_old.t[line]
				tmp[i] = to_draw[4] < 1 and t or to_draw[4]
				tmp = global_cache_old.s[line]
				tmp[i] = s
				_sline[i] = not (limit_set and screen == goto_limit) and s or nil
			end
		end
		draw_text(screen, cur_data, to_draw, line, return_data and to_repeat)
	end
	local empty = not limit_set or not next(global_cache.s[line])
	global_cache.s[line], monitor_mode = not empty and global_cache.s[line] or nil, monitor_mode_
	return to_repeat
end
function redraw_global_cache(check_changes)
	local rd = {}
	for i = 1, h do
		rd[#rd + 1] = redraw_global_cache_line(check_changes, i, nil, nil, monitor_mode == "duplicate" and #monitor_order > 1)
	end
	local monitor_mode_, tmp = monitor_mode, nil
	for i = 2, monitor_mode_ == "duplicate" and #monitor_order or 1 do
		for j = 1, #rd do
			tmp = rd[j]
			for k = 1, #tmp do
				draw_text(i, copy_table(tmp[k][1]), copy_table(tmp[k][2]), tmp[k][3])
			end
		end
	end
end
function get_global_cache(b, c) -- Returns the screen / the specified window in the nft-format.
	local d, e, f = {}, {(" "):rep(total_size[1])}, {b = 32768}
	local old_col, g, h
	for i = c and 2 or 1, c or total_size[2] do
		old_col = {nil, nil} -- back, text
		d[#d + 1] = {}
		g, h = global_cache_old[i] or f, d[#d]
		d[#d] = g and d[#d] or e
		for j = 1, b or total_size[1] do
			if g[j] then
				if (g[j].b or g[j].back) ~= old_col[1] then
					h[#h + 1] = ("30"):char()
					old_col[1] = g[j].b or g[j].back
					h[#h + 1] = old_col[1]
				end
				if (g[j].t or g[j].text or old_col[2]) ~= old_col[2] then
					h[#h + 1] = ("31"):char()
					old_col[2] = g[j].t or g[j].text
					h[#h + 1] = old_col[2]
				end
			end
			h[#h + 1] = g[j] and (g[j].s or g[j].char) or " "
		end
		d[#d] = h and _tconcat(h) or d[#d]
	end
	return _tconcat(d, "\n")
end
local native_conv = {} -- for term.nativePaletteColor
for i = 0, 15 do
	native_conv[2 ^ i] = i + 1
end
local cp = {
	nil,
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
function reload_color_palette(settings)
	if colored and term.setPaletteColor then
		if cp[settings.color_mode] and (settings.color_mode or 1) ~= last_palette.mode or (settings.invert_colors or false) ~= last_palette.inverted or (settings.original_colors or false) ~= last_palette.original then
			last_palette = {mode = settings.color_mode or 1, inverted = settings.invert_colors, original = settings.original_colors}
			local a = settings.original_colors and "original" or "new"
			for i = 1, 16 do
				local temp_color = {color_palette[a][i][1], color_palette[a][i][2], color_palette[a][i][3]}
				local b = cp[settings.color_mode]
				local red = round(temp_color[1] * b[1] + temp_color[2] * b[2] + temp_color[3] * b[3])
				local green = round(temp_color[1] * b[4] + temp_color[2] * b[5] + temp_color[3] * b[6])
				local blue = round(temp_color[1] * b[7] + temp_color[2] * b[8] + temp_color[3] * b[9])
				local c = settings.color_mode and settings.color_mode > 1
				temp_color[1] = c and (red > 255 and 255 or red) or temp_color[1]
				temp_color[2] = c and (green > 255 and 255 or green) or temp_color[2]
				temp_color[3] = c and (blue > 255 and 255 or blue) or temp_color[3]
				c = settings.invert_colors
				temp_color[1] = c and 255 - temp_color[1] or temp_color[1]
				temp_color[2] = c and 255 - temp_color[2] or temp_color[2]
				temp_color[3] = c and 255 - temp_color[3] or temp_color[3]
				for j = 1, monitor_mode == "extend" and #monitor_order or 1 do
					set_term(j, "setPaletteColor", 2 ^ (i - 1), 1 / 255 * temp_color[1], 1 / 255 * temp_color[2], 1 / 255 * temp_color[3])
				end
			end
		end
	end
end
function create(x, y, width, height, visible, bar)
	expect(1, x, "number")
	expect(2, y, "number")
	expect(3, width, "number")
	expect(4, height, "number")
	if visible ~= nil then expect(5, visible, "boolean") else visible = true end
	-- variables
	local back_color, blink, can_draw, id, state, text_color, border, title = 32768, false, true, 0, "normal", 1, false, ""
	-- tables
	local color_codes = {}
	for k, v in next, color_palette.new do
		color_codes[2 ^ (k - 1)] = {v[1], v[2], v[3]}
	end
	local cursor = {1, 1}
	local data = {
		maximized = {
			height = total_size[2] - 1,
			width = total_size[1],
			x = 1,
			y = 2,
		},
		normal = {
			height = height,
			width = width,
			x = x,
			y = y,
		},
	}
	local screen_s = {}
	local screen_b = {}
	local screen_t = {}
	local screen2 = {}
	local settings = {}
	local window = {}
	local redraw_line
	local my_blink = true
	local my_buttons = {{"close", 128, 128, 2048, 256}, {"minimize", 128, 128, 512, 256}, {"maximize", 128, 128, 8, 256}}
	local last_header_first
	local last_header_width
	local last_header_b
	local last_header_s
	local last_header_t
	-- functions
	local function set_cursor()
		if not global_visible then return nil end
		local success = false
		local _data = data[state]
		local _x, _y = _data.x + cursor[1] - 1, _data.y + cursor[2] - (bar and 0 or 1)
		success = success or (not border or border and cursor[1] > 1 and cursor[1] < _data.width and cursor[2] > 0 and cursor[2] < _data.height) and id == 0 or screen2[_y] and screen2[_y][_x] == id
		if success then
			local tmpy = cursor[2] + (bar and 1 or 0)
			local s, t, b = screen_s[tmpy], screen_t[tmpy], screen_b[tmpy]
			for i = monitor_mode == "extend" and #monitor_order or 1, 1, -1 do
				if _x > monitor_order[i].offset then
					if term.setCursorBlink then
						if blink then
							process_data.last_textcolor[i] = text_color
							set_term(i, "setTextColor", text_color)
							set_term(i, "setCursorPos", _x - monitor_order[i].offset, _y)
						end
						set_term(i, "setCursorBlink", blink)
					elseif my_blink and blink then
						process_data.last_textcolor[i] = text_color
						if b[cursor[1]] then
							local btmp = get_color[b[cursor[1]]]
							process_data.last_backcolor[i] = btmp
							set_term(i, "setBackgroundColor", btmp)
							set_term(i, "setTextColor", text_color)
							set_term(i, "setCursorPos", _x - monitor_order[i].offset, _y)
							set_term(i, "write", "#")
						end
					elseif not my_blink then
						if b[cursor[1]] then
							process_data.last_backcolor[i] = get_color[b[cursor[1]]]
							process_data.last_textcolor[i] = get_color[t[cursor[1]]]
							set_term(i, "setBackgroundColor", get_color[b[cursor[1]]])
							set_term(i, "setTextColor", get_color[t[cursor[1]]])
							set_term(i, "setCursorPos", _x - monitor_order[i].offset, _y)
							set_term(i, "write", s[cursor[1]])
						end
					end
					break
				end
			end
		end
	end
	function window.get_screen()
		return get_global_cache(data[state].width, data[state].height - (bar and 1 or 0))
	end
	function window.toggle_cursor_blink()
		if blink or my_blink then
			my_blink = not my_blink
			set_cursor()
		end
	end
	local function create_header(foreground)
		if foreground == last_header_first and last_header_width == data[state].width then
			screen_b[1] = last_header_b
			screen_s[1] = last_header_s
			screen_t[1] = last_header_t
			return nil
		end
		last_header_first = foreground
		last_header_width = data[state].width
		local b = {"", "", "", "", "", "", "", "", ""}
		local conf = settings
		if colored then
			for i = 1, id > 0 and #my_buttons or 1 do
				local a = my_buttons[i]
				b[1] = b[1] .. (foreground and hex[conf["window_" .. a[1] .. "_button_active_back"] or a[2]] or hex[conf["window_" .. a[1] .. "_button_inactive_back"] or a[3]])
				b[2] = b[2] .. "o"
				b[3] = b[3] .. (foreground and hex[conf["window_" .. a[1] .. "_button_active_text"] or a[4]] or hex[conf["window_" .. a[1] .. "_button_inactive_text"] or a[5]])
			end
		end
		b[4] = ((colored and " " or "=") .. title .. (colored and " " or "="):rep(last_header_width)):sub(1, colored and last_header_width - (id > 0 and #my_buttons or 0) - 1 or last_header_width)
		local __ = foreground
		if colored then
			if __ then
				b[5] = hex[conf.window_bar_active_back or 128]
				b[6] = hex[conf.window_bar_active_text or 1]
			else
				b[5] = hex[conf.window_bar_inactive_back or 128]
				b[6] = hex[conf.window_bar_inactive_text or 1]
			end
		elseif textutils and textutils.complete then
			b[5] = "7"
			b[6] = __ and "0" or "8"
		else
			b[5] = __ and "0" or "f"
			b[6] = __ and "f" or "0"
		end
		b[7] = colored and hex[conf.window_resize_button_back or 128] or b[7]
		b[8] = colored and (foreground and state == "normal" and id > 0 and "o" or " ") or b[8]
		b[9] = colored and hex[conf.window_resize_button_text or 256] or b[9]
		header_tmp[1] = _tconcat({b[1], b[5]:rep(#b[4]), b[7]})
		header_tmp[2] = _tconcat({b[2], b[4], b[8]})
		header_tmp[3] = _tconcat({b[3], b[6]:rep(#b[4]), b[9]})
		screen_s[1] = {}
		screen_t[1] = {}
		screen_b[1] = {}
		for i = 1, last_header_width do
			screen_b[1][i] = header_tmp[1]:sub(i, i)
			screen_s[1][i] = header_tmp[2]:sub(i, i)
			screen_t[1][i] = header_tmp[3]:sub(i, i)
		end
		last_header_b = screen_b[1]
		last_header_s = screen_s[1]
		last_header_t = screen_t[1]
	end
	function window.get_buttons()
		return my_buttons
	end
	function window.get_button(a)
		for i = 1, #my_buttons do
			if my_buttons[i][1] == a then
				return my_buttons[i]
			end
		end
		return nil
	end
	function window.set_buttons(a, b)
		my_buttons = a
		last_header_first = nil
		create_header(b)
		redraw_line(1)
		redraw_global_cache_line(false, data[state].y)
		set_cursor()
	end
	function redraw_line(line, pos_start, pos_end)
		if visible and can_draw then
			local cur_data = data[state]
			pos_start = pos_start and pos_end and (pos_start < 1 and 1 or pos_start) or nil
			pos_end = pos_start and pos_end and (pos_end > cur_data.width and cur_data.width or pos_end) or nil
			line = line or cursor[2] + (bar and 1 or 0)
			local ceiled_w, ceiled_h = border and math.ceil(cur_data.width * 0.5), border and math.ceil(cur_data.height * 0.5)
			if line > 0 and line <= cur_data.height then
				local _ypos = cur_data.y + line - 1
				screen2[_ypos] = screen2[_ypos] or {}
				local b = screen2[_ypos]
				screen_s[line] = screen_s[line] or {}
				screen_b[line] = screen_b[line] or {}
				screen_t[line] = screen_t[line] or {}
				local ltlength = #screen_s[line]
				local border_w, border_h = nil, nil
				for i = pos_start or 1, pos_end or cur_data.width do
					local _pos = cur_data.x + i - 1
					b[_pos] = b[_pos] or id
					if b[_pos] == id then
						global_cache.t[_ypos] = global_cache.t[_ypos] or {}
						global_cache.b[_ypos] = global_cache.b[_ypos] or {}
						global_cache.s[_ypos] = global_cache.s[_ypos] or {}
						if border and (line == cur_data.height or (i == 1 or i == cur_data.width) and line > 1) then
							local a = not border_w or not border_h
							border_w, border_h = a and ceiled_w or border_w, a and ceiled_h or border_h
							global_cache.t[_ypos][_pos] = settings.window_resize_border_text or 1
							global_cache.b[_ypos][_pos] = settings.window_resize_border_back or 128
							global_cache.s[_ypos][_pos] = line == border_h and "|" or i == border_w and "-" or " "
						else
							local a = screen_s[line][i]
							global_cache.t[_ypos][_pos] = a and get_color[screen_t[line][i]] or text_color
							global_cache.b[_ypos][_pos] = a and get_color[screen_b[line][i]] or back_color
							global_cache.s[_ypos][_pos] = screen_s[line][i] or " "
						end
					end
				end
			end
		end
	end
	local function redraw()
		for i = 1, visible and data[state].height or 0 do
			redraw_line(i)
		end
	end
	function window.has_header()
		return bar
	end
	function window.set_header_vis(a)
		if a ~= bar then
			bar = a
			data[state].height = data[state].height + (bar and 1 or -1)
		end
	end
	-- window functions
	function window.drawable(state)
		if type(state) == "boolean" then
			can_draw = state
		end
	end
	function window.get_data(sstate)
		local _data = sstate and data[sstate] or data[state]
		return _data.x, _data.y, _data.width, _data.height
	end
	function window.get_state()
		return state
	end
	function window.get_title()
		return title
	end
	function window.get_visible()
		return visible
	end
	function window.redraw(foreground, tScreen, nID)
		screen2 = tScreen or {}
		local id_old = id
		id = nID or 0
		if id_old ~= id then
			last_header_first = nil
		end
		if bar then
			create_header(foreground)
		end
		redraw()
		return screen2
	end
	function window.reposition(nX, nY, nWidth, nHeight, sstate)
		local _data = sstate and data[sstate] or data[state]
		_data.x = nX
		_data.y = nY
		_data.width = nWidth
		_data.height = nHeight
	end
	function window.restore_cursor()
		set_cursor()
	end
	function window.set_state(sState)
		if data[sState] then
			state = sState
			border = false
			last_header_first = nil
			create_header(true)
			redraw()
			redraw_global_cache(true)
		end
	end
	function window.set_title(new_title, foreground)
		if not foreground then
			my_blink = false
		end
		title = new_title
		if bar then
			last_header_first = nil
			create_header(foreground)
			redraw_line(1)
			redraw_global_cache_line(false, data[state].y)
		end
		set_cursor()
	end
	function window.set_visible(bVisible)
		visible = bVisible
	end
	function window.settings(new, foreground)
		settings = new
		if bar then
			last_header_first = nil
			create_header(foreground)
			redraw_line(1)
			redraw_global_cache_line(false, data[state].y + (bar and 1 or 0))
			set_cursor()
		end
	end
	function window.toggle_border(bVisible)
		border = bVisible
		redraw()
		redraw_global_cache(true)
	end
	-- term functions
	local function _blit(sText, sTextColor, sBackgroundColor)
		local text_len = #sText
		if cursor[2] < 1 then return end
		local cur = cursor[1] - 1
		local y = cursor[2] + (bar and 1 or 0)
		screen_s[y] = screen_s[y] or {}
		screen_b[y] = screen_b[y] or {}
		screen_t[y] = screen_t[y] or {}
		for i = #screen_s[y] + 1, cur do
			screen_s[y][i] = screen_s[y][i] or " "
			screen_t[y][i] = screen_t[y][i] or "0"
			screen_b[y][i] = screen_b[y][i] or "f"
		end
		local a = 1
		for i = cur + 1, cursor[1] + text_len - 1 do
			screen_s[y][i] = sText:sub(a, a)
			screen_t[y][i] = sTextColor:sub(a, a)
			screen_b[y][i] = sBackgroundColor:sub(a, a)
			a = a + 1
		end
		redraw_line(y, cursor[1], cur + text_len)
		redraw_global_cache_line(true, data[state].y + y - 1, data[state].x + cur, data[state].x + cur + text_len)
		cursor[1] = cursor[1] + text_len
		set_cursor()
	end
	if colored then
		function window.blit(sText, sTextColor, sBackgroundColor)
			expect(1, sText, "string")
			expect(2, sTextColor, "string")
			expect(3, sBackgroundColor, "string")
			local text_len = #sText
			if #sTextColor ~= text_len or #sBackgroundColor ~= text_len then
				error("Arguments must be the same length", 2)
			end
			_blit(sText, sTextColor, sBackgroundColor)
		end
	end
	function window.clear()
		screen_s = {bar and screen_s[1] or nil}
		screen_b = {bar and screen_b[1] or nil}
		screen_t = {bar and screen_t[1] or nil}
		redraw()
		redraw_global_cache(false)
		set_cursor()
	end
	function window.clearLine()
		screen_s[cursor[2] + (bar and 1 or 0)] = nil
		screen_b[cursor[2] + (bar and 1 or 0)] = nil
		screen_t[cursor[2] + (bar and 1 or 0)] = nil
		redraw_line()
		redraw_global_cache_line(true, data[state].y + cursor[2] + (bar and 1 or 0) - 1)
		set_cursor()
	end
	if term.setBackgroundColor then
		function window.getBackgroundColor()
			return back_color
		end
		window.getBackgroundColour = window.getBackgroundColor
	end
	function window.getCursorBlink()
		return blink
	end
	function window.getCursorPos()
		return cursor[1], cursor[2]
	end
	if term.setPaletteColor then
		function window.getPaletteColor(color)
			expect(1, color, "number")
			if color_codes[color] == nil then
				error("Invalid color (got " .. color .. ")", 2)
			end
			return color_codes[color][1], color_codes[color][2], color_codes[color][3]
		end
		window.getPaletteColour = window.getPaletteColor
	end
	function window.nativePaletteColor(num)
		local tmp = color_palette[settings.original_colors and "original" or "new"]
		local n = tmp[native_conv[num] or -1]
		if n then
			return n[1], n[2], n[3]
		end
		return 0, 0, 0
	end
	function window.getSize()
		return data[state].width, data[state].height - (bar and 1 or 0)
	end
	if term.setTextColor then
		function window.getTextColor()
			return text_color
		end
		window.getTextColour = window.getTextColor
	end
	if term.isColor then
		function window.isColor()
			return colored
		end
		window.isColour = window.isColor
	end
	function window.scroll(n)
		expect(1, n, "number")
		if n ~= 0 then
			if n > 0 then
				for _ = 1, n do
					if screen_s[1 + (bar and 1 or 0)] then
						table.remove(screen_s, 1 + (bar and 1 or 0))
						table.remove(screen_b, 1 + (bar and 1 or 0))
						table.remove(screen_t, 1 + (bar and 1 or 0))
					end
				end
			else
				for _ = n, -1 do
					screen_s[data[state].height] = nil
					screen_b[data[state].height] = nil
					screen_t[data[state].height] = nil
					table.insert(screen_s, 1 + (bar and 1 or 0), {})
					table.insert(screen_b, 1 + (bar and 1 or 0), {})
					table.insert(screen_t, 1 + (bar and 1 or 0), {})
				end
			end
			redraw()
			redraw_global_cache(true)
		end
	end
	if term.setBackgroundColor then
		function window.setBackgroundColor(color)
			expect(1, color, "number")
			back_color = color
		end
		window.setBackgroundColour = window.setBackgroundColor
	end
	function window.setCursorBlink(a)
		expect(1, a, "boolean")
		my_blink, blink = true, a
		set_cursor()
	end
	function window.setCursorPos(x_, y_)
		expect(1, x_, "number")
		expect(2, y_, "number")
		local mb = my_blink
		if not term.setCursorBlink then
			my_blink = false
			set_cursor()
		end
		cursor[1], cursor[2], my_blink = math.floor(x_), math.floor(y_), mb
		set_cursor()
	end
	if term.setTextColor then
		function window.setTextColor(color)
			expect(1, color, "number")
			text_color = color
		end
		window.setTextColour = window.setTextColor
	end
	if term.setPaletteColor then
		function window.setPaletteColour(color, r, g, b)
			expect(1, color, "number")
			if not color_codes[color] then
				error("Invalid color (got " .. color .. ")", 2)
			end
			local new_color = {}
			if type(r) == "number" and not g and not b then
				new_color = {colours.unpackRGB(r)}
			else
				expect(2, r, "number")
				expect(3, g, "number")
				expect(4, b, "number")
				new_color[1], new_color[2], new_color[3] = r, g, b
			end
			color_codes[color] = new_color
		end
		window.setPaletteColor = window.setPaletteColour
	end
	function window.write(sText)
		local text_type = type(sText)
		if text_type ~= "string" and text_type ~= "number" then error("bad argument #1 (expected string or number, got " .. text_type .. ")", 2) end
		sText = sText .. ""
		local text_len = #sText
		_blit(sText, hex[text_color]:rep(text_len), hex[back_color]:rep(text_len))
	end
	return window
end