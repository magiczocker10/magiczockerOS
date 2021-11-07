-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local peri, _computer_only, monitor_order, total_size, monitor_mode, global_visible, pixel_size, cdo_args = apis.peripheral.create(true), component and {} or {"term"}, {}, {0, 0}, "normal", true, {6, 9}, {0, 0}
local global_cache, global_cache_old, peri_call, peri_type, colored, h, term
local screen_cache, _tconcat = {}, table.concat
local validate_modes = {
	["normal"] = true,
	["extend"] = true,
	["duplicate"] = true,
}
function set_peripheral(object)
	peri_call = object and object.call or nil
	peri_type = object and object.getType or nil
	term = peri.wrap(peri.find("term") or peri.find("monitor"))
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
function clear_cache(keep_old)
	screen_cache = not keep_old and screen_cache or {}
	global_cache = keep_old and global_cache or {t = {}, b = {}, s = {}}
	global_cache_old = keep_old and global_cache_old or {}
end
function set_term(device, mode, ...)
	for i = monitor_mode == "duplicate" and 1 or device or 1, monitor_mode == "duplicate" and #monitor_order or device or 1 do
		peri_call(monitor_order[i].name, mode, ...)
	end
end
local function get_nearest_scale(mode, device, length)
	local _mode = mode == "width" and 1 or 2
	peri_call(device, "setTextScale", 0.5)
	local _size = {peri_call(device, "getSize")}
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
	local w = nil
	local _size = {0, 0}
	h = nil
	for i = 1, mon_len do
		peri_call(monitor_order[i].name, "setTextScale", 0.5)
		_size[1], _size[2] = peri_call(monitor_order[i].name, "getSize")
		w = (not w or w > _size[1]) and _size[1] or w
		h = (not h or h > _size[2]) and _size[2] or h
	end
	for i = 1, mon_len do
		local mo = monitor_order[i]
		if mo.name ~= "term" then
			local _w, _h = get_nearest_scale("width", mo.name, w), get_nearest_scale("height", mo.name, h)
			peri_call(mo.name, "setTextScale", 5) -- Force the event "monitor_resize" to fire
			local a = _w > _h and _h or _w
			cdo_args[1], cdo_args[2] = math.max(0.5, a - 0.5), math.min(5, a + 0.5)
			for j = cdo_args[2], cdo_args[1], -0.5 do
				peri_call(mo.name, "setTextScale", j)
				local tmp = {peri_call(mo.name, "getSize")}
				if tmp[1] >= w and tmp[2] >= h then
					break
				end
			end
		end
		_size = {peri_call(mo.name, "getSize")}
		mo.height, mo.startx, mo.endx, mo.offset = _size[2], cur_offset + 1, cur_offset + _size[1], cur_offset
		cur_offset = monitor_mode == "extend" and cur_offset + _size[1] or 0
		total_width = total_width + _size[1]
		if monitor_mode ~= "extend" and i == 1 then
			w, h = _size[1], _size[2]
			total_size[1], total_size[2] = w, h
		end
		h = monitor_mode == "extend" and h > _size[2] and _size[2] or h
	end
	if monitor_mode == "extend" then
		total_size[1], total_size[2] = total_width, h
	end
	if #monitor_order == 0 then
		error"No valid devices."
	end
end
function set_devices(mode, ...)
	monitor_mode = validate_modes[mode] and mode or "normal"
	local bw, list = false, monitor_mode == "normal" and _computer_only or {...}
	local m_o = monitor_order
	monitor_order = {}
	local processed = {}
	for i = 1, #list do
		if not processed[list[i]] and peri_type(list[i]) == "monitor" then
			peri_call(list[i], "setBackgroundColor", 32768)
			peri_call(list[i], "clear")
			bw = not peri_call(list[i], "isColor") or bw
			monitor_order[#monitor_order + 1] = {name = list[i]}
		end
		processed[list[i]] = true
	end
	colored = not bw
	for i = 1, peri_call and type(m_o) == "table" and #m_o or 0 do
		peri_call(m_o[i].name, "setBackgroundColor", 32768)
		peri_call(m_o[i].name, "clear")
	end
	monitor_order[#monitor_order + 1] = #monitor_order == 0 and {name = component and peri.find("monitor") or "term"} or nil
	calculate_device_offset()
	clear_cache()
end
local function can_added(data, content, text, back, x)
	if #data[2] == 0 or data[1] == x - #data[2] and back == data[3] and (content == " " or data[4] == -1 or text == data[4]) then
		if #data[2] == 0 then
			data[1], data[3], data[4] = x, back, -1
		end
		data[4] = data[4] == -1 and content ~= " " and text or data[4]
		data[2][#data[2] + 1] = content
		return true
	end
	return false
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
	local to_repeat, startxorg, endxorg = {}, startx, endx
	local goto_limit = return_data and 1 or #monitor_order
	local limit_set
	for screen = 1, goto_limit do
		local s = monitor_order[screen]
		local startx = math.max(startxorg or s.startx, s.startx)
		local endx = math.min(endxorg or s.endx, s.endx)
		limit_set = return_data or startxorg and endxorg
		local continue = endx >= startx and startx <= s.endx and s.startx <= endx
		local to_draw, cur_data = {-1, {}, -1, -1}, {0, -1, -1} -- x, text, bcol, tcol; x, backc, textc
		local _sline, _bline, _tline = global_cache.s[line], global_cache.b[line], global_cache.t[line]
		global_cache_old[line] = global_cache_old[line] or {}
		local _l = global_cache_old[line]
		startx, endx = not continue and 1 or startx, not continue and 0 or endx
		for i = startx, endx do
			local _lx = _l[i] or {}
			local s, b, t, _s, _b, _t = _sline[i], _bline[i], _tline[i], _lx.s, _lx.b, _lx.t
			if s and (not check_changes or not _l[i] or (b ~= _b or t ~= _t or s ~= _s) and not (b == _b and s == " " and _s == " ")) then
				if not can_added(to_draw, s, t, b, i) then
					draw_text(screen, cur_data, to_draw, line, return_data and to_repeat)
					to_draw[2] = {}
					to_draw[4] = -1
					can_added(to_draw, s, t, b, i)
				end
				_l[i] = _l[i] or {}
				_l[i].b = to_draw[3]
				_l[i].t = to_draw[4] < 1 and t or to_draw[4]
				_l[i].s = s
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
	for i = 2, monitor_mode == "duplicate" and #monitor_order or 1 do
		for j = 1, #rd do
			local tmp = rd[j]
			for k = 1, #tmp do
				draw_text(i, copy_table(tmp[k][1]), copy_table(tmp[k][2]), tmp[k][3])
			end
		end
	end
end
function get_screen()
	return screen_cache
end
function get_mode()
	return monitor_mode
end
function get_devices()
	return monitor_order
end
function get_size()
	return total_size[1], total_size[2]
end
function has_palette()
	return not not term.setPaletteColor
end
function has_cursor_blink()
	return not not term.setCursorBlink
end
function is_colored()
	return colored
end
function is_visible()
	return global_visible
end
function write(x, y, pixel_data)
	if x < 1 or x > total_size[1] or y < 1 or y > total_size[2] then
		return
	end
	screen_cache[y] = screen_cache[y] or {}
	if not screen_cache[y][x] or screen_cache[y][x] == pixel_data.id then
		global_cache.t[y] = global_cache.t[y] or {}
		global_cache.b[y] = global_cache.b[y] or {}
		global_cache.s[y] = global_cache.s[y] or {}
		global_cache.t[y][x] = pixel_data.t
		global_cache.b[y][x] = pixel_data.b
		global_cache.s[y][x] = pixel_data.s
		screen_cache[y][x] = pixel_data.id
	end
end