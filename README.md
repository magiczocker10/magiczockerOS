# magiczockerOS
Official repository of magiczockerOS

**About this OS**
The magiczockerOS is designed to run on all [ComputerCraft](https://github.com/dan200/computercraft) and [CCTweaked](https://github.com/squiddev-cc/cc-tweaked) versions
and on some [OpenComputers](https://github.com/MightyPirates/OpenComputers) versions as well.
Also the OS can highly be customizable through the build-in settings.

**How to install:**
1. Download and extract the ZIP-File from the [releases-section](https://github.com/magiczocker10/magiczockerOS/releases) of this repository.
2. Create "/magiczockerOS/CC" and "/magiczockerOS/CCTweaked"
3. Download [io.lua](https://raw.githubusercontent.com/dan200/ComputerCraft/master/src/main/resources/assets/computercraft/lua/rom/apis/io.lua) to "/magiczockerOS/CC/io.lua"
4. Download [bios.lua](https://raw.githubusercontent.com/SquidDev-CC/CC-Tweaked/mc-1.15.x/src/main/resources/data/computercraft/lua/bios.lua) to /magiczockerOS/CCTweaked/bios.lua"
- This step is only required, if there is no "/rom/modules/main/cc/expect.lua" **and** you want to run it in CCTweaked-Based ComputerCraft existing.
5. Start the OS

**How to use the server.lua (Currently CC-Compatible only)**
1. Put the server.lua on the computer, which you want to use as a server.
2. Connect disk-drives to the computer.
3. Connect a modem to it. (Only wired-modem to wired-modem and wireless-modem to wireless-modem is possible in ComputerCraft)
4. Run it and create your first useraccount.

**The following included files are optional and can be removed, if you haven't enough space on your computer**
* /magiczockerOS/apis/math.lua
* /magiczockerOS/programs/calendar.lua
* /magiczockerOS/programs/contextmenu.lua
* /magiczockerOS/programs/login.lua (If at least one useraccount is existing)
* /magiczockerOS/programs/osk.lua
* /magiczockerOS/programs/search.lua
* /magiczockerOS/programs/settings.lua
