
--[[--
Dig a pit of the specified width, length and depth

The pit will start on the square in front of the turtle and extend to the
right of the turtle.

When the turtle detects that it has no free slots in its inventory it will
return to its starting point and look for a chest in which to empty itself.
If it can't find a chest it will wait for you to empty it.

The proper configuration if you want to find the chest is :

	+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	|                             |
	|^        Area to clear       |
	+-+                           |
	|T| >                         |
	+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
	|C|
	+-+

The turtle is placed on the inner edge of the bottom left corner of the area to
be cleared and the chest is placed just behind it.

Unlike in other scripts the turtle is placed just outside the work area. This
makes it easier to retrieve once it has finished its job since it is not hanging
above a deep pit.

@script DigPit
]]

-- TODO : automatically empty inventory
local lapp    = require "sanelight.lapp"
local stringx = require 'sanelight.stringx'

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin.client"
local libdig   = require 'libdig'

local function onInventoryFull()
	-- Try to comact the inventory to avoid a trip to the starting point
	io.write("Inventory full. Compacting ... ")
	terrapin.compactInventory()

	if #terrapin.getFreeSlots() > 0 then
		io.write("Done.\n Resuming Dig.\n")
		return
	end

	-- can't compact it any more ... Return to start
	io.write("Inventory already compact. Returning to starting point ...\n")

	dig_pos = terrapin.getPos()

	terrapin.goToStart()
	-- turn to face the place where the chest would be
	terrapin.turn(2)

	local success, block = terrapin.inspect()

	if success and stringx.endswith(block.name, 'chest') then
		terrapin.dropAll()
	else
		checkin.checkin(
			'Inventory Full. Returning to surface. Please come to empty me')
		print('\nInventory Full. Empty me and press <ENTER>')
		read()
	end

	checkin.checkin('Invetory emptied. Returning to pit.')
	terrapin.goTo(dig_pos)
end

local args = { ... }

--- @usage
local usage = [[
	<width>  (number)
	<length> (number)
	<depth>  (number)
]]

local cmdLine = lapp(usage, args)

local required_moves = cmdLine.width * cmdLine.length * (cmdLine.depth + 1)
if not ui.confirmFuel(required_moves) then
	return
end


terrapin.enableInertialNav()
checkin.startTask('DigPit', cmdLine)

-- First we need to generate a list containing the depth of each layer we will
-- have to excavate.
local layer_depths = List()
local current_depth = cmdLine.depth

for i = 0, cmdLine.depth - 1, 3 do
	local layer_depth = math.min(cmdLine.depth - i, 3)
	current_depth = current_depth - layer_depth
	layer_depths:append(layer_depth)
end


-- Now we can generate a list containing the starting depth for each layer
-- respective to the current turtle position.
local layer_start_depths = List()
local start_depth = 0

local previous_start_depth = 0

for _,v in ipairs(layer_depths) do
	if previous_start_depth == 0 then
		start_depth = math.max(previous_start_depth - 2, -cmdLine.depth)
	else
		start_depth = math.max(previous_start_depth - 3, -cmdLine.depth)
	end

	layer_start_depths:append(start_depth)
	previous_start_depth = start_depth
end


-- now we can dig each layer
for i = 1, #layer_start_depths do
	-- print('Digging new layer. y = ', layer_start_depths[i], ', h = ', layer_depths[i])
	terrapin.goTo {
		["x"] = 0,
		["y"] = layer_start_depths[i],
		["z"] = 0,
		["turn"] = 0
	}

	-- Trust me.You need this !
	if layer_depths[i] == 3 then
		terrapin.digDown(0)
	end

	libdig.digLayer(layer_depths[i], cmdLine.width, cmdLine.length, onInventoryFull)
end


checkin.checkin('Finished digging. Returning to starting point.')
print('Finished Digging.')

terrapin.goToStart()
terrapin.turn(2)

checkin.endTask()
