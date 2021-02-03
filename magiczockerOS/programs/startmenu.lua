-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

local cursor, key_maps, menu, mode, width = 1, {}, {{}, {}}, nil, 1
local settings = user_data().settings or {}
local term, textutils = term, textutils
local function create(a, b, c, d)
	if term.isColor and term.isColor() or a then
		if b then
			menu[1][#menu[1] + 1] = {c, d}
		end
		menu[2][#menu[2] + 1] = {c, d}
	end
end
local my_win = user_data().windows[1]
local bw = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[bw]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[bw]
	if b then term.setTextColor(b) end
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
	for y = 1, #menu[mode] do
		local a = menu[mode][y][1]
		local b = settings.startmenu_items_align
		local c = cursor == y and bw < 3 and "-" or " "
		local d = (width - #a) * 0.5
		term.setCursorPos(1, y)
		term.write(c .. (a == "" and ("-"):rep(width - 2) or b == 2 and (" "):rep(math.floor(d) - 1) .. a .. (" "):rep(math.ceil(d) - 1) or b == 3 and (" "):rep(width - #a - 2) .. a or a .. (" "):rep(width - #a - 2)) .. c)
	end
end
local function size()
	width = 1
	for y = 1, #menu[mode] do
		local a = menu[mode][y][1]
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
			for i = 1, #uData.windows do
				a = uData.windows[i].window
				if a.get_visible() then
					a.set_visible(false)
					tmpd[#tmpd + 1] = a.set_visible
				end
			end
		else
			for i = 1, #tmpd do
				tmpd[i](true)
			end
			uData.desktop = {}
		end
	end
	my_win.is_system = false
	multishell.setTitle(my_win.id, "")
	my_win.is_system = true
	set_visible("taskbar", true)
end
local function events(a, b, _, c)
	if a == "refresh_settings" then
		settings = user_data().settings or {}
		back_color(32768, 256, settings.startmenu_back or 256)
		text_color(1, 1, settings.startmenu_text or 1)
		draw()
	elseif a == "mouse_click" and b == 1 then
		menu[mode][c][2]()
	elseif a == "key" and key_maps[b] and bw < 3 then
		if key_maps[b] == "enter" then
			menu[mode][cursor][2]()
		elseif key_maps[b] == "up" then
			cursor = cursor == 1 and #menu[mode] or cursor - 1
		elseif key_maps[b] == "down" then
			cursor = cursor == #menu[mode] and 1 or cursor + 1
		end
		draw()
	elseif a == "user" then
		mode = #(user_data().name or "") > 0 and 2 or 1
		size()
		draw()
	elseif a == "term_resize" then
		draw()
	end
end
do
	local a = _HOSTver >= 1132
	key_maps[a and 257 or 28] = "enter"
	key_maps[a and 264 or 208] = "down"
	key_maps[a and 265 or 200] = "up"
end
create(true, false, "CraftOS", function() close_os() end)
if fs.exists("/magiczockerOS/programs/settings.lua") then
	create(true, false, "Settings", function() set_my_vis(false) create_window("/magiczockerOS/programs/settings.lua", true) end)
end
create(true, false, "Shell", function() set_my_vis(false) create_window() end)
create(true, false, "Show Desktop", function() show_desktop() end)
create(true, false, "", function() end)
if fs.exists("/magiczockerOS/programs/login.lua") then
	create(true, false, "Sign out", function() switch_user(true, "") end)
	create(true, false, "Switch User", function() switch_user(false, "") end)
	create(true, false, "", function() end)
end
if fs.exists("/magiczockerOS/programs/osk.lua") then
	create(false, true, "Keyboard", function() set_my_vis(false) set_visible("osk", not get_visible("osk")) end)
	create(false, true, "", function() end)
end
if os.reboot then
	create(true, true, "Reboot", function() os.reboot() end)
end
create(true, true, "Shutdown", function() os.shutdown() end)
back_color(32768, 256, settings.startmenu_back or 256)
text_color(1, 1, settings.startmenu_text or 1)
events("user")
while true do
	events(coroutine.yield())
end