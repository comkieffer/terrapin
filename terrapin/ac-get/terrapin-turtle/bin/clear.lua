
--[[--
Level the specified area. Eveything above the layer the turtle is currently on
will be cut down. It will not fill up holes.

When the turtle detects that it has no free slots in its inventory it will
return to its starting point and look for a chest in which to empty itself.
If it can't find a chest it will wait for you to empty it.

The proper configuration if you want to find the chest is :

	+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	|                             |
	+-+      Area to clear        |
	|T|                           |
	+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	|C|
	+-+

The turtle is placed on the inner part of the bottom left corner of the area to
be cleared and the chest is placed just behind it.

TODO : Test Me
	- Make sure that ths works
	- Make sure that the inv dumping works well enough

@script Clear
]]

local lapp     = require "sanelight.lapp"

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin.client"

local function clear()
	local col_start_pos = terrapin.getPos()

	while terrapin.detectUp() do
		terrapin.digUp()
	end

	terrapin.goTo(col_start_pos)


	-- Handle inventory full condition by returning to the start point and
	-- looking for a chest.
	if #terrapin.getFreeSlots() == 0 then
		onInventoryFull()
	end
end

local function onInventoryFull()
	local current_pos = terrapin.getPos()
	terrapin.goToStart()
	terrapin.turn(2)  -- face the block where a chest might be

	local success, block = terrapin.inspect()
	if success and stringx.endswith(block.name, 'chest') then
		terrapin.dropAll()
	else
		checkin.warning(
			'Invetory Full. Returning to surface. Please come to empty me')
		print('Inventory Full. Empty me and press <ENTER>')
		read()
	end

	checkin.checkin('Inventory emptied. Returning to work.')
	terrapin.goTo(current_pos)
end


local args = { ... }

--- @usage
local usage = [[
<width>  (number)
<length> (number)
]]

local cmdLine = lapp(usage, args)

-- estimate fuel consumption.
-- we suppose that a "mountain" is on averag 3 blocks high
local required_moves = (cmdLine.length * 5) * cmdLine.width
if not ui.confirmFuel(required_moves) then
	return
end

terrapin.enableInertialNav()
checkin.startTask('Clear', cmdLine)

terrapin.visit(cmdLine.width, cmdLine.length, true, clear)

checkin.endTask()
