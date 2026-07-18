-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- Define global variables as local
local cy = coroutine.yield
local fe = fs.exists
local mc, mf = math.ceil, math.floor
local tb, tc, tt, tw = term.setBackgroundColor or function() end, term.setCursorPos, term.setTextColor or function() end, term.write

-- Variables
local my_win = user_data().windows[1]
local bw = term and term.isColor and (term.isColor() and 3 or (_VERSION):match('^Lua%s') and 2 or 1) or 0
local cursor, menu, sb, sia, st, w
local km = {}

-- Functions
local function draw()
	for k, v in next, menu do
		v = v[1]
		tc( 1, k )
		if v == '' then
			tw( (' %s '):format(
				('-'):rep( w - 2 )
			) )
		else
			if bw > 0 and bw < 3 and cursor == k then
				tb( ( { 1, 128, sb } )[ bw ] )
				tt( ( { 32768, 1, st } )[ bw ] )
				tw( ('%s%s%s%s%s'):format(
					' ',
					sia == 'right' and (' '):rep( w - #v - 2 ) or sia == 'left' and '' or (' '):rep( mf( (w - #v - 2) * 0.5 ) ),
					v,
					sia == 'left' and (' '):rep( w - #v - 2 ) or sia == 'right' and '' or (' '):rep( mc( (w - #v - 2) * 0.5 ) ),
					' '
				) )
				tb( ( { 32768, 256, sb } )[ bw ] )
				tt( ( { 1, 1, st } )[ bw ] )
			else
				tw( ('%s%s%s%s%s'):format(
					bw < 3 and cursor == k and '>' or ' ',
					sia == 'right' and (' '):rep( w - #v - 2 ) or sia == 'left' and '' or (' '):rep( mf( (w - #v - 2) * 0.5 ) ),
					v,
					sia == 'left' and (' '):rep( w - #v - 2 ) or sia == 'right' and '' or (' '):rep( mc( (w - #v - 2) * 0.5 ) ),
					bw < 3 and cursor == k and '<' or ' '
				) )
			end
		end
	end
end
local function add(a, b)
	menu[ #menu + 1 ] = { a, b or function() end }
	if #a > w then
		w = #a
	end
end
local function set_my_vis(a)
	if my_win.window.get_visible() == a then return nil end
	my_win.window.set_visible(a)
	local b = user_data().windows
	for k, v in next, b do
		if my_win == v then
			local tmp = v
			table.remove(b, k)
			table.insert(b, a and 1 or #b + 1, tmp)
		end
	end
end
local function create( user )
	cursor = 1
	menu = {}
	w = 1
	if user ~= '' then
		add( 'CraftOS', function() close_os() end)
		if fe('/magiczockerOS/programs/settings.lua') then
			add( 'Settings', function() set_my_vis(false) create_window('/magiczockerOS/programs/settings.lua', true) end )
		end
		if fe('/magiczockerOS/programs/settings-new.lua') then
			add( 'Settings New', function() set_my_vis(false) create_window('/magiczockerOS/programs/settings-new.lua', true) end )
		end
		local shellPath = fs.exists( '/rom/programs/shell.lua' ) and '/rom/programs/shell.lua' or '/rom/programs/shell'
		add( 'Shell', function() set_my_vis(false) create_window() end)
		add( 'Show Desktop', function() show_desktop() end)
		add( '' )
	end
	if fe('/magiczockerOS/programs/login.lua') and user ~= '' then
		add( 'Sign out', function() switch_user(true, '') end )
		add( 'Switch User', function() switch_user(false, '') end )
		add( '' )
	end
	if fe('/magiczockerOS/programs/osk.lua') then
		add( 'Keyboard', function() set_my_vis(false) set_visible('osk', not get_visible('osk')) end )
		add( '' )
	end
	if os.reboot then
		add( 'Reboot', os.reboot )
	end
	add( 'Shutdown', os.shutdown )
	w = w + 2
	set_pos(1, 2, w, #menu)
	draw()
end
local function show_desktop() -- need rework
	term.setVisible(false)
	local uData = user_data()
	if #uData.windows > 0 then
		local tmpd = uData.desktop
		if #tmpd == 0 then
			local a
			for _, v in next, uData.windows do
				a = v.window
				if a.get_visible() then
					a.set_visible(false)
					tmpd[#tmpd + 1] = a.set_visible
				end
			end
		else
			for k, v in next, tmpd do
				v(true)
			end
			uData.desktop = {}
		end
	end
	magicOS.set_visible('taskbar', true)
end

-- Events
local function events(e, d, _, y)
	if e == 'mouse_click' and d == 1 then
		menu[y][2]()
	elseif e == 'key' and km[d] and bw < 3 then
		if km[d] == 'enter' then
			menu[cursor][2]()
		elseif km[d] == 'up' then
			cursor = cursor == 1 and #menu or cursor - 1
			if menu[cursor][1] == '' then
				events(e, d)
			end
		elseif km[d] == 'down' then
			cursor = cursor == #menu and 1 or cursor + 1
			if menu[cursor][1] == '' then
				events(e, d)
			end
		end
		draw()
	elseif e == 'user' then
		create( user_data().name )
	elseif e == 'term_resize' then
		draw()
	elseif e == 'refresh_settings' then
		sb, sia, st = tonumber( d.startmenu_back or '256' ), d.startmenu_items_align or 'left', tonumber( d.startmenu_text or '1' )
		tb( ( { 32768, 256, sb } )[ bw ] )
		tt( ( { 1, 1, st } )[ bw ] )
		draw()
	end
end
do
	local a = (_HOSTver or 0) >= 1132
	km[a and 257 or 28] = 'enter'
	km[a and 264 or 208] = 'down'
	km[a and 265 or 200] = 'up'
end
events( 'user', '' )
events( 'refresh_settings', {} )
while true do
	events( cy() )
end
