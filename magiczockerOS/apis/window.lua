-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local monitor_order=term and {{name="computer",offset=0}} or {}
local term=term or {isColor=function() return true end,setBackgroundColor=function() end,setTextColor=function() end}
local w,h=term.getSize and term.getSize() or 51,19
local total_size={0,0}
local monitor_mode="normal"
local monitor_list={
	back=true,
	bottom=true,
	front=true,
	left=true,
	right=true,
	top=true
}
local _computer_only={"computer"}
local validate_modes={
	["normal"]=true,
	["extend"]=true,
	["duplicate"]=true
}
local process_data={
	to_draw={},
	last=nil,
	last_cursor=nil,
	last_screen=nil
}
local global_cache
local global_cache_old
local global_visible=true
local com_term=term
local peri_call=nil
local peri_meth=nil
local peri_type=nil
local peri_names=nil
local header_tmp = {"", "", "", "", "", "", "", "", ""}
-- both variables for get_nearest_scale
local _size={0,0}
local pixel_size={6,9}
local cdo_args={0,0}
local get_color={}
local hex={}
for i=1,16 do
	local tmp=2^(i-1)
	hex[tmp]=("0123456789abcdef"):sub(i,i)
	get_color[hex[tmp]]=tmp
end
local last_palette={mode=1,inverted=false,original=false}
local color_palette={
	new={
		{240,240,240}, -- white
		{242,178,51}, -- orange
		{229,127,216}, -- magenta
		{153,178,242}, -- lightBlue
		{222,222,108}, -- yellow
		{127,204,25}, -- lime
		{242,178,204}, -- pink
		{76,76,76}, -- gray
		{153,153,153}, -- lightGray
		{76,153,178}, -- cyan
		{178,102,229}, -- purple
		{51,102,204}, -- blue
		{127,102,76}, -- brown
		{87,166,78}, -- green
		{204,76,76}, -- red
		{17,17,17} -- black
	},
	original={
		{240,240,240}, -- white
		{235,136,68}, -- orange
		{195,84,205}, -- magenta
		{102,137,211}, -- lightBlue
		{222,222,108}, -- yellow
		{65,205,52}, -- lime
		{216,129,152}, -- pink
		{67,67,67}, -- gray
		{153,153,153}, -- lightGray
		{40,118,151}, -- cyan
		{123,47,190}, -- purple
		{37,49,146}, -- blue
		{81,48,26}, -- brown
		{59,81,26}, -- green
		{179,49,44}, -- red
		{0,0,0} -- black
	}
}
local function copy_table(a,b)
	local b, c = b or {}, {}
	b[a] = true
	for k, v in next, a do
		c[k], b = type(v) == "table" and not b[a] and copy_table(v, b) or v, b
	end
	return c, b
end
function set_peripheral(object)
	peri_call=object and object.call or nil
	peri_meth=object and object.getMethods or nil
	peri_type=object and object.getType or nil
	peri_names=object and object.getNames or nil
end
function set_global_visible(status)
	if type(status)=="boolean" then
		global_visible=status
	end
end
function get_global_visible()
	return global_visible
end
function clear_cache()
	global_cache={}
	global_cache_old={}
end
local to_log
local logger=false
local function set_term(device,mode,...)
	for i=((monitor_mode=="duplicate" and 1) or device or 1),((monitor_mode=="duplicate" and #monitor_order) or device or 1) do
		if monitor_order[i].name=="computer" then
			if logger then -- for debugging
				to_log[#to_log+1]={mode,...}
			end
			if com_term[mode] then
				com_term[mode](...)
			end
		elseif peri_call and peri_meth(monitor_order[i].name) then
			peri_call(monitor_order[i].name,mode,...)
		end
	end
end
function set_logger(state)
	logger=state
	if state then
		to_log={}
	else
		local a=fs.open("log_data","w")
		a.write(textutils.serialize(to_log))
		a.close()
	end
end
local function get_nearest_scale(mode,device,length)
	local _mode=mode=="width" and 1 or 2
	peri_call(device,"setTextScale",0.5)
	_size[1],_size[2]=peri_call(device,"getSize")
	local _=pixel_size[_mode]/(_size[_mode] or 1)
	for i=5,0.5,-.5 do
		if length<=(pixel_size[_mode]/(_*(i+i))) then
			return i
		end
	end
	return 0.5
end
local function calculate_device_offset()
	local cur_offset=0
	local total_width=0
	w,h=nil
	local mon_len=#monitor_order
	for i=1,mon_len do
		if monitor_order[i].name=="computer" then
			_size[1],_size[2]=term.getSize()
		else
			peri_call(monitor_order[i].name,"setTextScale",0.5)
			_size[1],_size[2]=peri_call(monitor_order[i].name,"getSize")
		end
		w=(not w or w>_size[1]) and _size[1] or w
		h=(not h or h>_size[2]) and _size[2] or h
	end
	for i=1,mon_len do
		local mo=monitor_order[i]
		if mo.name~="computer" then
			local _w, _h = get_nearest_scale("width",mo.name,w), get_nearest_scale("height",mo.name,h)
			peri_call(mo.name,"setTextScale",5) -- Force the event "monitor_resize" to fire
			local _ = _w>_h and _h or _w
			cdo_args[1], cdo_args[2] = _ - 0.5, _ + 0.5
			cdo_args[1], cdo_args[2] = cdo_args[1] < 0.5 and 0.5 or cdo_args[1], cdo_args[2] > 5 and 5 or cdo_args[2]
			for j=cdo_args[2],cdo_args[1],-0.5 do
				peri_call(mo.name,"setTextScale",j)
				local tmp = {peri_call(mo.name,"getSize")}
				if tmp[1]>=w and tmp[2]>=h then
					break
				end
			end
		end
		_size=mo.name=="computer" and {term.getSize()} or {peri_call(mo.name,"getSize")}
		mo.height=_size[2]
		mo.startx=cur_offset+1
		mo.endx=cur_offset+_size[1]
		mo.offset=cur_offset
		cur_offset=monitor_mode=="extend" and cur_offset+_size[1] or 0
		total_width=total_width+_size[1]
		if monitor_mode~="extend" then
			if i==1 then
				w=_size[1]
				h=_size[2]
				total_size[1]=w
				total_size[2]=h
			end
		end
		h = monitor_mode=="extend" and h > _size[2] and _size[2] or h
	end
	if monitor_mode=="extend" then
		w=total_width
		total_size[1], total_size[2] = total_width, h
	end
end
function get_devices()
	return monitor_order
end
function get_size()
	return total_size[1],total_size[2]
end
function set_devices(mode,...)
	monitor_mode=validate_modes[mode] and mode or "normal"
	local list=monitor_mode=="normal" and _computer_only or {...}
	local to_clear={}
	if type(monitor_order)=="table" then
		for i=1,#monitor_order do
			to_clear[monitor_order[i].name]=true
		end
	end
	monitor_order={}
	local processed={}
	local pd=process_data
	pd.last_backcolor=pd.last_backcolor or {}
	pd.last_textcolor=pd.last_textcolor or {}
	for i=1,#list do
		if not processed[list[i]] then
			processed[list[i]]=true
			if list[i]=="computer" or (peri_names and peri_type and peri_type(list[i])=="monitor") then
				pd.last_backcolor[list[i]]=-1
				pd.last_textcolor[list[i]]=-1
				if list[i]~="computer" and peri_type and peri_type(list[i])=="monitor" then
					peri_call(list[i],"setBackgroundColor",32768)
					peri_call(list[i],"clear")
				elseif list[i]=="computer" then
					if term.setBackgroundColor then
						term.setBackgroundColor(32768)
					end
					term.clear()
				end
				to_clear[list[i]]=nil
				monitor_order[#monitor_order+1]={name=list[i]}
			end
		end
	end
	for k in next,to_clear do
		if k=="computer" then
			if term.setBackgroundColor then
				term.setBackgroundColor(32768)
			end
			term.clear()
		elseif peri_call then
			peri_call(k,"setBackgroundColor",32768)
			peri_call(k,"clear")
		end
	end
	monitor_order[#monitor_order + 1] = #monitor_order == 0 and {name = "computer"} or nil
	calculate_device_offset()
	clear_cache()
end
local function can_added(data,to_add,x)
	if #data[2]==0 or data[1]==x-#data[2] and to_add.b==data[3] and (to_add.s==" " or data[4]==-1 or to_add.t==data[4]) then
		if #data[2]==0 then
			data[1]=x
			data[3]=to_add.b
			data[4]=-1
		end
		data[4]=data[4]==-1 and to_add.s~=" " and to_add.t or data[4]
		data[2][#data[2]+1]=to_add.s
		return true
	end
	return false
end
function draw_text(screen,data,new,line,rdata)
	if #new[2]==0 then
		return nil
	end
	if rdata then
		rdata[#rdata+1]={copy_table(data),copy_table(new),line}
	end
	if data[1]<1 or data[1]~=new[1] then
		set_term(screen,"setCursorPos",new[1]-monitor_order[screen].startx+1,line)
		data[1]=new[1]+#new[2]
	end
	if data[2]~=new[3] then
		data[2]=new[3]
		set_term(screen,"setBackgroundColor",new[3])
	end
	if new[4]>0 and data[3]~=new[4] then
		data[3]=new[4]
		set_term(screen,"setTextColor",new[4])
	end
	set_term(screen,"write",table.concat(new[2],""))
end
function redraw_global_cache_line(check_changes,line,startx,endx,return_data)
	if not global_visible or not line or line>h or not global_cache[line] then
		return nil
	end
	local monitor_mode_=monitor_mode
	monitor_mode=return_data and "extend" or monitor_mode
	local startxorg=startx
	local endxorg=endx
	local to_repeat={}
	local goto_limit = return_data and 1 or #monitor_order
	for screen=1,goto_limit do
		local s=monitor_order[screen]
		local startx=math.max(startxorg or s.startx,s.startx)
		local endx=math.min(endxorg or s.endx,s.endx)
		local limit_set = return_data or startxorg and endxorg
		local continue = endx>=startx and startx<=s.endx and s.startx<=endx
		local to_draw={-1,{},-1,-1} -- x, text, bcol, tcol
		local cur_data={0,-1,-1} -- x, backc, textc
		local _line=global_cache[line]
		local _line_old=global_cache_old[line] or {}
		global_cache_old[line]=global_cache_old[line] or {}
		startx,endx=not continue and 1 or startx,not continue and 0 or endx
		for i=startx,endx do
			local a,b=_line and _line[i],_line_old and _line_old[i]
			if a and (not check_changes or not b or ((a.b~=b.b or a.t~=b.t or a.s~=b.s) and not (a.b==b.b and a.s==" " and b.s==" "))) then
				if not can_added(to_draw,a,i) then
					draw_text(screen,cur_data,to_draw,line,return_data and to_repeat)
					to_draw[2]={}
					to_draw[4]=-1
					can_added(to_draw,a,i)
				end
				local tmp=global_cache_old[line]
				tmp[i]=tmp[i] or {}
				tmp[i].b=to_draw[3]
				tmp[i].t=(to_draw[4]<1 and a.t or to_draw[4])
				tmp[i].s=a.s
				_line[i]=not (limit_set and screen==goto_limit) and _line[i] or nil
			end
		end
		draw_text(screen,cur_data,to_draw,line,return_data and to_repeat)
	end
	local empty=true
	if limit_set then
		for k in next,global_cache[line] do
			empty=false
			break
		end
	end
	global_cache[line], monitor_mode=not (empty or not limit_set and screen==goto_limit) and global_cache[line] or nil, monitor_mode_
	return to_repeat
end
function redraw_global_cache(check_changes)
	local rd={}
	for i=1,h do
		rd[#rd+1]=redraw_global_cache_line(check_changes,i,nil,nil,monitor_mode=="duplicate")
	end
	local monitor_mode_, monitor_mode = monitor_mode, "extend"
	for i=2,monitor_mode_=="duplicate" and #monitor_order or 1 do
		for j=1,#rd do
			local tmp=rd[j]
			for k=1,#tmp do
				draw_text(i,copy_table(tmp[k][1]),copy_table(tmp[k][2]),tmp[k][3])
			end
		end
	end
	monitor_mode=monitor_mode_
end
function get_global_cache(a, b, c) -- Returns the screen / the specified window in the nft-format.
	local d = {}
	local e = {(" "):rep(total_size[1])}
	local f = {b = 32768}
	for i = c and 2 or 1, c or total_size[2] do
		local old_col = {nil, nil} -- back, text
		d[#d + 1] = {}
		local g, h = global_cache_old[i] or f, d[#d]
		d[#d] = g and d[#d] or e
		for j = 1, b or total_size[1] do
			if g[j] then
				if (g[j].b or g[j].back) ~= old_col[1] then
					h[#h + 1] = ("30"):char()
					old_col[1] = g[j].b or g[j].back
					h[#h + 1] = old_col[1]
				end
				if (g[j].t or g[j].text or old_col[2]) ~= old_col[2] then
					h[#h + 1] = ("31"):char()
					old_col[2] = g[j].t or g[j].text
					h[#h + 1] = old_col[2]
				end
			end
			h[#h + 1] = g[j] and (g[j].s or g[j].char) or " "
		end
		d[#d] = h and table.concat(h, "") or d[#d]
	end
	return table.concat(d, "\n")
end
local cp={
	nil,
	{.618,.320,.062,.163,.775,.062,.163,.320,.516}, -- achromatomaly *
	{.299,.587,.114,.299,.587,.114,.299,.587,.114}, -- achromatopsia / gray | https://de.wikipedia.org/wiki/YUV-Farbmodell
	{.8,.2,0,.258,.742,0,0,.142,.858}, -- deuteranomaly *
	{.625,.375,0,.7,.3,0,0,.3,.7}, -- deuteranopia *
	{.817,.183,0,.333,.667,0,0,.125,.875}, -- protanomaly *
	{.567,.433,0,.558,.442,0,0,.242,.758}, -- protanopia *
	{.393,.769,.189,.349,.686,.168,.272,.534,.131}, -- sepia
	{.967,.033,0,0,.733,.267,0,.183,.817}, -- tritanomaly *
	{.95,.05,0,0,.433,.567,0,.475,.525}, -- tritanopia *
} -- * https://www.reddit.com/r/gamedev/comments/2i9edg/code_to_create_filters_for_colorblind/
function reload_color_palette(settings)
	if (term.isColor and term.isColor()) and term.setPaletteColor then
		if (settings.color_mode or 1)~=last_palette.mode or (settings.invert_colors or false)~=last_palette.inverted or (settings.original_colors or false)~=last_palette.original then
			last_palette={mode=settings.color_mode or 1,inverted=settings.invert_colors,original=settings.original_colors}
			local _=settings.original_colors and "original" or "new"
			local function round(num)
				return (num%1>=0.5 and ceil(num)) or floor(num)
			end
			for i = 1, 16 do
				local temp_color={color_palette[_][i][1],color_palette[_][i][2],color_palette[_][i][3]}
				local red
				local green
				local blue
				local b=cp[settings.color_mode]
				red=b and round(temp_color[1]*b[1]+temp_color[2]*b[2]+temp_color[3]*b[3]) or nil
				green=b and round(temp_color[1]*b[4]+temp_color[2]*b[5]+temp_color[3]*b[6]) or nil
				blue=b and round(temp_color[1]*b[7]+temp_color[2]*b[8]+temp_color[3]*b[9]) or nil
				local c = settings.color_mode and settings.color_mode > 1
				temp_color[1] = c and (red>255 and 255 or red) or temp_color[1]
				temp_color[2] = c and (green>255 and 255 or green) or temp_color[2]
				temp_color[3] = c and (blue>255 and 255 or blue) or temp_color[3]
				c = settings.invert_colors
				temp_color[1] = c and 255-temp_color[1] or temp_color[1]
				temp_color[2] = c and 255-temp_color[2] or temp_color[2]
				temp_color[3] = c and 255-temp_color[3] or temp_color[3]
				for j=1, monitor_mode=="normal" and 1 or #monitor_order do
					set_term(j,"setPaletteColor",2^(i-1),1/255*temp_color[1],1/255*temp_color[2],1/255*temp_color[3])
				end
			end
		end
	end
end
function create(x,y,width,height,visible,bar)
	if type(x)~="number" then error("bad argument #2 (expected number, got "..type(x)..")",2) end
	if type(y)~="number" then error("bad argument #3 (expected number, got "..type(y)..")",2) end
	if type(width)~="number" then error("bad argument #4 (expected number, got "..type(width)..")",2) end
	if type(height)~="number" then error("bad argument #5 (expected number, got "..type(height)..")",2) end
	if visible~=nil and type(visible)~="boolean" then error("bad argument #6 (expected boolean, got "..type(visible)..")",2) end
	-- variables
	local back_color=32768
	local blink=false
	local can_draw=true
	local id=0
	local state="normal"
	local text_color=1
	local border=false
	local has_border=false
	local title=""
	visible=type(visible) == "nil" and true or visible
	-- tables
	local color_codes={
		[1]={240,240,240}, -- white
		[2]={242,178,51}, -- orange
		[4]={229,127,216}, -- magenta
		[8]={153,178,242}, -- lightBlue
		[16]={222,222,108}, -- yellow
		[32]={127,204,25}, -- lime
		[64]={242,178,204}, -- pink
		[128]={76,76,76}, -- gray
		[256]={153,153,153}, -- lightGray
		[512]={76,153,178}, -- cyan
		[1024]={178,102,229}, -- purple
		[2048]={51,102,204}, -- blue
		[4096]={127,102,76}, -- brown
		[8192]={87,166,78}, -- green
		[16384]={204,76,76}, -- red
		[32768]={17,17,17} -- black
	}
	local cursor={1,1}
	local data={
		maximized={
			height=total_size[2]-1,
			width=total_size[1],
			x=1,
			y=2
		},
		normal={
			height=height,
			width=width,
			x=x,
			y=y
		}
	}
	local screen={}
	local screen2={}
	local settings={}
	local window={}
	local redraw_line
	local my_blink=true
	-- functions
	local function set_size(y)
		local _=screen[y]
		local __=data[state].width
		_=_ or {
			back=hex[back_color]:rep(__),
			char=(" "):rep(__),
			text=hex[text_color]:rep(__)
		}
		if __>#_.char then
			screen[y]={back=_.back..hex[back_color]:rep(__-#_.back),char=_.char..(" "):rep(__-#_.char),text=_.text..hex[text_color]:rep(__-#_.text)}
		elseif __<#_.char then
			screen[y]={back=_.back:sub(1,__),char=_.char:sub(1,__),text=_.text:sub(1,__)}
		end
	end
	local function set_cursor()
		if not global_visible then
			return
		end
		local success=false
		local _data=data[state]
		local _x=_data.x+cursor[1]-1
		local _y=_data.y+cursor[2]-(bar and 0 or 1)
		if not border or (border and cursor[1]>1 and cursor[1]<_data.width and cursor[2]>0 and cursor[2]<_data.height) then
			if id==0 or (screen2[_y] and screen2[_y][_x]==id) then
				success=true
			end
		end
		if success then
			for i=(monitor_mode=="extend" and #monitor_order or 1),1,-1 do
				if _x>monitor_order[i].offset then
					if term.setCursorBlink then
						if blink then
							process_data.last_textcolor[i]=text_color
							set_term(i,"setTextColor",text_color)
							set_term(i,"setCursorPos",_x-monitor_order[i].offset,_y)
						end
						set_term(i,"setCursorBlink",blink)
					elseif my_blink and blink then
						process_data.last_textcolor[i]=text_color
						local tmpy = cursor[2]+(bar and 1 or 0)
						local sdata=screen[tmpy]
						if sdata and cursor[1]>0 and #sdata.back>=cursor[1] then
							local btmp=get_color[sdata.back:sub(cursor[1],cursor[1])]
							process_data.last_backcolor[i]=btmp
							set_term(i,"setBackgroundColor",btmp)
							set_term(i,"setTextColor",text_color)
							set_term(i,"setCursorPos",_x-monitor_order[i].offset,_y)
							set_term(i,"write","#")
						end
					elseif not my_blink then
						local xpos,ypos=_x-monitor_order[i].offset,_y
						local tmpy = cursor[2]+(bar and 1 or 0)
						local sdata = screen[tmpy]
						if sdata and cursor[1]>0 and #sdata.back>=cursor[1] then
							process_data.last_backcolor[i]=get_color[sdata.back:sub(cursor[1],cursor[1])]
							process_data.last_textcolor[i]=get_color[sdata.text:sub(cursor[1],cursor[1])]
							set_term(i,"setBackgroundColor",get_color[sdata.back:sub(cursor[1],cursor[1])])
							set_term(i,"setTextColor",get_color[sdata.text:sub(cursor[1],cursor[1])])
							set_term(i,"setCursorPos",_x-monitor_order[i].offset,_y)
							set_term(i,"write",sdata.char:sub(cursor[1],cursor[1]))
						end
					end
					break
				end
			end
		end
	end
	function window.get_screen()
		return get_global_cache(screen2, data[state].width, data[state].height - (bar and 1 or 0))
	end
	function window.toggle_cursor_blink()
		if blink or my_blink then
			my_blink = not my_blink
			set_cursor()
		end
	end
	local function create_header(foreground)
		local _={"","","","","","","","",""}
		local conf=settings
		if term.isColor and term.isColor() then
			_[1]=_[1]..(foreground and hex[conf.window_close_button_active_back or 128] or hex[conf.window_close_button_inactive_back or 128])
			_[2]="o"
			_[3]=_[3]..(foreground and hex[conf.window_close_button_active_text or 2048] or hex[conf.window_close_button_inactive_text or 256])
			if id>0 then
				_[1]=_[1]..(foreground and hex[conf.window_maximize_button_active_back or 128] or hex[conf.window_maximize_button_inactive_back or 128])
				_[2]=_[2].."o"
				_[3]=_[3]..(foreground and hex[conf.window_maximize_button_active_text or 512] or hex[conf.window_maximize_button_inactive_text or 256])
				_[1]=_[1]..(foreground and hex[conf.window_minimize_button_active_back or 128] or hex[conf.window_minimize_button_inactive_back or 128])
				_[2]=_[2].."o"
				_[3]=_[3]..(foreground and hex[conf.window_minimize_button_active_text or 8] or hex[conf.window_minimize_button_inactive_text or 256])
			end
		end
		_[4]=(((term.isColor and term.isColor() and " ") or "=")..title..((term.isColor and term.isColor() and " ") or "="):rep(data[state].width)):sub(1,(term.isColor and term.isColor() and data[state].width-(id>0 and 4 or 1)) or data[state].width)
		local __=foreground
		if term.isColor and term.isColor() then
			if __ then
				_[5]=hex[conf.window_bar_active_back or 128]
				_[6]=hex[conf.window_bar_active_text or 1]
			else
				_[5]=hex[conf.window_bar_inactive_back or 128]
				_[6]=hex[conf.window_bar_inactive_text or 1]
			end
		elseif textutils and type(textutils.complete)=="function" then
			_[5]="7"
			_[6]=__ and "0" or "8"
		else
			_[5]=__ and "0" or "f"
			_[6]=__ and "f" or "0"
		end
		local a = term.isColor and term.isColor()
		_[7]=a and hex[conf.window_resize_button_back or 128] or _[7]
		_[8]=a and ((foreground and state=="normal" and id>0 and "o") or " ") or _[8]
		_[9]=a and hex[conf.window_resize_button_text or 256] or _[9]
		header_tmp[1], header_tmp[2], header_tmp[3] = _[1], _[5]:rep(#_[4]), _[7]
		header_tmp[4], header_tmp[5], header_tmp[6] = _[2], _[4], _[8]
		header_tmp[7], header_tmp[8], header_tmp[9] = _[3], _[6]:rep(#_[4]), _[9]
		screen[1] = {
			back = table.concat(header_tmp, "", 1, 3),
			char = table.concat(header_tmp, "", 4, 6),
			text = table.concat(header_tmp, "", 7, 9)
		}
	end
	function redraw_line(line,pos_start,pos_end)
		local cur_data=data[state]
		pos_start=pos_start and pos_end and (pos_start<1 and 1 or pos_start) or nil
		pos_end=pos_start and pos_end and (pos_end>cur_data.width and cur_data.width or pos_end) or nil
		if visible and can_draw then
			line=line or cursor[2]+(bar and 1 or 0)
			if line>0 and line<=cur_data.height then
				local _ypos=cur_data.y+line-1
				screen2[_ypos]=screen2[_ypos] or {}
				local _=screen2[_ypos]
				screen[line]=screen[line] or {back="",char="",text=""}
				if #screen[line].char<cur_data.width then
					set_size(line)
				end
				local border_h
				local border_w
				for i=pos_start or 1,pos_end or cur_data.width do
					local _pos=cur_data.x+i-1
					_[_pos]=_[_pos] or id
					if _[_pos]==id then
						global_cache[_ypos]=global_cache[_ypos] or {}
						if border and (line==cur_data.height or ((i==1 or i==cur_data.width) and line>1)) then
							local a = not border_w or not border_h
							border_w, border_h=a and ceil(cur_data.width*.5) or border_w, a and ceil(cur_data.height*.5) or border_h
							global_cache[_ypos][_pos]={t=settings.window_resize_border_text or 1,b=settings.window_resize_border_back or 128,s=(line==border_h and "|") or (i==border_w and "-") or " "}
						else
							local _line=screen[line]
							global_cache[_ypos][_pos]={t=(get_color[_line.text:sub(i,i)] or text_color),b=(get_color[_line.back:sub(i,i)] or back_color),s=(_line.char:sub(i,i) or " ")}
						end
					end
				end
			end
		end
	end
	local function redraw()
		if visible then
			local new_screen={}
			for i=1,data[state].height do
				redraw_line(i)
				new_screen[i]=screen[i]
			end
			screen=new_screen
		end
	end
	function window.has_header()
		return bar
	end
	-- window functions
	function window.drawable(state)
		can_draw=state~=can_draw and state or can_draw
	end
	function window.get_data(sstate)
		sstate=data[sstate] and sstate or nil
		local _data=data[sstate or state]
		return _data.x,_data.y,_data.width,_data.height
	end
	function window.get_state()
		return state
	end
	function window.get_title()
		return title
	end
	function window.get_visible()
		return visible
	end
	function window.redraw(foreground,tScreen,nID)
		screen2=tScreen or {}
		id=nID or 0
		if bar then
			create_header(foreground)
		end
		redraw()
		return screen2
	end
	function window.reposition(nX,nY,nWidth,nHeight,sstate)
		sstate=data[sstate] and sstate or nil
		local _data=data[sstate or state]
		_data.x=nX
		_data.y=nY
		_data.width=nWidth
		_data.height=nHeight
	end
	function window.restore_cursor()
		set_cursor()
	end
	function window.set_state(sState)
		if data[sState] then
			state=sState
			border=false
			create_header(true)
			redraw()
			redraw_global_cache(true)
		end
	end
	function window.set_title(new_title,foreground)
		if not foreground then
			my_blink = false
		end
		title=new_title
		create_header(foreground)
		redraw_line(1)
		redraw_global_cache_line(false,data[state].y)
		set_cursor()
	end
	function window.set_visible(bVisible)
		visible=bVisible
	end
	function window.settings(new,foreground)
		settings=new
		if bar then
			create_header(foreground)
			redraw_line(1)
			redraw_global_cache_line(false,data[state].y+(bar and 1 or 0))
			set_cursor()
		end
	end
	function window.toggle_border(bVisible)
		border=bVisible
		redraw()
		redraw_global_cache(true)
	end
	-- term functions
	local function _blit(sText,sTextColor,sBackgroundColor)
		if type(sText)~="string" then error("bad argument #1 (expected string, got "..type(sText)..")",2) end
		if type(sTextColor)~="string" then error("bad argument #2 (expected string, got "..type(sTextColor)..")",2) end
		if type(sBackgroundColor)~="string" then error("bad argument #3 (expected string, got "..type(sBackgroundColor)..")",2) end
		local text_len=#sText
		if #sTextColor~=text_len or #sBackgroundColor~=text_len then
			error("Arguments must be the same length",2)
		end
		if cursor[2]<1 then
			return
		end
		local cur=cursor[1]-1
		local y=cursor[2]+(bar and 1 or 0)
		screen[y]=screen[y] or {} -- hallo
		screen[y].back=((screen[y].back or "")..("f"):rep(cur)):sub(1,cur)..sBackgroundColor..(screen[y].back or ""):sub(cursor[1]+text_len)
		screen[y].text=((screen[y].text or "")..("0"):rep(cur)):sub(1,cur)..sTextColor..(screen[y].text or ""):sub(cursor[1]+text_len)
		screen[y].char=((screen[y].char or "")..(" "):rep(cur)):sub(1,cur)..sText..(screen[y].char or ""):sub(cursor[1]+text_len)
		redraw_line(y,cursor[1],cur+text_len)
		redraw_global_cache_line(true,data[state].y+y-1,data[state].x+cur,data[state].x+cur+text_len)
		cursor[1]=cursor[1]+text_len
		set_cursor()
	end
	if term.isColor and term.isColor() then
		function window.blit(sText,sTextColor,sBackgroundColor)
			_blit(sText,sTextColor,sBackgroundColor)
		end
	end
	function window.clear()
		screen={bar and screen[1] or nil}
		redraw()
		redraw_global_cache(false)
		set_cursor()
	end
	function window.clearLine()
		screen[cursor[2]+(bar and 1 or 0)]=nil
		redraw_line()
		redraw_global_cache_line(true,data[state].y+cursor[2]+(bar and 1 or 0)-1)
		set_cursor()
	end
	if term.setBackgroundColor then
		function window.getBackgroundColor()
			return back_color
		end
		window.getBackgroundColour=window.getBackgroundColor
	end
	function window.getCursorBlink()
		return blink
	end
	function window.getCursorPos()
		return cursor[1],cursor[2]
	end
	if term.setPaletteColor then
		function window.getPaletteColor(color)
			if type(color)~="number" then error("bad argument #1 (expected number, got "..type(color)..")",2) end
			if color_codes[color]==nil then
				error("Invalid color (got "..color..")",2)
			end
			return color_codes[color][1],color_codes[color][2],color_codes[color][3]
		end
		window.getPaletteColour=window.getPaletteColor
	end
	function window.nativePaletteColor(num)
		local tmp=color_palette[settings.original_colors and "original" or "new"]
		for i=0,15 do
			if (2^i)==num then
				return tmp[i+1][1],tmp[i+1][2],tmp[i+1][3]
			end
		end
		return 0,0,0
	end
	function window.getSize()
		return data[state].width,data[state].height-(bar and 1 or 0)
	end
	if term.setTextColor then
		function window.getTextColor()
			return text_color
		end
		window.getTextColour=window.getTextColor
	end
	if term.isColor then
		function window.isColor()
			return term.isColor()
		end
		window.isColour=window.isColor
	end
	function window.scroll(n)
		if type(n)~="number" then error("bad argument #1 (expected number, got "..type(n)..")",2) end
		if n~=0 then
			if n>0 then
				for i=1,n do
					if screen[1+(bar and 1 or 0)] then
						table.remove(screen,1+(bar and 1 or 0))
					end
				end
			else
				for i=n,-1 do
					screen[data[state].height]=nil
					table.insert(screen,1+(bar and 1 or 0),{back="",char="",text=""})
				end
			end
			redraw()
			redraw_global_cache(true)
		end
	end
	if term.setBackgroundColor then
		function window.setBackgroundColor(color)
			if type(color)~="number" then error("bad argument #1 (expected number, got "..type(color)..")",2) end
			back_color=color
		end
		window.setBackgroundColour=window.setBackgroundColor
	end
	function window.setCursorBlink(_)
		if type(_)~="boolean" then error("bad argument #1 (expected boolean, got "..type(_)..")",2) end
		my_blink, blink = true, _
		set_cursor()
	end
	function window.setCursorPos(x_,y_)
		if type(x_)~="number" then error("bad argument #1 (expected number, got "..type(x_)..")",2) end
		if type(y_)~="number" then error("bad argument #2 (expected number, got "..type(y_)..")",2) end
		local mb=my_blink
		if not term.setCursorBlink then
			my_blink = false
			set_cursor()
		end
		cursor[1], cursor[2], my_blink = floor(x_), floor(y_), mb
		set_cursor()
	end
	if term.setTextColor then
		function window.setTextColor(color)
			if type(color)~="number" then error("bad argument #1 (expected number, got "..type(color)..")",2) end
			text_color=color
		end
		window.setTextColour=window.setTextColor
	end
	if term.setPaletteColor then
		function window.setPaletteColour(color,r,g,b)
			if type(color)~="number" then error("bad argument #1 (expected number, got "..type(color)..")",2) end
			if color_codes[color]==nil then
				error("Invalid color (got "..color..")",2)
			end
			local new_color={}
			if type(r)=="number" and g==nil and b==nil then
				new_color={colours.rgb8(r)}
			else
				if type(r)~="number" then error("bad argument #2 (expected number, got "..type(r)..")",2) end
				if type(g)~="number" then error("bad argument #3 (expected number, got "..type(g)..")",2) end
				if type(b)~="number" then error("bad argument #4 (expected number, got "..type(b)..")",2) end
				new_color[1],new_color[2],new_color[3]=r,g,b
			end
			color_codes[color]=new_color
		end
		window.setPaletteColor=window.setPaletteColour
	end
	function window.write(sText)
		local text_type=type(sText)
		if text_type~="string" and text_type~="number" then error("bad argument #1 (expected string, got "..text_type..")",2) end
		sText=sText..""
		local text_len=#sText
		_blit(sText,hex[text_color]:rep(text_len),hex[back_color]:rep(text_len))
	end
	return window
end