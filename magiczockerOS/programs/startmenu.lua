-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- numbers
local cursor = 1
local width = 1
-- tables
local mode = 1
local key_maps = {}
local menu = {{},{}}
local settings = settings or {}
-- functions
local function create(a,b,c,d)
	if (term.isColor and term.isColor()) or a then
		if b then
			menu[1][#menu[1]+1] = {c,d}
		end
		menu[2][#menu[2]+1] = {c,d}
	end
end
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
local function draw()
	back_color(32768, 256, settings.startmenu_back or 256)
	text_color(1, 1, settings.startmenu_text or 1)
	for y = 1, #menu[mode] do
		local a = menu[mode][y][1]
		local b = settings.startmenu_items_align
		local c = cursor == y and (not term or not term.isColor or not term.isColor()) and "-" or " "
		local d = (width - #a) * 0.5
		term.setCursorPos(1, y)
		term.write(c .. (a=="" and ("-"):rep(width - 2) or b==2 and (" "):rep(floor(d) - 1) .. a .. (" "):rep(ceil(d) - 1) or b==3 and (" "):rep(width - #a - 2) .. a or a .. (" "):rep(width - #a - 2)) .. c)
	end
end
local function size()
	width = 1
	for y = 1, #menu[mode] do
		local a = menu[mode][y][1]
		width = #a > width and #a or width
	end
	width = width + 2
	set_size(width, #menu[mode])
end
local function load_keys()
	if _HOSTver and _HOSTver >= 1132 then -- GLFW
		key_maps[257] = "enter"
		key_maps[264] = "down"
		key_maps[265] = "up"
	else -- LWJGL
		key_maps[28] = "enter"
		key_maps[200] = "up"
		key_maps[208] = "down"
	end
end
-- start
create(true, false, "CraftOS", function() close_os() end)
if fs.exists("/magiczockerOS/programs/settings.lua") then
	create(true, false, "Settings", function() set_visible("startmenu", false) create_window("/magiczockerOS/programs/settings.lua",true) end)
end
create(true, false, "Shell", function() set_visible("startmenu", false) create_window() end)
create(true, false, "Show Desktop", function() show_desktop() end)
create(true, false, "", function() end)
if fs.exists("/magiczockerOS/programs/login.lua") then
	create(true, false, "Sign out", function() switch_user(true, "") end)
	create(true, false, "Switch User", function() switch_user(false, "") end)
	create(true, false, "", function() end)
end
if fs.exists("/magiczockerOS/programs/osk.lua") then
	create(false, true, "Keyboard", function() set_visible("osk", not get_visible("osk")) set_visible("startmenu", not get_visible("startmenu")) end)
	create(false, true, "", function() end)
end
if os.reboot then
	create(true, true, "Reboot", function() os.reboot() end)
end
create(true, true, "Shutdown", function() os.shutdown() end)
load_keys()
size()
draw()
-- events
while true do
	local a, b, _, c = coroutine.yield()
	if a == "refresh_settings" then
		settings = get_settings()
		draw()
	elseif a == "user" then
		mode = #(user_data().name or "") > 0 and 2 or 1
		size()
		draw()
	elseif a == "mouse_click" and b == 1 then
		menu[mode][c][2]()
	elseif a == "key" and key_maps[b] and (not term.isColor or not term.isColor()) then
		if key_maps[b] == "enter" then
			menu[mode][cursor][2]()
		elseif key_maps[b] == "up" then
			cursor = cursor == 1 and #menu[mode] or cursor - 1
		elseif key_maps[b] == "down" then
			cursor = cursor == #menu[mode] and 1 or cursor + 1
		end
		draw()
	end
end
