-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
set_size(15,4)
multishell.setTitle(multishell.getCurrent(),"Goto Date")
local cursor=1
local fields={
	{"day",2},
	{"month",2},
	{"year",4},
}
local is_bw = (not term or not term.isColor or not term.isColor())
local click_x={0,1,1,0,2,2,0,3,3,3,3,0,4,4}
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
local function write_text(a, b, c, d)
	term.write(not term.isColor and a or term.isColor() and d or textutils and type(textutils.complete) == "function" and c or b)
end
local function draw()
	local b=0
	back_color(32768, 128, 2048)
	term.setCursorPos(1,1)
	term.write((" "):rep(15))
	term.setCursorPos(1,2)
	write_text(is_bw and cursor==1 and ">" or " "," "," "," ")
	for i=1,#fields do
		if cursor==i then
			back_color(1,256,8)
		else
			back_color(1,1,1)
		end
		local a = fields[i]
		text_color(32768,128,128)
		term.write((("0"):rep(a[2]).._G[a[1]]):sub(a[2]*(-1)))
		text_color(1,1,1)
		back_color(32768, 128, 2048)
		local tmp1=is_bw and cursor==i+1 and ">" or is_bw and cursor==i and "<" or i<#fields and "." or " "
		local tmp2=i<#fields and "." or " "
		write_text(tmp1,tmp2,tmp2,tmp2)
	end
	text_color(1,1,1)
	back_color(1,256,8)
	term.write"|>"
	back_color(32768, 128, 2048)
	term.write" "
	term.setCursorPos(1,3)
	term.write((" "):rep(15))
end
local function get_month_days(m)
	return m == 2 and 28 or (m % 2 == (m < 8 and 0 or 1) and 30 or 31) -- the 29th will be added seperatly
end
local function is_leap_year(year)
	return year % 4 == 0 and (year * 0.01 % 1 > 0 or year * 0.01 % 4 == 0)
end
local function date_is_valid()
	local day,month,year=tonumber(day),tonumber(month),tonumber(year)
	return year>=1900 and year<=9999 and month>0 and month<13 and day>0 and get_month_days(month)+(month==2 and is_leap_year(year) and 1 or 0)>=day or false
end
draw()
while true do
	local e,d,x,y=coroutine.yield()
	if e=="char" and d>="0" and d<="9" then
		_G[fields[cursor][1]]=(_G[fields[cursor][1]]..d):sub(fields[cursor][2]*(-1))
		draw()
	elseif e=="key" then
		if d==14 then -- backspace
			_G[fields[cursor][1]]=_G[fields[cursor][1]]:sub(1,-2)
			draw()
		elseif d==15 then -- tab
			cursor=cursor+1
			if cursor>#fields then
				cursor=1
			end
			draw()
		elseif d==28 then -- enter
			if date_is_valid() then
				_G.queue("set_date",num)
				break
			end
		end
	elseif e=="mouse_click" and y == 2 then
		local tmp=(click_x[x] or 0)
		if tmp==#fields+1 then
			if date_is_valid() then
				_G.queue("set_date",num)
				break
			end
		elseif tmp>0 then
			cursor=tmp
			draw()
		end
	end
end