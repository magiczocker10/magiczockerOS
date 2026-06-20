-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- Define global variables as local
local coroutine_yield = coroutine.yield
local fs_open = fs.open
local string_format, string_rep = string.format, string.rep
local table_concat, table_insert = table.concat, table.insert
local term_cursor, term_write = term.setCursorPos, term.write

-- Variables
local arrows, glfw, mode, settings = {}, (_HOSTver or 0) >= 1132, 1, {}
local layout, view

-- Functions
local function load_keys()
	local f = fs_open( '/magiczockerOS/key_mappings/data.lua', 'r' )
	local codes = (loadstring or load)( f.readAll() )()
	f.close()
	local is_arrow = {
		DOWN = true,
		LEFT = true,
		RIGHT = true,
		UP = true
	}
	local word, c_word
	local out1 = { {}, {} }
	local out2 = { {}, {} }
	layout = { {}, {} }
	view = { {}, {} }
	local function load_lines( posY, path )
		local file = fs_open( path, 'r' )
		local file_line = 0
		for line in file.readLine do
			file_line = file_line + 1
			word = line:match('[^%s]+')
			c_word = codes[word]
			if c_word then
				table_insert( out1[posY], c_word[1] )
				table_insert( out2[posY], c_word[2] )
				table_insert( layout[posY], c_word )
				if is_arrow[ word ] then
					arrows[glfw and codes[word][3] or codes[word][4]] = true
				end
			elseif word == '##' then
			elseif word == 'NEWLINE' then
				posY = posY + 1
				out1[posY] = out1[posY] or {}
				out2[posY] = out2[posY] or {}
				layout[posY] = layout[posY] or {}
			elseif word == 'NEWLINE_BASE' then
				posY = posY + 1
			elseif word == 'PLACEHOLDER' then
				local count = tonumber(line:sub(line:find('%s'), #line))
				local tmp = count > 1 and string_rep(' ', count - 1) or ''
				table_insert( out1[posY], tmp )
				table_insert( out2[posY], tmp )
				table_insert( layout[posY], {tmp, tmp, 0, 0} )
			else
				error( string_format( 'Line %s: %s', file_line, word ) )
			end
		end
		file.close()
	end
	load_lines( 2, string_format( '/magiczockerOS/key_mappings/%s.map', settings.osk_key_mapping ) )
	load_lines( 1, '/magiczockerOS/key_mappings/base.map' )
	for k, v in next, out1 do
		view[1][k] = table_concat( v, ' ')
		view[2][k] = table_concat( out2[k], ' ')
	end
end
local a = term and term.isColor and (term.isColor() and 3 or textutils and textutils.complete and 2 or 1) or 0
local function back_color(...)
	local b = ({...})[a]
	if b then term.setBackgroundColor(b) end
end
local function text_color(...)
	local b = ({...})[a]
	if b then term.setTextColor(b) end
end
local function set_color()
	local b = settings.wbab
	back_color(32768, 32768, b)
	text_color(1, 1, b == 1 and 32768 or settings.wbat)
end
local function draw()
	local w = 0
	for k, _ in next, layout do
		term_cursor(1, k)
		term_write(view[mode][k])
		w = #view[mode][k] > w and #view[mode][k] or w
	end
	return w
end
local function send_event(...)
	local proc = user_data and user_data().windows[1]
	if proc then
		proc.env.os.queueEvent(...)
	end
end

-- Events
local function events(e, d, x, y)
	if e == 'mouse_click' then
		local count, l = 0, layout[y]
		for entry = 1, #l do
			if count < x and count + #l[entry][1] >= x then
				if l[entry][3] > 0 then
					local tmp = mode > 1 and l[entry][2] or l[entry][1]
					if tmp == '---SPACE---' then
						send_event('char', ' ')
					elseif #tmp == 1 and not arrows[glfw and l[entry][3] or l[entry][4]] then
						send_event('char', tmp)
					end
					send_event('key', glfw and l[entry][3] or (mode > 1 and l[entry][5] or l[entry][4]))
					if mode == 2 then
						mode = 1
						draw()
					elseif l[entry][1] == 'Shift' or l[entry][1] == 'Caps' then
						mode = mode == 1 and (l[entry][1] == 'Shift' and 2 or l[entry][1] == 'Caps' and 3) or 1
						draw()
					end
					break
				end
			else
				count = count + #l[entry][1] + 1
			end
		end
	elseif e == 'refresh_settings' then
		settings = {
			osk_key_mapping = d.osk_key_mapping or 'qwerty',
			wbab = d.window_bar_active_back or 256,
			wbat = d.window_bar_active_text or 1
		}
		load_keys()
		set_color()
		local w = draw()
		set_pos(nil, nil, w - 1, #layout + 1)
	end
end
events( 'refresh_settings', {} )
while true do
	events( coroutine_yield() )
end
