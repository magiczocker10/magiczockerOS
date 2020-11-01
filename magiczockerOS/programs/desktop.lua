-- magiczockerOS - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local w,h = term.getSize()
h = h - 2
local folder = "/desktop"
local items = fs.exists(folder) and fs.list(folder) or {}
local offset = 0
local selected = 0
local last_click = {0,0,os.clock()}
local iconw, iconh = 10, 4
local iconsw, iconsh = math.floor(w/(iconw+1)), math.floor(h/(iconh+1))
local borderw, borderh = (w-((iconw+1)*iconsw-1))*0.5, (h-((iconh+1)*iconsh-1))*0.5
local page = 1
local pages = math.ceil(#items/(iconsw*iconsh))
local icon = {
	file = {">_  ","prog","    "},
	folder = {"  ","    ","Fldr"}
}
local col = {}
local col_ = 3
for i = 0, 15 do
	col[i] = (i+8)%16
end
local function invert()
	col_=col[col_]
	term.setBackgroundColor(2^col_)
end
local function draw_icon(id,line,x)
	if id then
		if id == 0 then
			return
		end
		x = id
		local tmp = math.floor((id-1)/iconsw)
		term.setCursorPos(borderw+1+(id-(tmp*iconsw)-1)*(iconw+1),borderh+line+tmp*(iconh+1))
	end
	if selected == offset+x then
		invert()
	end
	local tmpName = items[offset+x] or ""
	if line < 4 then
		local tmp2 = #tmpName>0 and (fs.isDir(folder..tmpName) and "folder" or "file") or "empty"
		term.write("   ")
		if term.isColor and tmp2~="empty" then
			invert()
			term.write(icon[tmp2][line])
			invert()
			if #icon[tmp2][line]<4 then
				term.write((" "):rep(4-#icon[tmp2][line]))
			end
		else
			term.write("    ")
		end
		term.write("   ")
	else
		term.setTextColor(32768)
		local tmp2 = tmpName:sub(1,(tmpName:find("%.") or #tmpName + 1) - 1):sub(1,10)
		local tmp3 = (10-#tmp2)*0.5
		term.write((" "):rep(math.floor(tmp3))..tmp2..(" "):rep(math.ceil(tmp3)))
		term.setTextColor(1)
	end
	if selected == offset+x then
		invert()
	end
end
local function draw()
	local _width, _f, _c = (" "):rep(w), math.floor(borderh), math.ceil(borderh)
	term.setBackgroundColor(8)
	for y = 1, h do
		term.setCursorPos(1,y)
		if y < _f or y > h-_c then
			term.write(_width)
		elseif (y-_f)%5 == 0 then
			term.write(_width)
			offset = offset + iconsw
		else
			if offset >= #items then
				term.write(_width)
			else
				term.write((" "):rep(math.floor(borderw)))
				local line = (y-_f)%5
				for x = 1, iconsw do
					draw_icon(nil,line,x)
					if x < iconsw then
						term.write(" ")
					end
				end
				term.write((" "):rep(math.ceil(borderw)))
			end
		end
	end
	offset = 0
	term.setCursorPos(1,h+1)
	term.write((" "):rep(math.floor((w-(pages*2-1))*0.5)))
	for x = 1,pages do
		term.setBackgroundColor(1)
		term.setTextColor(32768)
		term.write(x==page and "#" or " ")
		term.setBackgroundColor(8)
		if x<pages then
			term.write(" ")
		end
	end
	term.write((" "):rep(math.ceil((w-(pages*2-1))*0.5)))
	term.setCursorPos(1,h+2)
	term.write(_width)
end
draw()
while true do
	local e,d,x,y = coroutine.yield()
	if e == "user" then
		items = fs.exists(folder) and fs.list(folder) or {}
		pages = math.ceil(#items/(iconsw*iconsh))
		draw()
	elseif e == "mouse_click" then
		if x == last_click[1] and y == last_click[2] and os.clock() - last_click[3] < 0.2 and selected > 0 then
			local tmp = folder..items[selected]
			if fs.isDir(tmp) then
				error("Launcher explorer..")
			else
				error("Launching program..")
			end
		else
			-- if x == last_click[1] and y == last_click[2] and ((y-math.floor(borderh))/(iconh+1))%1 == 0.8 and selected > 0 then
				-- error("Rename..")
			-- else
				last_click = {x,y,os.clock()}
				local bw, bh = math.floor(borderw), math.floor(borderh)
				local tmp = selected
				if x > bw and x < w-bw+1 and y > bh and y < h-bh+1 then
					x, y = x - bw, y - bh
					selected = ((x/(iconw+1))%1 == 0 or (y/(iconh+1))%1 == 0) and 0 or math.floor(y/(iconh+1))*iconsw+math.floor(x/(iconw+1))+1
					selected = selected>#items and 0 or selected
				else
					selected = 0
				end
				if selected ~= tmp then
					for y = 1,iconh do
						draw_icon(tmp,y)
						draw_icon(selected,y)
					end
				end
			-- end
		end
	elseif e == "term_resize" then
		w, h = term.getSize()
		h = h - 2
		iconsw, iconsh = math.floor(w/(iconw+1)), math.floor(h/(iconh+1))
		borderw, borderh = (w-((iconw+1)*iconsw-1))*0.5, (h-((iconh+1)*iconsh-1))*0.5
		draw()
	end
end