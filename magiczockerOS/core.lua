-- magiczockerOS - Copyright by Julian Kriete 2016-2026

local user = 'system'
local user_id = 0
local last_id = 0
local running = true
local apis = {}
local default_settings = {}
local ggv, sgv
local _HOSTver = ccemux and 1132 or tonumber(({((_HOST or ''):match('%s*(%S+)$') or ''):reverse():sub(2):reverse():gsub('%.', '')})[1] or '') or 0
local last_header_click = nil
local drag_x = 0
local border_click_id, border_click_l, border_click_b, border_click_r = 0, false, false, false
local window_min_width = 20
local window_min_height = 10

-- Move dumped functions to local table to not expose them to user windows
local dumps = {}
for k, v in pairs( _G.dumps ) do
	dumps[k] = v
end
_G.dumps = nil

-- use user ids for easier renaming
local user_ids = {}
local system_processes = {
	{'taskbar', true, false},
	--{'startmenu', false, false},
	--{'calendar', false, false},
	--{'osk', false, true},
	--{'contextmenu', false, false},
	{'desktop', true, false} -- Replace with login.lua for system user and design a better login UI
}

-- process index for all windows
-- drawing order for windows
-- drawing order for taskbar after table.sort()
-- taskbar, startmenu, calendar, osk, <user windows>, context menu, desktop
local sessions = {}

-- storing processes (coroutines) and automatically create a new index in sessions table
--local processes = setmetatable( {}, {
--	__newindex = function(t, k, v) -- table, key, value
--		rawset(t, k, v)
--		if v.system then
--			table.insert(sessions[ v.user ], v)
--		else
--			table.insert(sessions[ v.user ], window_offset, v)
--		end
--	end
--} )

local function draw_windows()
	if term.setCursorBlink then
		term.setCursorBlink(false)
	end
	apis.buffer.clear_cache(true)
	local a = ggv()
	sgv(false)
	local temp_window, user_win
	for i = 1, #sessions[ user_id ] do
		temp_window = sessions[ user_id ][ i ].window
		if temp_window.get_visible() then
			temp_window.redraw( i )
		end
	end
	sgv(a)
	apis.buffer.redraw_global_cache(true)
	--screen = apis.buffer.get_screen()
	if term.setCursorBlink then
		term.setCursorBlink(false)
	end
end

local error2 = function(txt)
	local org_content = ''
	local file = fs.open('error.txt', 'r')
	if file then
		org_content = file.readAll()
		file.close()
	end
	file = fs.open('error.txt', 'w')
	if file then
		if #org_content > 0 then
			file.write(org_content)
		end
		file.write(txt .. '\n\n')
		file.close()
	end
end

local function load_api(name)
	--add_to_log('Loading ' .. name)
	local path = ('/magiczockerOS/apis/%s.lua'):format( name )
	local env = setmetatable({
		apis = apis
	}, {__index = _G})
	local file = fs.open( path, 'r')
	if not file then
		error2( ('%s: File not exists'):format( path ), 0)
	end
	local api, err = (loadstring or load)(file.readAll(), path, nil, env)
	file.close()
	if api then
		if setfenv then
			setfenv(api, env)
		end
		local ok, err = pcall(function() return api() end)
		if not ok then
			if err and err ~= '' then
				error2(err, 0)
			end
			return nil
		end
		local out = {}
		for k, v in next, env do
			if v ~= env then
				out[k] = v
			end
		end
		return out
	elseif err and err ~= '' then
		error2(err, 0)
	end
end

local function get_default_settings()
	if not fs.exists('/magiczockerOS/default_settings.json') then
		error('Default settings not found!')
	end
	local file = fs.open('/magiczockerOS/default_settings.json', 'r')
	local ok, err = (loadstring or load)(file.readAll(), 'core: unserialize', 't', {})
	file.close()
	if ok then
		local ok, err = pcall(ok)
		return ok and err or 'core unserialize: Unknown error'
	else
		return {error = err}
	end
	return {}
end

local function get_setting(source, name)
	local s = source and source[name]
	if not s and type(s) == 'nil' then
		return default_settings[name]
	end
	return s
end

local function expect(index, value, ...)
	local args = {...}
	for k, v in next, args do
		if type( value ) == v then
			return value
		end
	end
	error( ( 'bad argument #%d (%s expected, got %s)' ):format( index, table.concat(args, 'or'), type(value)), 3 )
end

local function create_process( user_id, system, custom_env, path, titlebar, ... )
	local args = {...}
	local env = setmetatable( custom_env, {
			__index = _G
	} )
	local out = {
		env = env,
		magicOS = sessions[ user_id ].magic,
		title = path:match('[^/]+$'),
		user = user_id,
		system = system,
		index = #sessions[ user_id ] + 1
	}

	if sessions[ user_id ].offset then
		table.insert( sessions[ user_id ], sessions[ user_id ].offset, out )
	else
		table.insert( sessions[ user_id ], out )
	end

	-- copy bios functions to env
	for k, v in pairs( dumps ) do
		env[k] = load(v, 'Bios - ' .. k, 't', env)
		if setfenv then
			setfenv(env[k], env)
		end
	end
	env._HOSTver = _HOSTver
	if system then
		-- Use magicOS table to avoid conflicts with future CraftOS variables
		-- and make searching for usage of them easier.
		env.magicOS = sessions[ user_id ].magic
		env.os = setmetatable( {
			shutdown = function()
				running = false
			end
		}, { __index=_G.os } )
	else
		--env.fs = ...
	end
	env.expect = expect
	env.multishell = {
		getCount = function() return #sessions[ user_id ] end,
		getCurrent = function() return out.index end,
		getFocus = function()
			for k,v in ipairs(sessions[ user_id ]) do
				if v.system == false then
					return v.index
				end
			end
			return nil
		end,
		getTitle = function(n) -- index
			expect(1, n, 'number')
			for k,v in ipairs(sessions[ user_id ]) do
				if v.index == n then
					return v.title
				end
			end
			return nil
		end,
		launch = function(e, p, ...) -- Env, Path, Arguments
			expect(1, e, 'table')
			expect(2, p, 'string')
			local pro = create_process( user_id, false, e, p, true, ... )
			draw_windows()
			return pro.index
		end,
		setFocus = function(n) -- index
			expect(1, n, 'number')
		end,
		setTitle = function(n, t) -- index, title
			expect(1, n, 'number')
			expect(2, t, 'string')
			t = t:gsub('\t', '')
			for k, v in ipairs(sessions[ user_id ]) do
				if v.index == n then
					v.title = t
					v.env.term.force_header_update() -- Update header
					--_queue(system_windows.taskbar.id .. "", "", "window_change")
					break
				end
			end
		end
	}

	local message = ''
	local program, err
	env.term = apis.window.create(2, 3, 25, 10, true, titlebar, out)
	local orgSize = env.term.getSize
	env.term.getSize = function(s)
		return (s and term.getSize or orgSize)()
	end
	env.term.redirect = function() end
	local file = fs.open( path, 'r' )
	if file then
		program, err = (loadstring or load)( file.readAll(), '@' .. path, 't', env, function(err) return err end )
		file.close()
		if program then
			env._ENV = env
			if setfenv then
				setfenv( program, env )
			end
		else
			message = (err or '') ~= '' and err or ('%s: Unknown error in load'):format( path )
		end
	else
		message = ('%s: File not found'):format( path )
	end
	local coro = coroutine.create( function()
		local ok, err
		if #message == 0 then
			local ok, err = pcall(function() program(table.unpack(args)) end)
			if not ok then
				if #err > 0 then
					message = err
				else
					('%s: Unknown error in pcall'):format( path )
				end
			end
		end
		if #message > 0 then
			error2( message or 'Unknown error' )
			if env.term.setBackgroundColor then
				env.term.setBackgroundColor( 32768 )
			end
			if env.term.setTextColor then
				env.term.setTextColor( 1 )
			end
			env.term.clear()
			env.term.setCursorPos(1, 1)
			env.print( message )
			env.print( 'Press any key to continue' )
			while true do
				local _, d = coroutine.yield()
				if d == 'key' then
					break
				end
			end
		end
	end )
	coroutine.resume(coro, 'term_resize')
	out.window = env.term
	out.coroutine = coro
	return out
end

local function login( u ) -- username
	if user_ids[ u ] then
		user = u
		user_id = user_ids[ u ]
	else
		last_id = last_id + 1
		user_ids[ u ] = last_id
		user = u
		user_id = user_ids[ u ]
		sessions[ user_id ] = {
			offset = 1
		}
		sessions[ user_id ].magic = { -- Keep in mind that only window, taskbar and startmenu can access these commands
			register_key = function() end,
			get_setting = get_setting,
			toggle = function( id )
				sessions[ user_id ][ id ].window.toggle_visible()
				draw_windows()
			end,
			user_data = function() return {
				settings = {}
			} end,
			isVisible = function( id )
				if sessions[ user_id ][id] then
					--error2((env.sessions[id]))
				end
				return sessions[ user_id ][ id ] and sessions[ user_id ][ id ].window.get_visible() or false
			end,
			buttons = {
				{'close', 128, 128, 2048, 256, function( id )
					table.remove( sessions[ user_id ], id )
					draw_windows()
				end},
				{'minimize', 128, 128, 512, 256, function( id )
					sessions[ user_id ][ id ].window.toggle_visible()
					draw_windows()
				end},
				{'maximize', 128, 128, 8, 256, function( id )
					local s = sessions[ user_id ][ id ]
					s.window.toggle_maximized()
					draw_windows()
					coroutine.resume(s.coroutine, 'term_resize')
				end}
			}
		}
		local a = ggv()
		sgv(false)
		for k, v in next, system_processes do
			if fs.exists( ('/magiczockerOS/programs/%s.lua'):format( v[ 1 ] ) ) then
				local z = create_process( user_id, (v[ 1 ] == 'taskbar' or v[ 1 ] == 'startmenu'), {}, ('/magiczockerOS/programs/%s.lua'):format( v[ 1 ] ), v[ 3 ] )
				z.system = true
				if not v[ 2 ] then
					z.window.set_visible(false)
				end
				--if v[ 1 ] == 'osk' then
				--	z.title = 'On-Screen Keyboard'
				--	sessions[ user_id ].offset = k + 1
				--end
				sessions[ user_id ][ v[ 1 ] ] = z
			end
		end
		sgv(a)
		draw_windows()
	end
end

default_settings = get_default_settings()
apis.peripheral = load_api('peripheral')
apis.buffer = load_api('buffer')
apis.window = load_api('window2')
ggv = apis.buffer.get_global_visible
sgv = apis.buffer.set_global_visible
apis.buffer.set_peripheral(apis.peripheral.create(true))
apis.buffer.set_devices('normal', 'computer')
apis.window.reload_color_palette({settings = {color_mode = 1} })
term = apis.peripheral.get_device(apis.peripheral.get_devices(true, true, 'term')[1] or apis.peripheral.get_devices(true, true, 'monitor')[1])
w, h = term.getSize()
login( 'system' )

-- Events
while running do
	local e, d, x, y, z = coroutine.yield()
	local s = sessions[ user_id ]
	-- Comvert OpenComputers to ComputerCraft
	if e == 'key_down' then
		if x > 31 and x < 127 then
			events('char', string.char(x))
		end
		e = 'key'
		d = y
	elseif e == 'touch' then
		e = 'mouse_click'
		d = z + 1
	elseif e == 'drop' then
		e = 'mouse_up'
		d = z + 1
	elseif e == 'drag' then
		e = 'mouse_drag'
		d = z + 1
	elseif e == 'scroll' then
		e = 'mouse_scroll'
		d = z * -1
	elseif e == 'screen_resized' then
		--e = 'monitor_resize'
	end

	-- Passing events to windows
	if e == 'mouse_click' or e == 'mouse_scroll' then
		for k, v in ipairs( s ) do
			local pX, pY, pW, pH, pV = v.window.get_data()
			if v.window.has_header() and pV and x >= pX and x < pX+pW and y == pY then -- Window-Buttons
				if k > s.offset then
					table.remove(s, k)
					table.insert(s, s.offset, v)
					draw_windows()
					k = s.offset
				end
				border_click_id = 0
				local btn = v.magicOS.buttons[ x - pX + 1 ]
				if btn and btn[ 6 ] then
					btn[ 6 ]( k )
				elseif x == pX + pW - 1 and not v.window.is_maximized() then -- Toggle resize
					v.window.toggle_border()
				else -- Empty header space
					last_header_click = k
					drag_x = x - pX
				end
				break
			elseif v.window.getBorder() then
				border_click_id, border_click_l, border_click_b, border_click_r = k, x == pX, y == pY + pH - 1, x == pX + pW - 1
				if not border_click_l and not border_click_b and not border_click_r then
					border_click_id = 0
					v.window.toggle_border()
				end
			elseif pV and x >= pX and x < pX+pW and y >= pY and y < pY+pH then
				if e == 'mouse_click' and k > s.offset then
					table.remove(s, k)
					table.insert(s, s.offset, v)
					draw_windows()
					--k = s.offset
				end
				last_header_click = nil
				coroutine.resume( v.coroutine, e, d, x-pX+1, y-pY+1 - ( v.window.has_header() and 1 or 0 ) )
				break
			end
		end
	elseif e == 'mouse_drag' and border_click_id > 0 then
		local pX, pY, pW, pH = s[ border_click_id ].window.get_data()
		if border_click_l then -- Left border
			pW = pW + (pX - x)
			pX = x
		end
		if border_click_b then -- Bottom border
			pH = y - pY + 1
		end
		if border_click_r then -- Right border
			pW = x - pX + 1
		end
		pW = math.max( window_min_width, pW )
		pH = math.max( window_min_height, pH )
		s[ border_click_id ].window.reposition( pX, pY, pW, pH )
		draw_windows()
		coroutine.resume( s[ border_click_id ].coroutine, 'term_resize' )
	elseif e == 'mouse_drag' and last_header_click then
		local pX, pY, pW, pH = s[ last_header_click ].window.get_data()
		s[ last_header_click ].window.reposition( x - drag_x, y, pW, pH )
		draw_windows()
	elseif e == 'terminate' then
		running = false
	end
end