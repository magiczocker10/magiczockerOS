-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- variables
local space_right_tabs = 0
local w, h = term.getSize()
local max_icons_per_row
local max_rows
local space_left
local space_right
local page
local selected = 1
local is_colored = not (not term or not term.isColor or not term.isColor())
local user = user or ""
local my_background
-- tables
local key_maps = {}
local settings = settings or {}
local pages
local windows={}
local available={}
local textbox_available=native_fs.exists("/magiczockerOS/programs/desktop/textbox_dialog.lua")
-- functions
local function back_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and textutils.complete and b or a)
	end
end
local function _max(...)
	local args = {...}
	local a = #args > 0 and tonumber(args[1]) or 0
	if type(a) ~= "number" then
		a = 0
	end
	for i = 2, #args do
		if type(args[i]) == "number" and args[i] > a then
			a = args[i]
		end
	end
	return a
end
local function position_icons()
	pages = {{}}
	if w - 1 < 7 then
		return
	end
	max_icons_per_row = floor((w - 1) / 7)
	max_rows = floor((h - 3) / 6)
	space_left = floor((w - max_icons_per_row * 7) * 0.5)
	space_right = ceil((w - max_icons_per_row * 7) * 0.5)
	local file_list = fs.exists("desktop") and fs.list("desktop") or {}
	page = 1
	local cur_x, cur_y = space_left + 1, 2
	local max_icons_per_page = max_icons_per_row * max_rows
	for i = 1, #file_list do
		local tmp = pages[#pages]
		tmp[#tmp + 1] = {name = file_list[i], x = cur_x, y = cur_y}
		cur_x = cur_x + 7
		if i % max_icons_per_row == 0 then
			cur_x = space_left + 1
			cur_y = cur_y + 6
		end
		if i % max_icons_per_page == 0 and i < #file_list then
			page = page + 1
			cur_x, cur_y = space_left + 1, 2
			pages[#pages + 1] = {}
		end
	end
	page = 1
end
local function draw()
	if magiczockerOS.contextmenu then
		magiczockerOS.contextmenu.clear_map()
		magiczockerOS.contextmenu.add_map(1,1,w,h,{{"Refresh","refresh"},{"New background","new_background"},{"New Shortcut","New Shortcut"}})
	end
	space_right_tabs = floor((w - #pages * 2 + 1) * 0.5)
	local line = 0
	local _width = (" "):rep(w)
	local s_r = (" "):rep(space_right)
	for i = 1, h do
		term.setCursorPos(1, i)
		if i == h - 1 and user ~= "" then
			back_color(32768, 256, my_background or settings.desktop_back or 2)
			term.write((" "):rep(space_right_tabs))
			for j = 1, #pages do
				if j == page then
					back_color(1, 128, 128)
				else
					back_color(1, 256, 256)
				end
				term.write" "
				if j < #pages then
					back_color(32768, 256, my_background or settings.desktop_back or 2)
					term.write" "
				end
			end
			back_color(32768, 256, my_background or settings.desktop_back or 2)
			term.write((" "):rep(ceil((w - #pages * 2 + 1) * 0.5)))
		else
			back_color(32768, 256, my_background or settings.desktop_back or 2)
			local tmp = i % 6
			if tmp == 2 then
				line = line + 1
			end
			if line <= max_rows and tmp > 1 and tmp < 5 or tmp == 0 then
				term.write((" "):rep(_max(space_left - 1, 0)))
				local __ = max_icons_per_row * (line - 1) + 1
				term.write(not is_colored and pages[page][__] and selected == __ and ">" or " ")
			end
			if line > max_rows or line > 0 and not pages[page][max_icons_per_row * (line - 1) + 1] then
				tmp = 1
			end
			if tmp == 2 then -- first icon line
				local __ = max_icons_per_row * (line - 1) + max_icons_per_row
				for j = max_icons_per_row * (line - 1) + 1, __ do
					if pages[page][j] then
						if magiczockerOS.contextmenu then
							magiczockerOS.contextmenu.add_map(pages[page][j].x, pages[page][j].y, 6, 5, {{"Open"}, {"Delete"}, {"Rename", "Rename_" .. pages[page][j].name}})
						end
						term.setBackgroundColor(1)
						text_color(1, 128, 16)
						term.write"1	    "
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						text_color(1, 1, 1)
						term.write(not is_colored and selected == j and "<" or not is_colored and j < __ and selected == j + 1 and ">" or " ")
					else
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						term.write"       "
					end
				end
			elseif tmp == 3 then -- second icon line
				local __ = max_icons_per_row * (line - 1) + max_icons_per_row
				for j = max_icons_per_row * (line - 1) + 1, max_icons_per_row * (line - 1) + max_icons_per_row do
					if pages[page][j] then
						term.setBackgroundColor(1)
						text_color(1, 128, 16)
						term.write"2	    "
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						text_color(1, 1, 1)
						term.write(not is_colored and selected == j and "<" or not is_colored and j < __ and selected == j + 1 and ">" or " ")
					else
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						term.write"       "
					end
				end
			elseif tmp == 4 then -- third icon line
				local __ = max_icons_per_row * (line - 1) + max_icons_per_row
				for j = max_icons_per_row * (line - 1) + 1, max_icons_per_row * (line - 1) + max_icons_per_row do
					if pages[page][j] then
						term.setBackgroundColor(1)
						text_color(1, 128, 16)
						term.write"3	    "
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						text_color(1, 1, 1)
						term.write(not is_colored and selected == j and "<" or not is_colored and j < __ and selected == j + 1 and ">" or " ")
					else
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						term.write"       "
					end
				end
			elseif tmp == 0 then -- file name
				local __ = max_icons_per_row * (line - 1) + max_icons_per_row
				for j = max_icons_per_row * (line - 1) + 1, max_icons_per_row * (line - 1) + max_icons_per_row do
					if pages[page][j] then
						local tmp = pages[page][j].name
						if #tmp > 6 then
							tmp = tmp:sub(1, 4) .. ".."
						end
						text_color(1, 1, 1)
						term.write((tmp .. "      "):sub(1, 6))
						text_color(1, 1, 1)
						term.write(not is_colored and selected == j and "<" or not is_colored and j < __ and selected == j + 1 and ">" or " ")
					else
						back_color(32768, 256, my_background or settings.desktop_back or 2)
						term.write"       "
					end
				end
			else
				term.write(_width)
			end
			if tmp > 1 and tmp < 5 or tmp == 0 then
				term.write(s_r)
			end
		end
	end
end
local function check_windows()
	for i=#windows,1,-1 do
		if windows[i].done then
			position_icons()
			draw()
			table.remove(windows,i)
		end
	end
end
if textbox_available then
	available["Rename"]={"textbox_dialog", "Rename"}
	available["New Shortcut"]={"textbox_dialog", "Create"}
end
-- start
do
	local a = (_HOSTver or 0) >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 262 or 205] = "right"
	key_maps[a and 263 or 203] = "left"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
position_icons()
draw()
-- events
while true do
	local e = {coroutine.yield()}
	if e[1] == "new_background" then
		check_windows()
		my_background = 2^math.random(0,15)
		draw()
	elseif e[1] == "refresh" then
		position_icons()
		draw()
	elseif e[1] == "mouse_click" and user ~= "" and e[4] == h - 1 and e[3] > space_right_tabs then
		local tmp = (e[3] - space_right_tabs + 1) * 0.5
		if pages[tmp] then
			page = tmp
			draw()
		end
	elseif e[1] == "mouse_click" and e[3] > space_left and e[4] > 1 then
		for i = 1, #pages[page] do
			if e[3] >= pages[page][i].x and e[3] < pages[page][i].x + 6 and e[4] >= pages[page][i].y and e[4] < pages[page][i].y + 5 then
				selected = i
				draw()
				create_window(pages[page][selected].name)
				break
			end
		end
	elseif e[1] == "mouse_scroll" then
		if page + e[2] > 0 and pages[page + e[2]] then
			page = page + e[2]
			if selected > #pages[page] then
				selected = #pages[page]
			end
			draw()
		end
	elseif e[1] == "key" and not is_colored and key_maps[e[2]] then
		local _key = key_maps[e[2]]
		if _key == "left" then
			if (selected - 1) % max_icons_per_row == 0 then
				if page > 1 then
					local success
					local tmp = (selected - 1) / max_icons_per_row + 1
					for j = tmp, 1, -1 do
						for i = max_icons_per_row, 1, -1 do
							if pages[page - 1][(j - 1) * max_icons_per_row + i] then
								success = true
								selected = (j - 1) * max_icons_per_row + i
								page = page - 1
								draw()
								break
							end
						end
						if success then
							break
						end
					end
				end
			elseif selected > 1 then
				selected = selected - 1
				draw()
			end
		elseif _key == "right" then
			if selected % max_icons_per_row == 0 then
				if page < #pages then
					local tmp = selected / max_icons_per_row
					for i = tmp, 1, -1 do
						if pages[page + 1][(i - 1) * max_icons_per_row + 1] then
							selected = (i - 1) * max_icons_per_row + 1
							page = page + 1
							draw()
							break
						end
					end
				end
			elseif selected < #pages[page] then
				selected = selected + 1
				draw()
			end
		elseif _key == "up" and selected > max_icons_per_row then
			selected = selected - max_icons_per_row
			draw()
		elseif _key == "down" and ceil(selected / max_icons_per_row) < ceil(#pages[page] / max_icons_per_row) then
			selected = selected + max_icons_per_row
			if selected > #pages[page] then
				selected = #pages[page]
			end
			draw()
		elseif _key == "enter" and pages[page][selected] then
			create_window(pages[page][selected].name)
		end
	elseif e[1] == "term_resize" then
		w, h = term.getSize()
		local page_old = page
		position_icons()
		page = #pages <= page_old and page_old or #pages
		draw()
	elseif e[1] == "refresh_settings" then
		settings = get_settings()
		draw()
	elseif e[1] == "user" then
		user = e[2]
		position_icons()
		draw()
	elseif e[1] then
		local a = e[1]:find("_") and e[1]:sub(1, e[1]:find("_") - 1) or e[1]
		if available[a] then
			windows[#windows+1]={data=false, title = a, mode = a, other = available[a], file = e[1]:sub(#a+2)}
			create_window("/magiczockerOS/programs/desktop/"..available[a][1]..".lua",true,windows[#windows])
		end
	elseif not e[1] then
		error"D:"
	end
end