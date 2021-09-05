-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local term = term
local max_height, max_width, my_size, key_maps, settings, my_pos, scrollable, cur_settings = 15, 20, {0, 0}, {}, user_data().settings or {}, {0, 0}, false, {}
local cursor, items, scroll, caller, parents, cur_raw
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local cs = cur_settings
local events
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function update_cached_settings()
	cs.cmb = get_setting(settings, "context_menu_background")
	cs.cmia = get_setting(settings, "context_menu_items_align")
	cs.cmt = get_setting(settings, "context_menu_text")
end
local function process_data(x, y)
	local maxw, maxh = get_total_size()
	local maxtw, maxth = maxw, maxh
	maxw, maxh = math.min(maxw - 2, max_width), math.min(maxh - 3, max_height)
	local curw, curh = 1, math.min(#items, maxh)
	for i = 1, #items do
		if #items[i].txt > curw then
			curw = #items[i].txt
		end
	end
	curw = math.min(curw + 2, maxw)
	if x + curw > maxtw then
		x = maxtw - curw
	end
	if y + curh > maxth then
		y = maxth - curh
	end
	if x < 2 then
		x = 2
	end
	if y < 3 then
		y = 3
	end
	my_pos[1], my_pos[2] = x, y
	my_size[1], my_size[2] = curw, curh
	scrollable = #items > maxh
	scroll = 0
	if scrollable and not (items[1].txt == "^" and items[1].system_added) then
		for i = #items, 1, -1 do
			items[i + 1] = items[i]
		end
		items[1] = {system_added = true, txt = "^", on_click = function() scroll = scroll + 1 end}
		items[#items + 1] = {txt = "v", on_click = function() scroll = scroll + 1 end}
	end
	if not term.isColor or not term.isColor() then
		cursor = 1 + (scrollable and 1 or 0)
	end
	set_pos(x, y, curw, curh)
end
local function correct_scroll()
	if cursor - scroll > my_size[2] then
		scroll = cursor - my_size[2]
	elseif cursor - scroll < 1 then
		scroll = 1 - scroll + cursor
	end
end
local function draw()
	back_color(1, 128, cs.cmb)
	text_color(32768, 1, cs.cmt)
	local is_bw = not term.isColor or not term.isColor()
	local to_add = (" "):rep(my_size[1])
	local align = math.max(1, math.min(3, cs.cmia))
	for i = 1, my_size[2] do
		term.setCursorPos(1, i)
		local tmp = scrollable and (i == 1 and "^^^" or i == my_size[2] and "vvv") or items[i + scroll].txt
		if tmp then
			local dot = #tmp > my_size[1] - 2
			if dot and align == 2 then
				tmp = tmp:sub(1, my_size[1] - 2)
			end
			tmp = (align == 1 and "" or to_add) .. tmp .. (align == 3 and "" or to_add)
			local half = align == 2 and math.floor((#tmp - my_size[1] + 1) * 0.5) + 2
			local part_one = align == 2 and half or align == 1 and 1 or (my_size[1] - 2) * -1
			local part_two = align == 2 and half - 3 + my_size[1] or align == 1 and my_size[1] - 2 or nil
			tmp = tmp:sub(part_one, part_two)
			if dot then
				tmp = tmp:sub(1, -3) .. ".."
			end
			if items[i + scroll] and type(items[i + scroll].event) == "table" then
				tmp = tmp:sub(align, align == 2 and -2 or align == 1 and -3 or nil) .. " >"
			end
			if is_bw and cursor == i + scroll then
				tmp = "-" .. tmp .. "-"
			else
				tmp = " " .. tmp .. " "
			end
		end
		term.write(tmp or to_add)
	end
end
local function setup_data(data)
	my_size[1], my_size[2], cur_raw = 0, 0, data
	for i = 1, #data do
		items[#items + 1] = {txt = data[i][1], event = data[i][2], raw = data[i]}
	end
	process_data(my_pos[1], my_pos[2])
end
local function unpack(a, b)
	local b = b or 1
	if a[b] then
		return a[b], unpack(a, b + 1)
	end
end
local function handle_click(a)
	if type(items[a].event) == "function" and items[a].system_added then
		items[a].event()
	elseif type(items[a].event) == "table" then
		parents[#parents + 1] = {cur_raw, my_pos[1], my_pos[2]}
		local tmp = items[a].event
		items = {
			{
				system_added = true, txt = "< Back", event = function()
					local d = parents[#parents][1]
					my_pos[1], my_pos[2] = parents[#parents][2], parents[#parents][3]
					items, parents[#parents] = {}, nil
					setup_data(d)
					draw()
				end,
			},
		}
		setup_data(tmp)
		draw()
	else
		os.queueEvent(caller.id .. "", caller.user or "", unpack(items[a].raw, 2))
		set_visible("contextmenu", false)
	end
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end

register_key(_HOSTver >= 1132 and 46 or 52, function() -- .
	if system_windows.contextmenu.window.get_visible() then return end
	local ud = user_data()
	local co_window, my_window
	for i = 1, #system_window_order do
		if system_windows[system_window_order[i]].window.get_visible() then
			my_window = system_windows[system_window_order[i]]
			co_window = my_window.contextmenu_on_key
			if co_window then
				break
			end
		end
		if not co_window and system_window_order[i] == "taskbar" and #ud.windows > 0 and ud.windows[1].window.get_visible() then
			my_window = ud.windows[1]
			co_window = my_window.contextmenu_on_key
			if co_window then
				break
			end
		end
	end
	if co_window then
		local win_x, win_y = my_window.window.get_data()
		events("set_data", co_window.data, win_x - 1 + co_window.x, win_y - 1 + co_window.y, my_window)
		events("redraw_items")
		set_visible("contextmenu", true)
	end
end)
update_cached_settings()
function events(a, b, c, d, e)
	if a == "set_data" then
		parents = {}
		caller = e
		items = {}
		my_pos[1] = c
		my_pos[2] = d
		setup_data(b)
	elseif a == "redraw_items" then
		draw()
	elseif a == "mouse_click" then
		if scrollable and (d == 1 and scroll > 0 or d == my_size[2] and #items - scroll > my_size[2]) then
			scroll = scroll + (d == 1 and scroll > 0 and -1 or 1)
			draw()
		elseif items[d + scroll].event then
			handle_click(d + scroll)
		end
	elseif a == "mouse_scroll" and scrollable then
		if b > 0 and #items - scroll > my_size[2] or b < 0 and scroll > 0 then
			scroll = scroll + b > 0 and 1 or -1
			draw()
		end
	elseif a == "key" and (not term.isColor or not term.isColor()) then
		local _key = key_maps[b]
		if _key == "up" and cursor > 0 or _key == "down" and cursor < #items - (scrollable and 1 or 0) then
			cursor = cursor + (_key == "up" and -1 or 1)
			correct_scroll()
			draw()
		elseif _key == "enter" and items[cursor].event then
			handle_click(cursor)
		end
	elseif a == "refresh_settings" then
		settings = user_data().settings or {}
		update_cached_settings()
		draw()
	end
end
while true do
	events(coroutine.yield())
end