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
			menu[1][#menu[1]+1] = setmetatable({}, {
				__tostring=function() return c end,
				__call=d,
			})
		end
		menu[2][#menu[2]+1] = setmetatable({}, {
			__tostring=function() return c end,
			__call=d,
		})
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
local function draw()
	back_color(32768, 256, settings.startmenu_back or 256)
	text_color(1, 1, settings.startmenu_text or 1)
	for y = 1, #menu[mode] do
		local a = tostring(menu[mode][y])
		local b = settings.startmenu_items_align
		local c = cursor == y and (not term or not term.isColor or not term.isColor()) and "-" or " "
		local d = (width - #a) * 0.5
		term.setCursorPos(1, y)
		term.write(c .. (a=="" and ("-"):rep(width - 2) or b==2 and (" "):rep(math.floor(d) - 1) .. a .. (" "):rep(math.ceil(d) - 1) or b==3 and (" "):rep(width - #a - 2) .. a or a .. (" "):rep(width - #a - 2)) .. c)
	end
end
local function size()
	width = 1
	for y = 1, #menu[mode] do
		local a = tostring(menu[mode][y])
		width = #a > width and #a or width
	end
	width = width + 2
	set_size(width, #menu[mode])
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
	local e, d, x, y = coroutine.yield()
	if e == "refresh_settings" then
		settings = get_settings()
		draw()
	elseif e == "user" then
		mode = #(user_data().name or "") > 0 and 2 or 1
		size()
		draw()
	elseif e == "mouse_click" and d == 1 then
		menu[mode][y]()
	elseif e == "key" and key_maps[d] and (not term.isColor or not term.isColor()) then
		if key_maps[d] == "enter" then
			menu[mode][cursor]()
		elseif key_maps[d] == "up" then
			cursor = cursor == 1 and #menu[mode] or cursor - 1
		elseif key_maps[d] == "down" then
			cursor = cursor == #menu[mode] and 1 or cursor + 1
		end
		draw()
	end
end