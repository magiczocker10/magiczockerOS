-- magiczockerOS - Copyright by Julian Kriete 2016-2026

-- Variables
local w, h = term.getSize(true)
local startmenuId, calendarId = 0, 0

-- Functions
local function draw()
	local f = multishell.getFocus()
	term.setBackgroundColor( 256 )
	term.setCursorPos( 1, 1 )
	term.write( f == startmenuId and '_m_' or ' m ')
	term.write( f == calendarId and '_calendar_' or ' calendar ')
	term.write( ('_'):rep(w-13) )
end

local function events(e, d, x, y)
	if e == 'mouse_click' then
		if x > 0 and x < 4 then
			startmenuId = multishell.launch( { magicOS = magicOS }, 'magiczockerOS/programs/startmenu.lua' )
			draw()
		elseif x > 3 and x < 14 then
			calendarId = multishell.launch( { magicOS = magicOS }, 'magiczockerOS/programs/calendar.lua' )
			draw()
		end
	elseif e == 'term_resize' then
		w, h = term.getSize(true)
		term.setPos( 1, 1, w, 1 )
		draw()
	end
end

-- Events
events( 'term_resize' )
while true do
	events(coroutine.yield())
end
