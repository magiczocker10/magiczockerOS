-- magiczockerOS - Copyright by Julian Kriete 2016-2021

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180

-- Define global variables as local
local cy = coroutine.yield
local open = fs.open
local concat, insert = table.concat, table.insert
local tb, tc, tt, tw = term.setBackgroundColor or function() end, term.setCursorPos, term.setTextColor or function() end, term.write

-- Variables
local caps = false
local glfw, mode = (_HOSTver or 0) >= 1132, 1
local arrows, layout, view = {}, {}, {}

-- Functions
local function load_keys( okm )
	local f = open( '/magiczockerOS/key_mappings/data.lua', 'r' )
	local codes = (loadstring or load)( f.readAll(), '@key_mapping', 't', {} )()
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
	arrows = {}
	layout[1] = {}
	layout[2] = {}
	view[1] = {}
	view[2] = {}
	local function load_lines( y, path )
		local file = open( path, 'r' )
		local file_line = 0
		for line in file.readLine do
			file_line = file_line + 1
			word = line:match('[^%s]+')
			c_word = codes[word]
			if c_word then
				insert( out1[y], c_word[1] )
				insert( out2[y], c_word[2] )
				insert( layout[y], c_word )
				if is_arrow[ word ] then
					arrows[glfw and codes[word][3] or codes[word][4]] = true
				end
			elseif word == '##' then
			elseif word == 'NEWLINE' then
				y = y + 1
				out1[y] = out1[y] or {}
				out2[y] = out2[y] or {}
				layout[y] = layout[y] or {}
			elseif word == 'NEWLINE_BASE' then
				y = y + 1
			elseif word == 'PLACEHOLDER' then
				local count = tonumber(line:sub(line:find('%s'), #line))
				local tmp = count > 1 and ( ' ' ):rep( count - 1) or ''
				insert( out1[y], tmp )
				insert( out2[y], tmp )
				insert( layout[y], {tmp, tmp, 0, 0} )
			else
				error( ( 'Line %s: %s' ):format( file_line, word ) )
			end
		end
		file.close()
	end
	load_lines( 2, ( '/magiczockerOS/key_mappings/%s.map' ):format( okm ) )
	load_lines( 1, '/magiczockerOS/key_mappings/base.map' )
	for k, v in next, out1 do
		view[1][k] = concat( v, ' ' )
		view[2][k] = concat( out2[k], ' ' )
	end
end
local function draw()
	local w = 0
	for k, v in next, view[mode] do
		tc(1, k)
		tw(v)
		w = #v > w and #v or w
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
					if mode == 2 and not caps then
						mode = 1
						draw()
					elseif l[entry][1] == 'Shift' or l[entry][1] == 'Caps' then
						mode = mode == 1 and (l[entry][1] == 'Shift' or l[entry][1] == 'Caps') and 2 or 1
						caps = l[entry][1] == 'Caps' and mode == 2
						draw()
					end
					break
				end
			else
				count = count + #l[entry][1] + 1
			end
		end
	elseif e == 'refresh_settings' then
		local a, b = d.window_bar_active_back or 256, d.window_bar_active_text or 1
		local c = term and term.isColor and (term.isColor() and 3 or (_VERSION):match('^Lua%s') and 2 or 1) or 0
		load_keys( d.osk_key_mapping or 'qwerty' )
		tb( ( {32768, 32768, a} )[ c ] )
		tt( ( {1, 1, a == 1 and 32768 or b} )[ c ] )
		local w = draw()
		set_pos(nil, nil, w - 1, #layout + 1)
		draw()
	end
end
events( 'refresh_settings', {} )
while true do
	events( cy() )
end
