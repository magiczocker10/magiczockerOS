-- Calender works from 15.10.1582 until 31.12.9999

-- Define global variables as local
local cy = coroutine.yield
local mf = math.floor
local tb, tc, tt, tw = term.setBackgroundColor or function() end, term.setCursorPos, term.setTextColor or function() end, term.write

-- Variables
local bw = term and term.isColor and (term.isColor() and 3 or (_VERSION):match('^Lua%s') and 2 or 1) or 0
local date = os.date and os.date( '*t' ) or {}
local day, month, year = date.day or 1, date.month or 1, date.year or 1970
local k = {}
local w = 23
local h = 8
local running = true
local offsets = {
	0,31,60,91,121,152,182,213,244,274,305,335,
	0,31,59,90,120,151,181,212,243,273,304,334
}
local cb, cl, ct, ctt, ctb

-- Functions
local function back(...)
	tb( ({...})[bw] )
end

local function text(...)
	tt( ({...})[bw] )
end

local function write(...)
	tw( ({...})[bw + 1] )
end

local function week_day( d, m, y ) -- Source: https://de.wikipedia.org/wiki/Wochentagsberechnung
	if ( m < 3 ) then
		y = y - 1
	end
	return ( ( d + mf( 2.6 * ( ( m + 9 ) % 12 + 1 ) - 0.2 ) + y % 100 + mf( y % 100 * 0.25 ) + mf( y * 0.0025 ) - 2 * mf( y * 0.01 ) - 1 ) % 7 + 7 ) % 7 + 1
end

local function leap_year( y )
	return y % 4 == 0 and y % 100 ~= 0 or y % 400 == 0
end

local function days_in_month( m, l ) -- Source: http://lua-users.org/wiki/DayOfWeekAndDaysInMonthExample
	return m == 2 and l and 29 or ('\31\28\31\30\31\30\31\31\30\31\30\31'):byte( m )
end

local function week( d, m, y, l, x ) -- Source: https://en.wikipedia.org/wiki/ISO_week_date
	local w = mf(( 10 + offsets[ m + (l and 12 or 0 ) ] + d - week_day( d, m, y ) ) / 7 )
	if not x and w == 53 and week(1, 1, y + 1, l) == 1 then
		return 1
	end
	return w == 0 and week(31, 12, y - 1, l, true) or w
end

local function draw()
	local a = week_day( 1, month, year ) % 7
	if a == 0 then
		a = 7
	end
	local ly = leap_year( year )
	local days = days_in_month( month, ly )
	a = 1 - a
	back( 32768, 1, cb )
	for y = 1, h do
		tc( 1, y )
		if y == 1 then
			text( 1, 256, cl )
			tw( '< ' )
			text( 1, 128, ct )
			tw( ('JanFebMarAprMayJunJulAugSepOctNovDec'):sub(3 * month - 2, 3 * month) )
			text( 1, 256, cl )
			tw( ' >        < ' )
			text( 1, 128, ct )
			tw( ( '%4d' ):format( year ) )
			text( 1, 256, cl )
			tw( ' >' )
		elseif y == 2 then
			text( 1, 256, cl )
			tw( '   Mo Th We Th Fr Sa Su' )
		else
			for x = 1, 7 do
				a = a + 1
				if x == 1 then
					text( 1, 256, cl )
					tw( a <= days and ( '%2d' ):format( week( a > 0 and a or 1, month, year, ly ) ) or '  ' )
					text( 1, 128, ct )
				end
				if a == day and month == date.month and year == date.year then
					tw( ' ' )
					back( 1, 128, ctb )
					text( 32768, 1, ctt )
					write( '##', ( '%2d' ):format( a ), ( '%2d' ):format( a ), ( '%2d' ):format( a ) )
					back( 32768, 1, cb )
					text( 1, 128, ct )
				else
					tw( (a > 0 and a <= days) and ( ' %2d' ):format( a ) or '   ' )
				end
			end
		end
	end
end

local function fix_date()
	if month == 13 then
		month = 1
		year = year + 1
	elseif month == 0 then
		month = 12
		year = year - 1
	end
	if year < 1582 then
		year = 1582
	elseif year > 9999 then
		month = 12
		year = 9999
	end
	if year == 1582 and month < 11 then
		month = 11
	end
	draw()
end

-- Events
local function events( e, d, x, y )
	if e == 'mouse_click' and y == 1 then
		if x == 1 then
			month = month - 1
			fix_date()
		elseif x == 7 then
			month = month + 1
			fix_date()
		elseif x == w - 7 then
			year = year - 1
			fix_date()
		elseif x == w then
			year = year - 1
			fix_date()
		end
	elseif e == 'mouse_scroll' and y == 1 then
		if x < 8 then
			month = month + d
			fix_date()
		elseif x > w - 8 then
			year = year + d
			fix_date()
		end
	elseif e == 'key' and k[d] then
		if k[d] == 'l' then
			month = month - 1
		elseif k[d] == 'r' then
			month = month + 1
		elseif k[d] == 'u' then
			year = year - 1
		elseif k[d] == 'd' then
			year = year + 1
		end
		fix_date()
	elseif e == 'terminate' then
		running = false
	elseif e == 'term_resize' then
		local parentW, parentH = term.getSize(true)
		term.setPos(parentW - w + 1, 2, w, h)
	elseif e == 'refresh_settings' then
		cb = tonumber( d.calendar_back or '1' )
		cl = tonumber( d.calender_label or '256' )
		ct = tonumber( d.calendar_text or '128' )
		ctb = tonumber( d.calendar_today_back or '2048' )
		ctt = tonumber( d.calendar_today_text or '1' )
		draw()
	end
end

do
	--local a = true or _HOSTver >= 1132
	local a = false
	k[a and 262 or 205] = 'r'
	k[a and 263 or 203] = 'l'
	k[a and 264 or 208] = 'd'
	k[a and 265 or 200] = 'u'
end
events( 'term_resize' )
events( 'refresh_settings', {} )
while running do
	events( cy() )
end