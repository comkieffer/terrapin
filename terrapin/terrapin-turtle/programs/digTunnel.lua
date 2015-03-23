
--[[--
Digs a tunnel of the specified proportions.


Place the turtle in the bottom left corner of the area you want to dig. The
turtle will start digging from the top down and left to right.

The turtle will try to dig as many 3 high chuks as possible but will dig
only 1 or 2 high if required to pravoid digging outside of the boundary.
This allows the turtle to use a lot less fuel than it would otherwise.

Like most programs in the terrapin API collection the turtle will estimate
the number of moves requried to finish the task and if the remaining fuel is
not enough to finish will ask you to confirm.

It will also use the checkin API to report it's progress. At this point in
time the turtle will not check to see if it still has room in it's inventory
whilst digging. This will be changed in a future release to make the turtle
empty its inventory into a chest when it overflows.

@script DigTunnel
]]--

local lapp    = require "sanelight.lapp"
local List    = require "sanelight.List"
local stringx = require 'sanelight.stringx'

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin.client"
local libdig   = require 'libdig'

local function onInventoryFull()
	dig_pos = terrapin.getPos()

	terrapin.goToStart()
	-- turn to face the place where the chest would be
	terrapin.turn(2)

	local success, block = terrapin.inspect()
	if success and stringx.endswith(block.name, 'chest') then
		terrapin.dropAll()
	else
		checkin.checkin(
			'Invetory Full. Returning to surface. Please come to empty me')
		print('Inventory Full. Empty me and press <ENTER>')
		read()
	end

	checkin.checkin('Inventory emptied. Returning to pit.')
	terrapin.goTo(dig_pos)
end

local args = { ... }

--- @usage
local usage = [[
	<width> (number)
	<height> (number)
	<length> (number)
]]

local cmdLine = lapp(usage, args)

assert(cmdLine.width > 0)
assert(cmdLine.height > 0)
assert(cmdLine.length > 0)

-- This is a quick hack to get the terrapin.visit base to wrok well.
cmdLine.length = cmdLine.length + 1


-- check fuel level
-- FIXME : Is this still true ?
local required_moves = cmdLine.length * cmdLine.height * cmdLine.width  -- digging moves
                     + 2 * (cmdLine.height - 1) * cmdLine.width -- repositioning after each slice

if not ui.confirmFuel(required_moves) then
	return
end

-- we use inertial nav to track the height of the turtle.
terrapin.enableInertialNav()
checkin.startTask('DigTunnel', cmdLine)

-- First we generate a list containing the height of all the layers we will dig.
local layer_heights = List()
local current_height = cmdLine.height

for i = 0, cmdLine.height - 1, 3 do
	local layer_height = math.min(cmdLine.height - i, 3)
	current_height = current_height - layer_height
	layer_heights:append(layer_height)
end

-- print('Layer chunks generated :')
-- print(textutils.serialize(layer_heights))

-- We use this list to calculate the starting height for each layer
local layer_start_heights = List()
local start_height = -1

local previous_start_height = cmdLine.height

for _,v in ipairs(layer_heights) do
	if previous_start_height == cmdLine.height then
		start_height = math.max(previous_start_height - 1, 1)
	else
		start_height = math.max(previous_start_height - 3, 1)
	end

	layer_start_heights:append(start_height)
	previous_start_height = start_height
end

-- So far we have considered heights. We need to convert all our distances into
-- the coordinate system for the inertial_nav system that starts from 0. T
--
-- For example the block above the turtle is blocks 2 for us but for the
-- inertial module the height of the block is y = 1
for i = 1, #layer_start_heights do
	layer_start_heights[i] = layer_start_heights[i] -1
end

-- print('Layer starts generated:')
-- print(textutils.serialize(layer_start_heights))

-- now we can dig each layer
for i = 1, #layer_start_heights do
	-- print('Digging new layer. y = ', layer_start_heights[i], ', h = ', layer_heights[i])
	terrapin.goTo {
		["x"] = 0,
		["y"] = layer_start_heights[i],
		["z"] = 0,
		["turn"] = 0
	}
	libdig.digLayer(layer_heights[i], cmdLine.width, cmdLine.length, onInventoryFull)
end

-- Now we can go back to our starting point
terrapin.goToStart()

checkin.endTask()
