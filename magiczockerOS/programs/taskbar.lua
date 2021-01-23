-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local search = fs.exists("/magiczockerOS/programs/search.lua")
local calendar = fs.exists("/magiczockerOS/programs/calendar.lua")
-- numbers
local w = term.getSize()
local offset = 0
-- strings
local line = ""
local time = ""
local user = user or ""
local _min = math.min
-- tables
local front = {}
local list = {}
local settings = user_data().settings or {}
local window_pos = {}
local procs = {}
local u_data
local events
-- functions
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function get_time()
	if settings.clock_visible and (os.time or os.date) then
		if os.date then
			return os.date(" %"..(settings.clock_format and "H" or "I")..":%M"..(settings.clock_format and "" or " %p").." ")
		else
			local a=nil
			local b=os.time()
			if not settings.clock_format then
				a=b>11 and "PM" or "AM"
				if b>=13 then
					b=b-12
				end
			end
			local hour="0"..math.floor(b)
			local minute="0"..math.floor((b-hour)*60)
			local tmp = (not term.isColor and (get_visible("calendar") and "-" or "_") or " ")
			return tmp..hour:sub(-2)..":"..minute:sub(-2)..""..(a and " "..a or "")..tmp
		end
	else
		return ""
	end
end
local function get_proc_vis(a)
	return procs[a] and not procs[a].is_dead and procs[a].window.get_visible() or false
end
local function create_proc(a, b)
	if not (not procs[a] or procs[a].is_dead) then
		return nil
	end
	local f = apis.window.get_global_visible()
	apis.window.set_global_visible(false)
	create_window(b, true)
	procs[a] = user_data().windows[1]
	local e = procs[a].window.get_buttons()
	table.remove(e, 1)
	procs[a].window.set_buttons(e, true)
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
	term.setCursorPos(1,1)
	if get_proc_vis("startmenu") then
		back_color(32768,256,settings.startmenu_button_active_back or 256)
		text_color(1,1,settings.startmenu_button_active_text or 1)
	else
		back_color(1,128,settings.startmenu_button_inactive_back or 128)
		text_color(32768,1,settings.startmenu_button_inactive_text or 1)
	end
	term.write((not term.isColor and (get_proc_vis("startmenu") and "-m-" or "_m_")) or " m ")
end
local function draw_search()
	if user~="" and search then
		term.setCursorPos(w-2,1)
		if get_proc_vis("search") then
			back_color(32768,256,settings.search_button_active_back or 256)
			text_color(1,1,settings.search_button_active_text or 1)
		else
			back_color(1,128,settings.search_button_inactive_back or 128)
			text_color(32768,1,settings.search_button_inactive_text or 1)
		end
		term.write((not term.isColor and (get_proc_vis("search") and "-S-" or "_S_")) or " S ")
	end
end
local function draw_items()
	term.setCursorPos(4,1)
	local tmp = w
	if not search then
		w = w + 3
	end
	local a=line:sub(1+offset,w-#time-3-(user == "" and 0 or 3)+offset)
	local b=a
	local c=false -- inject
	local d=0 -- start
	if front.pos then
		for i=front.offset-offset+1,front.offset-offset+#list[front.pos].name+2 do
			if i>0 then
				d=0 and i or d
				a=a:sub(1,i-1).."\t"..a:sub(i+1,#a)
				c=true
			end
		end
	end
	if c then
		back_color(1,128,settings.taskbar_items_inactive_back or 128)
		text_color(32768,1,settings.taskbar_items_inactive_text or 1)
		term.write(a:sub(1,a:find("\t")-1))
		back_color(32768,256,settings.taskbar_items_active_back or 256)
		text_color(1,1,settings.taskbar_items_active_text or 1)
		local found=a:find("\t")
		local last=found
		while found do
			term.write(b:sub(found,found))
			found=a:find("\t",found+1)
			if found then
				last=found
			end
		end
		back_color(1,128,settings.taskbar_items_inactive_back or 128)
		text_color(32768,1,settings.taskbar_items_inactive_text or 1)
		term.write(a:sub(last+1,#a))
	else
		back_color(1,128,settings.taskbar_items_inactive_back or 128)
		text_color(32768,1,settings.taskbar_items_inactive_text or 1)
		term.write(a)
	end
	if ({term.getCursorPos()})[1]<w-(user == "" and (-1) or 2)-#time then
		back_color(1,128,settings.taskbar_back or 128)
		local e=w-(user == "" and (-1) or 2)-#time-({term.getCursorPos()})[1]
		local f=(" "):rep(e)
		term.write(not term.isColor and ("_"):rep(e) or f)
	end
	w = tmp
end
local function set_items()
	local a=user_data()
	a = a.windows and a.windows[1] or nil -- upper_window
	list=user_data().labels
	line=""
	front={}
	window_pos={}
	if a then
		local _width=w-#time-3-((not search or user == "") and 0 or 3)
		local b=0 -- cursor
		for i=1,#list do
			if list[i].id ~= (procs["search"] and procs["search"].id or -1) and list[i].id ~= (procs["startmenu"] and procs["startmenu"].id or -1) and list[i].id ~= (procs["calendar"] and procs["calendar"].id or -1) then
				if not term.isColor then
					line=line.."_"..list[i].name.."_"
				else
					line=line.." "..list[i].name.." "
				end
				if list[i].id == a.id and a.window.get_visible() then
					front.offset=b
					front.pos=i
					if offset>b then
						offset=b
					elseif #line-offset>_width then
						offset = #line-_width
					end
				end
				for j=1,#list[i].name+2 do
					window_pos[#window_pos+1]=list[i].id
				end
				b=b+#list[i].name+2
			end
		end
		if offset>0 and #line-offset<_width then
			offset=#line-_width
		end
		if offset<0 then
			offset=0
		end
	end
	draw_items()
end
local function draw_clock()
	time=get_time()
	if settings.clock_visible then
		if get_proc_vis("calendar") then
			back_color(32768,256,settings.clock_back_active or 256)
			text_color(1,32768,settings.clock_text_active or 1)
		else
			back_color(1,128,settings.clock_back_inactive or 128)
			text_color(32768,1,settings.clock_text_inactive or 1)
		end
		term.setCursorPos(w+1-#time-((not search or user == "") and 0 or 3),1)
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
		set_visible("contextmenu",false)
	end
	if get_proc_vis("startmenu") and ign ~= "sm" then
		events("mouse_click", 1, 1, 1)
	end
	if get_visible("calendar") and ign ~= "ca" then
		events("mouse_click", 1, (w - 1 - (user == "" and -1 or 2)) + (search and 0 or 3), 1)
	end
end
local function switch_visible(id, state)
	local uData = user_data()
	uData.desktop = {}
	for i = 1, #uData.windows do
		if uData.windows[i].id == id then
			local temp_window = uData.windows[i]
			local visible = not temp_window.window.get_visible()
			table.remove(uData.windows, i)
			table.insert(uData.windows, visible and 1 or #uData.windows + 1, temp_window)
			temp_window.window.set_visible(visible)
			break
		end
	end
	set_pos()
end
local function toggle(a)
	local b = not procs[a] or procs[a].is_dead
	set_vis(a == "startmenu" and "sm" or a == "calendar" and "ca" or "se")
	if not b then
		switch_visible(procs[a].id, not procs[a].window.get_visible())
	end
end
-- start
draw_start()
set_items()
draw_search()
-- events
function events(a, b, c)
	if a == "user" or a == "refresh_settings" then
		local u_data_old = u_data
		if a == "user" then
			u_data = user_data()
			if u_data_old and u_data ~= u_data_old then
				for i = #u_data_old.windows, 1, -1 do
					local v = u_data_old.windows[i]
					if v.is_system and (procs["search"] == v or procs["startmenu"] == v or procs["calendar"] == v) then
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
			if settings.clock_visible == nil then
				settings.clock_visible = true
			end
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
		elseif calendar and user ~= "" and c >= (w - (user == "" and -1 or 2) - #time) + (search and 0 or 3) and c < (w - (user == "" and -1 or 2)) + (search and 0 or 3) then -- open/close calendar
			if get_proc_vis("startmenu") then
				toggle("startmenu")
				draw_start()
			end
			toggle("calendar")
			draw_clock()
			set_items()
		elseif search and user ~= "" and c > w - 3 then -- open/close search
			toggle("search")
			draw_search()
		elseif b == 1 or b == 3 then -- taskbar entries
			if b == 1 then -- left
				switch_visible(window_pos[c-3+offset])
			else -- middle
				local id = window_pos[c-3+offset]
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
		events("mouse_click", 1, (w - 1 - (user == "" and -1 or 2)) + (search and 0 or 3), 1)
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
		w=term.getSize()
		if procs["calendar"] then
			procs["calendar"].env.set_pos(w - 24, nil, nil, nil, true)
		end
		draw_start()
		set_items()
		draw_search()
	end
end
while true do
	events(coroutine.yield())
end