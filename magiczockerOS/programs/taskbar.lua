-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local search = fs.exists("/magiczockerOS/programs/search.lua")
-- numbers
local w=term.getSize()
local B=0 -- offset
-- strings
local A="" -- line
local D="" -- time
local E=user or "" -- user
-- tables
local F={} -- front
local G={} -- list
local H=settings or {} -- settings
local I={} -- window_pos
-- functions
local function back_color(a,b,c)
	if term.isColor then
		term.setBackgroundColor((term.isColor() and c) or (type(textutils.complete) == "function" and b) or a)
	end
end
local function text_color(a,b,c)
	if term.isColor then
		term.setTextColor((term.isColor() and c) or (type(textutils.complete) == "function" and b) or a)
	end
end
local function write_text(a,b,c,d)
	term.write((not term.isColor and a) or (term.isColor() and d) or (textutils and type(textutils.complete) == "function" and c) or b)
end
local function get_time()
	if H.clock_visible and (os.time or os.date) then
		if os.date then
			return os.date(" %"..(H.clock_format and "H" or "I")..":%M"..(H.clock_format and "" or " %p").." ")
		else
			local a=nil
			local b=os.time()
			if not H.clock_format then
				a=b>11 and "PM" or "AM"
				if b>=13 then
					b=b-12
				end
			end
			local hour="0"..floor(b)
			local minute="0"..floor((b-hour)*60)
			local tmp = (not term.isColor and (get_visible("calendar") and "-" or "_") or " ")
			return tmp..hour:sub(-2)..":"..minute:sub(-2)..""..(a and " "..a or "")..tmp
		end
	else
		return ""
	end
end
local function draw_start()
	term.setCursorPos(1,1)
	if get_visible("startmenu") then
		back_color(32768,256,H.startmenu_button_active_back or 256)
		text_color(1,1,H.startmenu_button_active_text or 1)
		write_text("-m-"," m "," m "," m ")
	else
		back_color(1,128,H.startmenu_button_inactive_back or 128)
		text_color(32768,1,H.startmenu_button_inactive_text or 1)
		write_text("_m_"," m "," m "," m ")
	end
end
local function draw_search()
	if E~="" and search then
		term.setCursorPos(w-2,1)
		if get_visible("search") then
			back_color(32768,256,H.search_button_active_back or 256)
			text_color(1,1,H.search_button_active_text or 1)
			write_text("-S-"," S "," S "," S ")
		else
			back_color(1,128,H.search_button_inactive_back or 128)
			text_color(32768,1,H.search_button_inactive_text or 1)
			write_text("_S_"," S "," S "," S ")
		end
	end
end
local function draw_items()
	term.setCursorPos(4,1)
	local tmp = w
	if not search then
		w = w + 3
	end
	local a=A:sub(1+B,w-#D-3-(E == "" and 0 or 3)+B)
	local b=A:sub(1+B,w-#D-3-(E == "" and 0 or 3)+B)
	local c=false -- inject
	local d=0 -- start
	if F.pos then
		for i=F.B-B+1,F.B-B+#G[F.pos].name+2 do
			if i>0 then
				d=0 and i or d
				a=a:sub(1,i-1).."\t"..a:sub(i+1,#a)
				c=true
			end
		end
	end
	if c then
		back_color(1,128,H.taskbar_items_inactive_back or 128)
		text_color(32768,1,H.taskbar_items_inactive_text or 1)
		term.write(a:sub(1,a:find("\t")-1))
		back_color(32768,256,H.taskbar_items_active_back or 256)
		text_color(1,1,H.taskbar_items_active_text or 1)
		local found=a:find("\t")
		local last=found
		while found do
			term.write(b:sub(found,found))
			found=a:find("\t",found+1)
			if found then
				last=found
			end
		end
		back_color(1,128,H.taskbar_items_inactive_back or 128)
		text_color(32768,1,H.taskbar_items_inactive_text or 1)
		term.write(a:sub(last+1,#a))
	else
		back_color(1,128,H.taskbar_items_inactive_back or 128)
		text_color(32768,1,H.taskbar_items_inactive_text or 1)
		term.write(a)
	end
	if ({term.getCursorPos()})[1]<w-(E == "" and (-1) or 2)-#D then
		back_color(1,128,H.taskbar_back or 128)
		local e=w-(E == "" and (-1) or 2)-#D-({term.getCursorPos()})[1]
		local f=(" "):rep(e)
		write_text(("_"):rep(e),f,f,f)
	end
	w = tmp
end
local function set_items()
	local a=get_top_window() -- upper_window
	G=get_label()
	A=""
	F={}
	I={}
	if a then
		local _width=w-#D-3-((not search or E == "") and 0 or 3)
		local b=0 -- cursor
		for i=1,#G do
			if not term.isColor then
				A=A.."_"..G[i].name.."_"
			else
				A=A.." "..G[i].name.." "
			end
			if G[i].id == a.id and a.window.get_visible() then
				F.B=b
				F.pos=i
				if B>b then
					B=b
				elseif #A-B>_width then
					B = #A-_width
				end
			end
			for j=1,#G[i].name+2 do
				I[#I+1]=G[i].id
			end
			b=b+#G[i].name+2
		end
		if B>0 and #A-B<_width then
			B=#A-_width
		end
		if B<0 then
			B=0
		end
	end
	draw_items()
end
local function draw_clock()
	D=get_time()
	if H.clock_visible then
		if get_visible("calendar") then
			back_color(32768,256,H.clock_back_active or 256)
			text_color(1,32768,H.clock_text_active or 1)
		else
			back_color(1,128,H.clock_back_inactive or 128)
			text_color(32768,1,H.clock_text_inactive or 1)
		end
		term.setCursorPos(w+1-#D-((not search or E == "") and 0 or 3),1)
		term.write(D)
	end
end
local function set_vis(ign)
	if get_visible("contextmenu") and ign~="cm" then
		set_visible("contextmenu",false)
	end
	if get_visible("startmenu") and ign~="sm" then
		set_visible("startmenu",false)
		draw_start()
	end
	if get_visible("calendar") and ign~="ca" then
		set_visible("calendar",false)
		draw_clock()
	end
	if get_visible("search") and ign~="se" then
		set_visible("search",false)
		draw_search()
	end
end
-- start
draw_start()
set_items()
draw_search()
-- events
while true do
	local a,b,c,d=coroutine.yield()
	if a == "user" or a == "refresh_settings" then
		if a == "user" then
			E = user_data().name
		else
			H = get_settings()
			if type(H.clock_visible) == "nil" then
				H.clock_visible=true
			end
		end
		draw_clock()
		draw_start()
		draw_items()
		draw_search()
	elseif a == "mouse_click" then
		if c<4 and d == 1 then -- open/close start menu
			set_vis("sm")
			set_visible("startmenu",not get_visible("startmenu"))
			draw_start()
		elseif E~="" and c>=(w-(E == "" and (-1) or 2)-#D)+(search and 0 or 3) and c<(w-(E == "" and (-1) or 2))+(search and 0 or 3) and d == 1 then -- open/close calendar
			set_vis("ca")
			set_visible("calendar",not get_visible("calendar"))
			draw_clock()
		elseif search and E~="" and c>w-3 and d == 1 then -- open/close search
			set_vis("se")
			set_visible("search",not get_visible("search"))
			draw_search()
		elseif b == 1 or b == 3 then -- taskbar entries
			if b == 1 then -- left
				switch_visible(I[c-3+B])
			else -- middle
				close_window(I[c-3+B])
			end
			set_items()
			set_vis()
		end
	elseif a == "mouse_scroll" then
		if c>3 and c<=w-#D-(search and 3 or 0) then
			if b == -1 and B>0 then
				B=B-1
			elseif b == 1 and #A>w-#D-3+B then
				B=B+1
			end
			draw_items()
		end
	elseif a == "start_change" then
		draw_start()
	elseif a == "search_change" then
		draw_search()
	elseif a == "calendar_change" then
		draw_clock()
	elseif a == "window_change" then
		draw_start()
		set_items()
		draw_search()
	elseif a == "os_time" then
		draw_clock()
	elseif a == "term_resize" then
		w=term.getSize()
		draw_start()
		set_items()
		draw_search()
	end
end