-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local w, h = 25, 1
local cur_date = os.date and os.date("*t") or {} -- day hour min month sec wday yday year
local cursor = {1, 1}
local view, month, year, offset, months, width, month_keys, year_keys, leap_year, key_maps = 3, cur_date.month or 1, cur_date.year or 2020, 0, {{"Jan", 31, 31}, {"Feb", 28, 59}, {"Mar", 31, 90}, {"Apr", 30, 120}, {"May", 31, 151}, {"Jun", 30, 181}, {"Jul", 31, 212}, {"Aug", 31, 243}, {"Sep", 30, 273}, {"Oct", 31, 304}, {"Nov", 30, 334}, {"Dec", 31, 365}}, (" "):rep(w), {1, 4, 4, 0, 2, 5, 0, 3, 6, 1, 4, 6}, { [1700] = 4, [1800] = 2, [1900] = 0, [2000] = 6 }, false, {}
local settings = user_data().settings or {}
local function get_week_day(a, b, c) -- Source: http://mathforum.org/dr.math/faq/faq.calendar.html
	local year2 = tonumber(tostring(c):sub(-2))
	leap_year = c % 4 == 0 and not (c % 100 == 0 and c % 400 > 0)
	local tmp = (math.floor(year2 * 0.25) + a + month_keys[b] - ((leap_year and b == 1 or leap_year and b == 2) and 1 or 0) + year_keys[tonumber(tostring(c):sub(1, -3) .. "00")] + year2) % 7
	return tmp == 0 and 6 or tmp == 1 and 7 or tmp - 1
end
local function get_week(a, b, c) -- Source: http://www.salesianer.de/util/kalwoch.html
	local d = (b > 1 and months[b - 1][3] or 0) + (c % 4 == 0 and not (c % 100 == 0 and c % 400 > 0) and b > 2 and 1 or 0)
	return (d + a - get_week_day(a, b, c) + get_week_day(4, 1, c) - 4) / 7 + 1
end
local function draw(a, b)
	local line = ""
	if view < 3 then -- Year and Month overview
		for y = a or 1, b or 8 do
			if y == 2 then
				line = view == 1 and " " .. (cursor[2] == 1 and "-" or " ") .. " " .. (year > 1970 and "<" or " ") .. "  Please select  " .. ">" .. (cursor[2] == 1 and "-" or " ") .. " " or " " .. (cursor[2] == 1 and "-" or " ") .. " " .. (year > 1970 and "<" or " ") .. (" "):rep(math.floor((17 - #tostring(year)) * 0.5)) .. year .. (" "):rep(math.ceil((17 - #tostring(year)) * 0.5)) .. "> " .. (cursor[2] == 1 and "-" or " ") .. " "
			elseif y == 4 or y == 6 then
				if view == 1 then -- Year overview
					line = " " .. (cursor[2] == (y == 4 and 2 or 3) and cursor[1] == (y == 6 and 5 or 1) and ">" or " ")
					local start, iend = year - 1, y == 6 and 8 or 4
					for i = y == 6 and 5 or 1, iend do
						line = line .. start + i .. (cursor[1] == i + 1 and i < iend and ">" or cursor[1] == i and "<" or " ")
					end
					line = line .. "  "
				else -- Month overview
					line = cursor[2] == (y == 4 and 2 or 3) and cursor[1] == (y == 6 and 7 or 1) and ">" or " "
					local iend = y == 6 and 12 or 6
					for i = y == 6 and 7 or 1, iend do
						line = line .. months[i][1] .. (cursor[1] == i + 1 and i < iend and ">" or cursor[1] == i and "<" or " ")
					end
				end
			else
				line = width
			end
			term.setCursorPos(1,y)
			term.write(line)
		end
		if 8 ~= h then
			h = 8
			set_pos(nil, nil, w, h)
		end
	elseif view == 3 then -- Day overview
		offset = get_week_day(1, month, year)
		local tmp = months[month][1] .. " " .. year
		local endline = 10
		months[2][2] = leap_year and 29 or 28
		local tmp2 = get_week(1, month, year)
		for y = a or 1, b or 11 do
			if y == 2 then
				line = " " .. (cursor[2] == 1 and "-" or " ") .. " " .. (year == 1970 and month == 1 and " " or "<") .. (" "):rep(math.floor((17 - #tmp) * 0.5)) .. tmp .. (" "):rep(math.ceil((17 - #tmp) * 0.5)) .. "> " .. (cursor[2] == 1 and "-" or " ") .. " "
			elseif y == 4 then
				line = "    Mo,Tu,We,Th,Fr,Sa,Su "
			elseif y > 4 and y < endline then
				line = " " .. ("0" .. (tmp2 == 0 and get_week(31, 12, year - 1) or tmp2)):sub(-2) .. " "
				tmp2 = tmp2 + 1
				for i = 1, 7 do
					local num = (y - 5) * 7 + i - offset + 1
					line = line .. ((cur_date.day or 0) == num and (cur_date.month or 0) == month and (cur_date.year or 0) == year and "##" or (num > 0 and num <= months[month][2] and (" " .. num):sub(-2) or "  ")) .. (num < months[month][2] and i < 7 and ";" or " ")
					endline = num >= months[month][2] and y or 11
				end
			else
				line = width
			end
			term.setCursorPos(1,y)
			term.write(line)
			if y == endline + 1 then
				if y ~= h then
					h = y
					set_pos(nil, nil, w, h)
				end
				break
			end
		end
	end
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
if term.setBackgroundColor then
	term.setBackgroundColor(settings.calendar_back or 256)
end
if term.setTextColor then
	term.setTextColor(settings.calendar_text or 1)
end
draw()
while true do
	local e, d, x, y = coroutine.yield()
	if e == "mouse_click" then
		if x > 4 and x < w - 3 and y == 2 and view > 1 then
			view = view - 1
			year = view == 1 and year - year % 8 + 2 or year
			cursor[1], cursor[2] = view == 2 and -5 or -3, 1
			draw()
		elseif view == 3 then
			if x == 4 and y == 2 and not (year == 1970 and month == 1) then
				month = month == 1 and 12 or month - 1
				year = month == 12 and year - 1 or year
				draw()
			elseif x == w - 3 and y == 2 then
				month = month == 12 and 1 or month + 1
				year = month == 1 and year + 1 or year
				draw()
			end
		elseif view == 2 then
			if x == 4 and y == 2 and year > 1970 then
				year = year - 1
				draw(2, 2)
			elseif x == w - 3 and y == 2 then
				year = year + 1
				draw(2, 2)
			elseif (y == 4 or y == 6) and (x - 1) % 4 > 0 then
				month = math.ceil((x - 1) * 0.25) + (y == 6 and 6 or 0)
				view = view + 1
				draw()
			end
		elseif (y == 4 or y == 6) and (x - 2) % 5 > 0 then -- view 1
			year = year - 1 + math.ceil((x - 2) * 0.2) + (y == 6 and 4 or 0)
			view = view + 1
			draw()
		end
	elseif e == "mouse_scroll" then
		if view == 3 and not (d == -1 and year == 1970 and month == 1) then
			month = month + d
			if month == 0 then
				month = 12
				year = year - 1
			elseif month == 13 then
				month = 1
				year = year + 1
			end
			draw()
		elseif view == 2 and not (d == -1 and year == 1970) then
			year = year + d
			draw()
		elseif view == 1 and not (d == -1 and year == 1970) then
			year = year + 8 * d
			draw()
		end
	elseif e == "key" then
		d = key_maps[d] or ""
		if d == "up" and cursor[2] > 1 then
			cursor[1], cursor[2] = cursor[1] - (view == 2 and 6 or 4), cursor[2] - 1
			draw()
		elseif d == "down" and cursor[2] < 3 and view < 3 then
			cursor[1], cursor[2] = cursor[1] + (view == 2 and 6 or 4), cursor[2] + 1
			draw()
		elseif (d == "left" or d == "right") and cursor[2] == 1 then
			if view == 3 then
				month = month + (d == "left" and -1 or 1)
			elseif view == 2 then
				year = year + (d == "left" and -1 or 1)
			else
				year = year + (d == "left" and -8 or 8)
			end
			draw()
		elseif d == "enter" and cursor[2] == 1 and view > 1 then
			view = view - 1
			year = view == 1 and year - year % 8 + 2 or year
			cursor[1] = view == 2 and -5 or view == 1 and -3 or 1
			draw()
		elseif d == "enter" and cursor[2] > 1 and view < 3 then
			if view == 1 then
				year = year - 1 + cursor[1]
			else -- view == 2
				month = cursor[1]
			end
			cursor[1], cursor[2] = 1, 2
			view = view + 1
			draw()
		elseif d == "left" and (cursor[1] == 1 or cursor[1] == (view == 2 and 7 or 5)) then
			cursor[1] = view == 3 and 1 or (view == 2 and 6 or 4) * (cursor[2] - 1)
			if view == 2 then
				year = year - 1
				cursor[1] = cursor[2] == 2 and 6 or 12
			else
				year = year - 8
				cursor[1] = cursor[2] == 2 and 4 or 8
			end
			draw()
		elseif d == "left" then
			cursor[1] = view == 3 and 1 or cursor[1] - 1
			draw()
		elseif d == "right" and cursor[1] == (view == 2 and 6 or 4) * (cursor[2] - 1) then
			cursor[1] = view == 3 and 1 or (view == 2 and 6 or 4) * (cursor[2] - 2) + 1
			if view == 2 then
				year = year + 1
				cursor[1] = cursor[2] == 2 and 1 or 7
			else
				year = year + 8
				cursor[1] = cursor[2] == 2 and 1 or 5
			end
			draw()
		elseif d == "right" then
			cursor[1] = view == 3 and 1 or cursor[1] + 1
			draw()
		end
	elseif e == "term_resize" then
		draw()
	elseif a == "settings" then
		settings = b
		draw()
	end
end