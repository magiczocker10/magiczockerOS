-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- numbers
local A = 1 -- cursor
local D = not term.isColor and 1 or term.isColor() and 4 or textutils and type(textutils.complete) == "function" and 3 or 2 -- list_mode
local C = 1 -- width
-- tables
local E = {} -- key_maps
local F = {{}, {}, {}, {}, {}, {}, {}, {}}
local G = settings or {}
-- functions
local function B(a, b, c)
	for i = a and 5 or 1, a and 8 or 4 do
		F[i][#F[i] + 1] = {b, c}
	end
end
H=ceil
I=floor
local function J(a, b, c)
	if term and term.isColor then
		term.setBackgroundColor(term.isColor() and c or textutils and type(textutils.complete) == "function" and b or a)
	end
end
local function K(a, b, c)
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
local function L() -- draw
	J(32768, 256, G.startmenu_back or 256)
	K(1, 1, G.startmenu_text or 1)
	for y = 1, #F[D] do
		local a = F[D][y]
		local b = ""
		local c = A == y and (not term or not term.isColor or not term.isColor()) and "-" or " "
		if a[1] == "" then
			b = ("-"):rep(C - 2)
		elseif G.startmenu_items_align == 2 then
			local length = (C - #a[1]) * 0.5
			b = (" "):rep(I(length) - 1) .. a[1] .. (" "):rep(H(length) - 1)
		elseif G.startmenu_items_align == 3 then
			b = (" "):rep(C - #a[1] - 2) .. a[1]
		else
			b = a[1] .. (" "):rep(C - #a[1] - 2)
		end
		term.setCursorPos(1, y)
		term.write(c .. b .. c)
	end
end
local function M() -- size
	C = #F[D][1]
	for y = 2, #F[D] do
		C = #F[D][y][1] > C and #F[D][y][1] or C
	end
	C = C + 2
	set_size(C, #F[D])
end
local function N() -- load_keys
	local a
	if #(_HOST or "") > 1 then -- Filter from https://forums.coronalabs.com/topic/71863-how-to-find-the-last-word-in-string/
		a = tonumber(({_HOST:match("%s*(%S+)$"):reverse():sub(2):reverse():gsub("%.", "")})[1] or "")
	end
	if a and type(a) == "number" and a >= 1132 then -- GLFW
		E[257] = "enter"
		E[264] = "down"
		E[265] = "up"
	else -- LWJGL
		E[28] = "enter"
		E[200] = "up"
		E[208] = "down"
	end
end
-- start
if D == 4 then
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
if D == 4 and fs.exists("/magiczockerOS/programs/osk.lua") then
	B(true, "Keyboard", function() set_visible("osk", not get_visible("osk")) set_visible("startmenu", not get_visible("startmenu")) end)
	B(true, "", nil)
end
B(true, "Reboot", function() os.reboot() end)
B(true, "Shutdown", function() os.shutdown() end)
N()
M()
L()
-- events
while true do
	local a, b, c, d = coroutine.yield()
	if a == "refresh_settings" then
		G = get_settings()
		L()
	elseif a == "user" then
		D = not term.isColor and 1 or term.isColor() and 4 or textutils and type(textutils.complete) == "function" and 3 or 2
		if #(user_data().name or "") > 0 then
			D = D + 4
		end
		M()
		L()
	elseif a == "mouse_click" and b == 1 and c <= C and d <= #F[D] and F[D][d][2] then
		F[D][d][2]()
	elseif a == "key" and E[b] and (not term.isColor or not term.isColor()) then
		if E[b] == "enter" and F[D][A][2] then
			F[D][A][2]()
		elseif E[b] == "up" then
			A = A == 1 and #F[D] or A - 1
		elseif E[b] == "down" then
			A = A == #F[D] and 1 or A + 1
		end
		L()
	end
end