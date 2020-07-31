-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- numbers
local cursor = 1
local list_mode = not term.isColor and 1 or term.isColor() and 4 or textutils and type(textutils.complete) == "function" and 3 or 2
local width = 1
-- tables
local key_maps = {}
local F = {{}, {}, {}, {}, {}, {}, {}, {}}
local settings = settings or {}
-- functions
local function B(a, b, c)
	for i = a and 5 or 1, a and 8 or 4 do
		F[i][#F[i] + 1] = {b, c}
	end
end
local function back_color(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function text_color(a, b, c)
	if term and term.isColor then
		term.setTextColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
if not os.reboot then
	for _, v in next, F do
		local tmp = #v
		v[tmp - 1] = v[tmp]
		v[tmp] = nil
	end
end
local function draw()
	back_color(32768, 256, settings.startmenu_back or 256)
	text_color(1, 1, settings.startmenu_text or 1)
	for y = 1, #F[list_mode] do
		local a = F[list_mode][y]
		local b = ""
		local c = cursor == y and (not term or not term.isColor or not term.isColor()) and "-" or " "
		if a[1] == "" then
			b = ("-"):rep(width - 2)
		elseif settings.startmenu_items_align == 2 then
			local length = (width - #a[1]) * 0.5
			b = (" "):rep(math.floor(length) - 1) .. a[1] .. (" "):rep(math.ceil(length) - 1)
		elseif settings.startmenu_items_align == 3 then
			b = (" "):rep(width - #a[1] - 2) .. a[1]
		else
			b = a[1] .. (" "):rep(width - #a[1] - 2)
		end
		term.setCursorPos(1, y)
		term.write(c .. b .. c)
	end
end
local function size()
	width = #F[list_mode][1]
	for y = 2, #F[list_mode] do
		width = #F[list_mode][y][1] > width and #F[list_mode][y][1] or width
	end
	width = width + 2
	set_size(width, #F[list_mode])
end
local function load_keys()
	local a
	if #(_HOST or "") > 1 then -- Filter from https://forums.coronalabs.com/topic/71863-how-to-find-the-last-word-in-string/
		a = tonumber(({_HOST:match("%s*(%S+)$"):reverse():sub(2):reverse():gsub("%.", "")})[1] or "")
	end
	if a and type(a) == "number" and a >= 1132 then -- GLFW
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
if list_mode == 4 then
	B(false, "Keyboard", function() set_visible("osk", not get_visible("osk")) end)
	B(false, "", nil)
end
B(false, "Reboot", function() os.reboot() end)
B(false, "Shutdown", function() os.shutdown() end)
B(true, "CraftOS", function() close_os() end)
if fs.exists("/magiczockerOS/programs/settings.lua") then
	B(true, "Settings", function() set_visible("startmenu", false) create_window("/magiczockerOS/programs/settings.lua",true) end)
end
B(true, "Shell", function() set_visible("startmenu", false) create_window() end)
B(true, "Show Desktop", function() show_desktop() end)
B(true, "", nil)
if fs.exists("/magiczockerOS/programs/login.lua") then
	B(true, "Sign out", function() switch_user(true, "") end)
	B(true, "Switch User", function() switch_user(false, "") end)
	B(true, "", nil)
end
if list_mode == 4 and fs.exists("/magiczockerOS/programs/osk.lua") then
	B(true, "Keyboard", function() set_visible("osk", not get_visible("osk")) set_visible("startmenu", not get_visible("startmenu")) end)
	B(true, "", nil)
end
B(true, "Reboot", function() os.reboot() end)
B(true, "Shutdown", function() os.shutdown() end)
load_keys()
size()
draw()
-- events
while true do
	local e, d, x, y = coroutine.yield()
	if e == "refresh_settings" then
		settings = get_settings()
		draw()
	elseif e == "user" then
		list_mode = not term.isColor and 1 or term.isColor() and 4 or textutils and type(textutils.complete) == "function" and 3 or 2
		if #(user_data().name or "") > 0 then
			list_mode = list_mode + 4
		end
		size()
		draw()
	elseif e == "mouse_click" and d == 1 and x <= width and y <= #F[list_mode] and F[list_mode][y][2] then
		F[list_mode][y][2]()
	elseif e == "key" and key_maps[d] and (not term.isColor or not term.isColor()) then
		if key_maps[d] == "enter" and F[list_mode][cursor][2] then
			F[list_mode][cursor][2]()
		elseif key_maps[d] == "up" then
			cursor = cursor == 1 and #F[list_mode] or cursor - 1
		elseif key_maps[d] == "down" then
			cursor = cursor == #F[list_mode] and 1 or cursor + 1
		end
		draw()
	end
end
