# magiczockerOS
Official repository of magiczockerOS

## About this OS
The magiczockerOS is designed to run on all [ComputerCraft](https://github.com/dan200/computercraft) and [CCTweaked](https://github.com/squiddev-cc/cc-tweaked) versions
and on some [OpenComputers](https://github.com/MightyPirates/OpenComputers) versions as well.
Also the OS can highly be customizable through the build-in settings.

## How to install:
1. Download and extract the ZIP-File from the [releases-section](https://github.com/magiczocker10/magiczockerOS/releases) of this repository to the root-directoy of your computer `computer/<id>/`.
2. Start the OS

## Planned changes for this branch
* Only taskbar and startmenu should keep custom functions
  * every program should run without magiczockerOS APIs for easier testing and optimization
* Add missing events
* Reimplement filesystem API
* Move settings to files/.settings.json to remove custom functions from settings.lua
* Remove _HOSTver
* Terminate startmenu and calendar to save memory if not visible
* Fix bugs

## How to use the server.lua (Currently CC-Compatible only)
1. Put the server.lua on the computer, which you want to use as a server.
2. Connect disk-drives to the computer.
3. Connect a modem to it. (Only wired-modem to wired-modem and wireless-modem to wireless-modem is possible in ComputerCraft)
4. Run it and create your first user account.

## The following included files are optional and can be removed, if you haven't enough space on your computer
* /magiczockerOS/programs/calendar.lua
* /magiczockerOS/programs/contextmenu.lua
* /magiczockerOS/programs/login.lua (If at least one local useraccount is existing)
* /magiczockerOS/programs/osk.lua
* /magiczockerOS/programs/search.lua
* /magiczockerOS/programs/settings.lua
