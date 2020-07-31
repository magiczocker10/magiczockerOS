-- magiczockerOS 3.0 - Copyright by Julian Kriete 2016-2020

-- My ComputerCraft-Forum account:
-- http://www.computercraft.info/forums2/index.php?showuser=57180
local running=true
multishell.setTitle(multishell.getCurrent(),mode.."   \""..title.."\"")
local data=user_data()
if not data.server then
	fs.set_root_path("/magiczockerOS/users/"..data.name.."/files/")
end
local function draw()
	term.setBackgroundColor(64)
	term.clear()
end
draw()
while running do
	local e,d,x,y=coroutine.yield()
	if e=="char" then
		running=false
	end
end
local file=fs.open("/desktop/abcd","w")
if file then
	file.write("Hallo Welt")
	file.close()
end
done=true