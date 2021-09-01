-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local search = fs.exists("/magiczockerOS/programs/search.lua")
local calendar = fs.exists("/magiczockerOS/programs/calendar.lua")
local offset, line, time, user, front, list, window_pos, procs, settings, cur_settings = 0, "", "", user or "", {}, {}, {}, {}, user_data().settings or {}, {}
local u_data, events, w
local cs = cur_settings
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function update_cached_settings()
	cs.cba = get_setting(settings, "clock_back_active")
	cs.cbi = get_setting(settings, "clock_back_inactive")
	cs.cf = get_setting(settings, "clock_format")
	cs.cta = get_setting(settings, "clock_text_active")
	cs.cti = get_setting(settings, "clock_text_inactive")
	cs.cv = get_setting(settings, "clock_visible")
	cs.sebab = get_setting(settings, "search_button_active_back")
	cs.sebat = get_setting(settings, "search_button_active_text")
	cs.sebib = get_setting(settings, "search_button_inactive_back")
	cs.sebit = get_setting(settings, "search_button_inactive_text")
	cs.stbab = get_setting(settings, "startmenu_button_active_back")
	cs.stbat = get_setting(settings, "startmenu_button_active_text")
	cs.stbib = get_setting(settings, "startmenu_button_inactive_back")
	cs.stbit = get_setting(settings, "startmenu_button_inactive_text")
	cs.tb = get_setting(settings, "taskbar_back")
	cs.tiab = get_setting(settings, "taskbar_items_active_back")
	cs.tiat = get_setting(settings, "taskbar_items_active_text")
	cs.tiib = get_setting(settings, "taskbar_items_inactive_back")
	cs.tiit = get_setting(settings, "taskbar_items_inactive_text")
end
local function get_time()
	if cs.cv and (os.time or os.date) then
		local c_f = cs.cf
		if os.date then
			return os.date(" %" .. (c_f and "H" or "I") .. ":%M" .. (c_f and "" or " %p") .. " ")
		else
			local a = nil
			local b = os.time()
			if not c_f then
				a = b > 11 and "PM" or "AM"
				if b >= 13 then
					b = b - 12
				end
			end
			local hour = "0" .. math.floor(b)
			local minute = "0" .. math.floor((b - hour) * 60)
			local tmp = not term.isColor and (get_visible("calendar") and "-" or "_") or " "
			return tmp .. hour:sub(-2) .. ":" .. minute:sub(-2) .. "" .. (a and " " .. a or "") .. tmp
		end
	else
		return ""
	end
end
local function get_proc_vis(a)
	return procs[a] and not procs[a].is_dead and procs[a].window.get_visible() or false
end
local function create_proc(a, b)
	if procs[a] and not procs[a].is_dead then
		return nil
	end
	local f = apis.window.get_global_visible()
	apis.window.set_global_visible(false)
	create_window(b, true)
	procs[a] = user_data().windows[1]
	local e = procs[a].buttons
	table.remove(e, 1)
	procs[a].is_system = true
	procs[a].auto_kill = true
	if a == "startmenu" or a == "search" then
		procs[a].window.set_header_vis(false)
		procs[a].click_outside = true
	elseif a == "calendar" then
		procs[a].window.set_header_vis(false)
		procs[a].click_outside = true
		procs[a].env.set_pos(w - 24, 2, nil, nil, true)
		procs[a].env.os.queueEvent("term_resize")
	end
	apis.window.set_global_visible(f)
	if a == "search" or a == "calendar" then
		set_pos()
	end
end
local function draw_start()
	term.setCursorPos(1, 1)
	if get_proc_vis("startmenu") then
		back_color(32768, 256, cs.stbab)
		text_color(1, 1, cs.stbat)
	else
		back_color(1, 128, cs.stbib)
		text_color(32768, 1, cs.stbit)
	end
	term.write(not term.isColor and (get_proc_vis("startmenu") and "-m-" or "_m_") or " m ")
end
local function draw_search()
	if user ~= "" and search then
		term.setCursorPos(w - 2, 1)
		if get_proc_vis("search") then
			back_color(32768, 256, cs.sebab)
			text_color(1, 1, cs.sebat)
		else
			back_color(1, 128, cs.sebib)
			text_color(32768, 1, cs.sebit)
		end
		term.write(not term.isColor and (get_proc_vis("search") and "-S-" or "_S_") or " S ")
	end
end
local function draw_items()
	term.setCursorPos(4, 1)
	local tmp = w
	if not search then
		w = w + 3
	end
	local a = line:sub(1 + offset, w - #time - 3 - (user == "" and 0 or 3) + offset)
	local b = a
	local c = false -- inject
	local d = 0 -- start
	if front.pos then
		for i = front.offset - offset + 1, front.offset - offset + #list[front.pos].name + 2 do
			if i > 0 then
				d = 0 and i or d
				a = a:sub(1, i - 1) .. "\t" .. a:sub(i + 1, #a)
				c = true
			end
		end
	end
	if c then
		back_color(1, 128, cs.tiib)
		text_color(32768, 1, cs.tiit)
		term.write(a:sub(1, a:find("\t") - 1))
		back_color(32768, 256, cs.tiab)
		text_color(1, 1, cs.tiat)
		local found = a:find("\t")
		local last = found
		while found do
			term.write(b:sub(found, found))
			found = a:find("\t", found + 1)
			if found then
				last = found
			end
		end
		back_color(1, 128, cs.tiib)
		text_color(32768, 1, cs.tiit)
		term.write(a:sub(last + 1, #a))
	else
		back_color(1, 128, cs.tiib)
		text_color(32768, 1, cs.tiit)
		term.write(a)
	end
	if ({term.getCursorPos()})[1] < w - (user == "" and -1 or 2) - #time then
		back_color(1, 128, cs.tb)
		local e = w - (user == "" and -1 or 2) - #time - ({term.getCursorPos()})[1]
		local f = (" "):rep(e)
		term.write(not term.isColor and ("_"):rep(e) or f)
	end
	w = tmp
end
local function set_items()
	local a = user_data()
	a = a.windows and a.windows[1] or nil -- upper_window
	list, line, front, window_pos = user_data().labels, "", {}, {}
	if a then
		local _width = w - #time - 3 - ((not search or user == "") and 0 or 3)
		local b = 0 -- cursor
		for i = 1, #list do
			if list[i].id ~= (procs.search and procs.search.id or -1) and list[i].id ~= (procs.startmenu and procs.startmenu.id or -1) and list[i].id ~= (procs.calendar and procs.calendar.id or -1) then
				if not term.isColor then
					line = line .. "_" .. list[i].name .. "_"
				else
					line = line .. " " .. list[i].name .. " "
				end
				if list[i].id == a.id and a.window.get_visible() then
					front.offset = b
					front.pos = i
					if offset > b then
						offset = b
					elseif #line - offset > _width then
						offset = #line - _width
					end
				end
				for _ = 1, #list[i].name + 2 do
					window_pos[#window_pos + 1] = list[i].id
				end
				b = b + #list[i].name + 2
			end
		end
		if offset > 0 and #line - offset < _width then
			offset = #line - _width
		end
		if offset < 0 then
			offset = 0
		end
	end
	draw_items()
end
local function draw_clock()
	time = get_time()
	if cs.cv then
		if get_proc_vis("calendar") then
			back_color(32768, 256, cs.cba)
			text_color(1, 32768, cs.cta)
		else
			back_color(1, 128, cs.cbi)
			text_color(32768, 1, cs.cti)
		end
		term.setCursorPos(w + 1 - #time - ((not search or user == "") and 0 or 3), 1)
		term.write(time)
	end
end
local function set_vis(ign)
	if ign == "se" then
		create_proc("search", "/magiczockerOS/programs/search.lua")
	elseif ign == "sm" then
		create_proc("startmenu", "/magiczockerOS/programs/startmenu.lua")
	elseif ign == "ca" then
		create_proc("calendar", "/magiczockerOS/programs/calendar.lua")
	end
	if get_visible("contextmenu") and ign ~= "cm" then
		set_visible("contextmenu", false)
	end
	if get_proc_vis("startmenu") and ign ~= "sm" then
		events("mouse_click", 1, 1, 1)
	end
	if get_visible("calendar") and ign ~= "ca" then
		events("mouse_click", 1, w - 1 - (user == "" and -1 or 2) + (search and 0 or 3), 1)
	end
end
local function switch_visible(id, state)
	local uData = user_data()
	uData.desktop = {}
	for i = 1, #uData.windows do
		if uData.windows[i].id == id then
			local temp_window = uData.windows[i]
			local visible = not temp_window.window.get_visible()
			if type(state) == "boolean" then
				visible = state
			end
			table.remove(uData.windows, i)
			table.insert(uData.windows, visible and 1 or #uData.windows + 1, temp_window)
			temp_window.window.set_visible(visible)
			break
		end
	end
	set_pos()
end
local function send_event(a, ...)
	if procs[a] and not procs[a].is_dead then
		procs[a].env.os.queueEvent(...)
	end
end
local function toggle(a)
	local b = not procs[a] or procs[a].is_dead
	set_vis(a == "startmenu" and "sm" or a == "calendar" and "ca" or "se")
	if not b then
		local c = user_data()
		local d = c.desktop
		switch_visible(procs[a].id, not procs[a].window.get_visible())
		c.desktop = d
	end
end
function events(a, b, c)
	if a == "user" or a == "refresh_settings" then
		local u_data_old = u_data
		if a == "user" then
			u_data = user_data()
			if u_data_old and u_data ~= u_data_old then
				for i = #u_data_old.windows, 1, -1 do
					local v = u_data_old.windows[i]
					if v.is_system and (procs.search == v or procs.startmenu == v or procs.calendar == v) then
						v.window.set_visible(false)
						v.window.drawable(true)
						u_data.windows[#u_data.windows + 1] = v
						table.remove(u_data_old.windows, i)
						v.env.set_user(b)
						v.env.os.queueEvent("user", b)
					end
				end
			end
			user = u_data.name
		else
			settings = u_data.settings or {}
			update_cached_settings()
			send_event("calendar", a)
			send_event("search", a)
			send_event("startmenu", a)
		end
		draw_clock()
		draw_start()
		draw_items()
		draw_search()
	elseif a == "mouse_click" then
		if c < 4 then -- open/close startmenu
			if get_proc_vis("calendar") then
				toggle("calendar")
				draw_clock()
			end
			toggle("startmenu")
			draw_start()
			set_items()
		elseif search and user ~= "" and c > w - 3 then -- open/close search
			toggle("search")
			draw_search()
		elseif calendar and user ~= "" and c >= w - (user == "" and -1 or 2) - #time + (search and 0 or 3) and c < w - (user == "" and -1 or 2) + (search and 0 or 3) then -- open/close calendar
			if get_proc_vis("startmenu") then
				toggle("startmenu")
				draw_start()
			end
			toggle("calendar")
			draw_clock()
			set_items()
		elseif b == 1 or b == 3 then -- taskbar entries
			if b == 1 then -- left
				switch_visible(window_pos[c - 3 + offset])
			else -- middle
				local id = window_pos[c - 3 + offset]
				local uData = user_data()
				uData.desktop = {}
				local has_close = false
				for i = 1, #uData.windows do
					if uData.windows[i].id == id then
						has_close = uData.windows[i].window.get_button("close") and true or false
						if has_close then
							table.remove(uData.windows, i)
						end
						break
					end
				end
				local tmp = uData.labels
				for i = 1, #tmp do
					if tmp[i].id == id then
						if has_close then
							table.remove(tmp, i)
						end
						break
					end
				end
				set_pos() -- force's the core to redraw the windows
			end
			set_items()
			set_vis()
		end
	elseif a == "mouse_scroll" then
		if c > 3 and c <= w - #time - (search and 3 or 0) then
			if b == -1 and offset > 0 then
				offset = offset - 1
			elseif b == 1 and #line > w - #time - 3 + offset then
				offset = offset + 1
			end
			draw_items()
		end
	elseif a == "switch_start" then
		events("mouse_click", 1, 1, 1)
	elseif a == "switch_calendar" then
		events("mouse_click", 1, w - 1 - (user == "" and -1 or 2) + (search and 0 or 3), 1)
	elseif a == "switch_search" and search then
		events("mouse_click", 1, w, 1)
	elseif a == "window_change" or a == "start_change" then
		draw_start()
		set_items()
		draw_clock()
		draw_search()
	elseif a == "os_time" then
		events("window_change")
	elseif a == "term_resize" then
		w = term.getSize()
		if procs.calendar then
			procs.calendar.env.set_pos(w - 24, nil, nil, nil, true)
		end
		draw_start()
		set_items()
		draw_search()
	end
end
update_cached_settings()
events("term_resize")
while true do
	events(coroutine.yield())
end
