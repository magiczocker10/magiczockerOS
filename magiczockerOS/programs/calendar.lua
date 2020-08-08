-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local windows = {}
local key_maps = {}
local selected = {1, 1, 2000}
local height = 8
local week_days = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
local user = user or ""
local settings = settings or {}
local last_views = {}
local month_names = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December",
}
local _month_width = (" "):rep(25)
local _year_width = _month_width
local cur_day = {1, 8, 2019} -- set the start-date
local cur_view = 1
local cur_view_cursor = 0
local function size(w,h)
	if size then
		set_size(w,h)
		magiczockerOS.contextmenu.clear_map()
		local tmp=magiczockerOS.contextmenu.add_map(1,1,w,h,{{"Goto date","goto_date"}})
		magiczockerOS.contextmenu.on_menu_key(tmp,1,1)
	end
end
local function background_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function get_month_days(m)
	return m == 2 and 28 or (m % 2 == (m < 8 and 0 or 1) and 30 or 31) -- the 29th will be added seperatly
end
local function is_leap_year(year)
	return year % 4 == 0 and (year * 0.01 % 1 > 0 or year * 0.01 % 4 == 0)
end
local function convert_date_to_number(dat)
	local to_return = dat[1]
	if dat[3] > 1900 then -- years
		for i = 1900, dat[3] - 1 do
			to_return = to_return + 365 + (is_leap_year(i) and 1 or 0)
		end
	end
	if dat[2] > 1 then -- months
		for i = 1, dat[2] - 1 do
			to_return = to_return + get_month_days(i) + (i == 2 and is_leap_year(dat[3]) and 1 or 0)
		end
	end
	return to_return
end
local function get_week_number(dat, total)
	local day_one = convert_date_to_number({1, 1, dat[3]})
	local day_two = convert_date_to_number(total and {31, 12, dat[3]} or dat)
	local wd_one = day_one % 7
	wd_one = wd_one == 0 and 7 or wd_one
	local wd_two = day_two % 7
	wd_two = wd_two == 0 and 7 or wd_two
	local to_return = day_two - day_one + 1
	to_return = wd_one > 4 and to_return - 8 + wd_one or to_return + wd_one - 1
	to_return = (total and (wd_two > 3 and to_return + 7 - wd_two or to_return - wd_two) or to_return) / 7
	if not total then
		to_return = to_return % 1 > 0 and floor(to_return) + 1 or to_return
		if to_return > get_week_number({31, 12, dat[3]}, true) then
			to_return = 1
		elseif to_return == 0 then
			to_return = get_week_number({31, 12, dat[3] - 1}, true)
		end
	end
	return to_return
end
local function draw_month()
	local td = get_month_days(cur_day[2])
	local _width = _month_width
	local wd = convert_date_to_number({1, cur_day[2], cur_day[3]}) % 7
	local wn = get_week_number({1, cur_day[2], cur_day[3]})
	local wnt = get_week_number({1, cur_day[2], cur_day[3]}, true)
	wd = wd == 0 and 7 or wd
	if set_size then
		local height_ = height
		height = ceil((td + wd - 1) / 7) + 5
		if height ~= height_ then
			height_ = height
			size(25, height)
		end
	end
	term.setCursorPos(1, 1)
	term.write(_width)
	term.setCursorPos(1, 2)
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.write((cur_day[3] > 1900 or cur_day[2] > 1) and "<" or " ")
	local temp = month_names[cur_day[2]] .. " " .. cur_day[3]
	local to_add = (17 - #temp) * .5
	term.write((" "):rep(floor(to_add)) .. temp .. (" "):rep(ceil(to_add)))
	term.write((cur_day[3] < 9999 or cur_day[2] < 12) and ">" or " ")
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.setCursorPos(1, 3)
	term.write(_width)
	term.setCursorPos(1, 4)
	term.write"    "
	for i = 1, 7 do
		term.write(week_days[i] .. (i == 7 and "" or "|"))
	end
	term.write" "
	term.setCursorPos(1, 5)
	local _wn = " " .. wn
	_wn = _wn:sub(#_wn - 1)
	term.write(" " .. _wn .. " ")
	term.write((" "):rep((wd - 1) * 3))
	local row = 5
	for i = 1, td do
		if selected[3] == cur_day[3] and selected[2] == cur_day[2] and selected[1] == i then
			text_color(1, 128, settings.calendar_text_hightlight or 128)
			term.write((" " .. i):sub(-2))
			text_color(1, 1, settings.calendar_text or 1)
		else
			term.write((" " .. i):sub(-2))
		end
		wd = wd + 1
		if i == td then
			term.write((" "):rep((8 - wd) * 3) .. " ")
		elseif wd == 8 then
			term.write" "
			wn, wd, row = wn >= wnt and 1 or wn, 1, row + 1
			term.setCursorPos(1, row)
			local _wn = " " .. wn
			_wn = _wn:sub(#_wn - 1)
			term.write(" " .. _wn .. " ")
		else
			term.write(i < td and "|" or " ")
		end
	end
	term.setCursorPos(1, row + 1)
	term.write(_width)
end
local function draw_months()
	term.setCursorPos(1, 1)
	term.write(_month_width)
	term.setCursorPos(1, 2)
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.write(cur_day[3] > 1900 and "<" or " ")
	term.write("      " .. cur_day[3] .. "       ")
	term.write(cur_day[3] < 9999 and ">" or " ")
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.setCursorPos(1, 3)
	term.write(_month_width)
	for j = 1, 12, 6 do
		term.setCursorPos(1, j == 1 and 4 or 6)
		for i = j, j + 5 do
			local temp = 1 - 1 + i
			if i == 1 or i == 7 then
				term.write(cur_view_cursor == i and ">" or " ")
			end
			if selected[3] == cur_day[3] and selected[2] == temp then
				text_color(1, 128, settings.calendar_text_highlight or 128)
			else
				text_color(1, 1, settings.calendar_text or 1)
			end
			term.write(month_names[temp]:sub(1, 3))
			if cur_view_cursor == i then
				term.write"<"
			elseif cur_view_cursor == i + 1 and i ~= 6 then
				term.write">"
			else
				term.write" "
			end
		end
		if j < 7 then
			term.setCursorPos(1, 5)
			term.write(_month_width)
		end
	end
	term.setCursorPos(1, 7)
	term.write(_month_width)
	term.setCursorPos(1, 8)
	term.write(_month_width)
end
local function draw_years()
	local year = cur_day[3]
	local __ = year % 8
	if __ < 4 then
		year = year - 4 - __
	elseif __ > 4 then
		year = year - __ + 4
	end
	cur_day[3] = year
	term.setCursorPos(1, 1)
	term.write(_year_width)
	term.setCursorPos(1, 2)
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.write(cur_day[3] > 1900 and "<" or " ")
	term.write("   Please sel.   ")
	term.write(cur_day[3] < 9996 and ">" or " ")
	term.write((not term.isColor or not term.isColor()) and cur_view_cursor == 0 and " - " or "   ")
	term.setCursorPos(1, 3)
	term.write(_year_width)
	for j = 1, 8, 4 do
		term.setCursorPos(1, j == 1 and 4 or 6)
		term.write"  "
		for i = j, j + 3 do
			local temp = year - 1 + i
			if i == 1 or i == 5 then
				term.write(cur_view_cursor == i and ">" or " ")
			end
			if temp > 9999 then
				term.write"    "
			else
				if selected[3] == temp then
					text_color(1, 128, settings.calendar_text_hightlight or 128)
				else
					text_color(1, 1, settings.calendar_text or 1)
				end
				term.write(temp)
			end
			if cur_view_cursor == i then
				term.write"<"
			elseif cur_view_cursor == i + 1 and i + 1 < (j == 1 and 5 or 9) then
				term.write">"
			else
				term.write" "
			end
		end
		term.write"  "
		if j == 1 then
			term.setCursorPos(1, 5)
			term.write(_year_width)
		end
	end
	term.setCursorPos(1, 7)
	term.write(_year_width)
	term.setCursorPos(1, 8)
	term.write(_year_width)
end
local function draw()
	background_color(32768, 256, settings.calendar_back or 256)
	text_color(1, 1, settings.calendar_text or 1)
	if set_size and (cur_view == 2 or cur_view == 3) and height ~= 8 then
		height = 8
		size(25, 8)
	end
	if cur_view == 1 then
		draw_month()
	elseif cur_view == 2 then
		draw_months()
	elseif cur_view == 3 then
		draw_years()
	end
end
local function change_page(dir)
	if cur_view == 1 then
		if dir == "left" and (cur_day[3] > 1900 or cur_day[2] > 1) then
			cur_day[2] = cur_day[2] - 1
			if cur_day[2] == 0 then
				cur_day[2] = 12
				cur_day[3] = cur_day[3] - 1
			end
			draw()
		elseif dir == "right" and (cur_day[3] < 9999 or cur_day[2] < 12) then
			cur_day[2] = cur_day[2] + 1
			if cur_day[2] == 13 then
				cur_day[2] = 1
				cur_day[3] = cur_day[3] + 1
			end
			draw()
		end
	elseif cur_view == 2 or cur_view == 3 then
		if dir == "left" and cur_day[3] > 1900 then
			cur_day[3] = cur_day[3] - (cur_view == 2 and 1 or 8)
			draw()
		elseif dir == "right" and cur_day[3] < 9996 then
			cur_day[3] = cur_day[3] + (cur_view == 2 and 1 or 8)
			if cur_day[3] > 9999 then
				cur_day[3] = 9999
			end
			draw()
		end
	end
end
do
	local a = (_HOSTver or 0) >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
size(25, 8)
draw()
while true do
	local e, d, x, y = coroutine.yield()
	if e == "mouse_click" then
		if cur_view == 1 then
			if y == 2 and x > 4 and x < 22 then
				cur_view = cur_view + 1
				draw()
			elseif y == 2 and x == 4 and (cur_day[3] > 1900 or cur_day[2] > 1) then
				change_page("left")
			elseif y == 2 and x == 22 and (cur_day[3] < 9999 or cur_day[2] < 12) then
				change_page("right")
			end
		elseif cur_view == 2 then
			if x == 4 and y == 2 and cur_day[3] > 1900 then
				change_page("left")
			elseif x == 22 and y == 2 and cur_day[3] < 9996 then
				change_page("right")
			elseif x > 10 and x < 15 and y == 2 then
				cur_view = cur_view + 1
				draw()
			elseif x < 25 and (y == 4 or y == 6) then
				local x = (x - 1) * 0.25
				if x % 1 > 0 then
					cur_view = 1
					cur_day[2] = 6 * (y == 4 and 0 or 1) + ceil(x)
					draw()
				end
			end
		elseif cur_view == 3 then
			if x == 4 and y == 2 and cur_day[3] > 1900 then
				change_page("left")
			elseif x == 22 and y == 2 and cur_day[3] < 9996 then
				change_page("right")
			elseif y == 4 or y == 6 then
				local x = (x - 3) * .2
				if x % 1 > 0 then
					cur_view = 2
					cur_day[3] = cur_day[3] - 1 + 4 * (y == 4 and 0 or 1) + ceil(x)
					draw()
				end
			end
		end
	elseif e == "mouse_scroll" then
		change_page(d == 1 and "right" or "left")
	elseif e == "key" and cur_view_cursor == 0 and (key_maps[d] == "left" or key_maps[d] == "right") then
		change_page(key_maps[d])
	elseif e == "key" and key_maps[d] and (not term.isColor or not term.isColor()) then
		local _key = key_maps[d]
		if _key == "enter" then
			if cur_view_cursor == 0 and cur_view < 3 then
				cur_view = cur_view + 1
				draw()
			elseif cur_view_cursor > 0 and cur_view == 2 then
				cur_view = 1
				cur_day[2] = cur_view_cursor
				cur_view_cursor = 0
				draw()
			elseif cur_view_cursor > 0 and cur_view == 3 then
				cur_view = 2
				local year = cur_day[3]
				local year_mod = year % 8
				year = year_mod < 4 and year - 4 - year_mod or year_mode > 4 and year - year_mode + 4 or year
				cur_day[3] = year - 1 + cur_view_cursor
				cur_view_cursor = 1
				draw()
			end
		elseif _key == "up" then
			if (cur_view == 2 or cur_view == 3) and cur_view_cursor > 0 then
				cur_view_cursor = cur_view_cursor - (cur_view == 2 and 6 or 4)
				if cur_view_cursor < 0 then
					cur_view_cursor = 0
				end
				draw()
			end
		elseif _key == "down" then
			if cur_view == 2 and cur_view_cursor < 12 then
				cur_view_cursor = cur_view_cursor + (cur_view_cursor == 0 and 1 or 6)
				if cur_view_cursor > 12 then
					cur_view_cursor = 12
				end
				draw()
			elseif cur_view == 3 then
				cur_view_cursor = cur_view_cursor + (cur_view_cursor == 0 and 1 or 6)
				if cur_view_cursor > 8 then
					cur_view_cursor = 8
				end
				draw()
			end
		elseif _key == "left" then
			if cur_view == 2 or cur_view == 3 then
				if cur_view_cursor == 1 or cur_view_cursor == (cur_view == 2 and 7 or 5) then
					cur_day[3] = cur_day[3] - (cur_view == 3 and 8 or 1)
					if cur_day[3] < 1900 then
						cur_day[3] = 1900
					else
						if cur_view == 2 then
							cur_view_cursor = cur_view_cursor == 1 and 6 or 12
						else
							cur_view_cursor = cur_view_cursor == 1 and 4 or 8
						end
					end
					draw()
				elseif cur_view_cursor > 0 then
					cur_view_cursor = cur_view_cursor - 1
					draw()
				end
			end
		elseif _key == "right" then
			if cur_view == 2 then
				if cur_view_cursor == 6 or cur_view_cursor == 12 then
					cur_day[3] = cur_day[3] + 1
					if cur_day[3] > 9999 then
						cur_day[3] = 9999
					else
						cur_view_cursor = cur_view_cursor == 6 and 1 or 7
					end
					draw()
				elseif cur_view_cursor > 0 then
					cur_view_cursor = cur_view_cursor + 1
					draw()
				end
			elseif cur_view == 3 then
				if cur_view_cursor == 4 or cur_view_cursor == 8 then
					cur_day[3] = cur_day[3] + 8
					if cur_day[3] > 9999 then
						cur_day[3] = 9999
					else
						cur_view_cursor = cur_view_cursor == 4 and 1 or 5
					end
					draw()
				elseif cur_view_cursor > 0 then
					cur_view_cursor = cur_view_cursor + 1
					if cur_day[3] - 1 + cur_view_cursor > 9999 then
						cur_view_cursor = cur_view_cursor - 1
					end
					draw()
				end
			end
		end
	elseif e == "refresh_settings" then
		settings = get_settings()
		draw()
	elseif e == "user" then
		last_views[user] = not x and {{cur_day[1], cur_day[2], cur_day[3]}, cur_view, cur_view_cursor} or nil
		user, cur_view, cur_day[1], cur_day[2], cur_day[3] = d, 1, selected[1], selected[2], selected[3]
		if last_views[user] then
			cur_day[1], cur_day[2], cur_day[3], cur_view, cur_view_cursor = last_views[user][1][1], last_views[user][1][2], last_views[user][1][3], last_views[user][2], last_views[user][3]
		end
		height = 0
		draw()
	elseif e == "term_resize" then
		draw()
	elseif e == "set_date" then
		local tmp=windows[d]
		cur_day[1], cur_day[2], cur_day[3] = tonumber(tmp.day), tonumber(tmp.month), tonumber(tmp.year)
		cur_view, height, selected[1], selected[2], selected[3] = 1, 0, cur_day[1], cur_day[2], cur_day[3]
		draw()
	elseif e == "goto_date" then
		windows[#windows + 1] = {done = false,day = 1, month = 1, year = 1, queue = os.queueEvent, num = #windows + 1}
		create_window("/magiczockerOS/programs/calendar/goto_date.lua", true, windows[#windows])
	end
end