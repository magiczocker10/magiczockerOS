-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- Define global variables as local
local coroutine_yield = coroutine.yield
local fs_exists = fs.exists
local math_ceil, math_floor = math.ceil, math.floor
local os_reboot, os_shutdown = os.reboot, os.shutdown
local term_setBackgroundColor, term_setCursorPos, term_setTextColor, term_write = term.setBackgroundColor or function() end, term.setCursorPos, term.setTextColor or function() end, term.write

-- Variables
local bw = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local cursor = 1
local key_maps = {}
local menu = { {}, {} }
local mode = 1
local my_win = user_data().windows[1]
local item_align = 1
local width = 1

-- Functions
local function create(a, b, c, d)
	if term.isColor and term.isColor() or a then
		if b then
			menu[1][#menu[1] + 1] = {c, d}
		end
		menu[2][#menu[2] + 1] = {c, d}
	end
end
local function back_color(...)
	term_setBackgroundColor( ({...})[bw] )
end
local function text_color(...)
	term_setTextColor( ({...})[bw] )
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
local function draw()
	for k, v in next, menu[mode] do
		local a, b, c = v[1], item_align, cursor == k and bw < 3 and '-' or ' '
		local d = (width - #a) * 0.5
		term_setCursorPos(1, k)
		term_write(c .. (a == '' and ( '-' ):rep( width - 2 ) or b == 2 and ( ' ' ):rep( math_floor(d) - 1 ) .. a .. ( ' ' ):rep( math_ceil(d) - 1 ) or b == 3 and ( ' ' ):rep( width - #a - 2 ) .. a or a .. ( ' ' ):rep( width - #a - 2 )) .. c)
	end
end
local function size()
	width = 1
	for _, v in next, menu[mode] do
		local a = v[1]
		width = #a > width and #a or width
	end
	width = width + 2
	set_pos(1, 2, width, #menu[mode])
end
local function show_desktop()
	set_my_vis(false)
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
	set_visible('taskbar', true)
end
create(true, false, 'CraftOS', function() close_os() end)
if fs_exists('/magiczockerOS/programs/settings.lua') then
	create(true, false, 'Settings', function() set_my_vis(false) create_window('/magiczockerOS/programs/settings.lua', true) end)
	create(true, false, 'Settings New', function() set_my_vis(false) create_window('/magiczockerOS/programs/settings-new.lua', true) end)
end
create(true, false, 'Shell', function() set_my_vis(false) create_window() end)
create(true, false, 'Show Desktop', function() show_desktop() end)
create(true, false, '', function() end)
if fs_exists('/magiczockerOS/programs/login.lua') then
	create(true, false, 'Sign out', function() switch_user(true, '') end)
	create(true, false, 'Switch User', function() switch_user(false, '') end)
	create(true, false, '', function() end)
end
if fs_exists('/magiczockerOS/programs/osk.lua') then
	create(false, true, 'Keyboard', function() set_my_vis(false) set_visible('osk', not get_visible('osk')) end)
	create(false, true, '', function() end)
end
if os_reboot then
	create(true, true, 'Reboot', function() os_reboot() end)
end
create(true, true, 'Shutdown', function() os_shutdown() end)

-- Events
local function events(e, d, _, y)
	if e == 'refresh_settings' then
		item_align = d.startmenu_items_align or 1,
		back_color(32768, 256, d.startmenu_back or 256)
		text_color(1, 1, d.startmenu_text or 1)
		size()
		draw()
	elseif e == 'mouse_click' and d == 1 then
		menu[mode][y][2]()
	elseif e == 'key' and key_maps[d] and bw < 3 then
		if key_maps[d] == 'enter' then
			menu[mode][cursor][2]()
		elseif key_maps[d] == 'up' then
			cursor = cursor == 1 and #menu[mode] or cursor - 1
		elseif key_maps[d] == 'down' then
			cursor = cursor == #menu[mode] and 1 or cursor + 1
		end
		draw()
	elseif e == 'user' then
		mode = #(user_data().name or "") > 0 and 2 or 1
		size()
		draw()
	elseif e == 'term_resize' then
		draw()
	end
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 257 or 28] = 'enter'
	key_maps[a and 264 or 208] = 'down'
	key_maps[a and 265 or 200] = 'up'
end
events( 'refresh_settings', {} )
events( 'user', '' )
while true do
	events( coroutine_yield() )
end
