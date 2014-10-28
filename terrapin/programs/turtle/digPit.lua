
--[[--
Dig a pit of the specified width, length and depth

The pit will start on the square in front of the turtle and extend to the
right of the turtle.

@script DigPit
]]

-- TODO : automatically empty inventory
local lapp    = require "pl.lapp"
local stringx = require 'pl.stringx'

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin"
local libdig   = require 'libdig'

local function onInventoryFull()
	dig_pos = terrapin.getPos()

	terrapin.goToStart()
	-- turn to face the place where the chest would be
	terrapin.turn(2)
	terrapin.forward()

	local success, block = terrapin.inspect()
	if success and stringx.endswith(block.name, 'chest') then
		terrapin.dropAll()
	else
		checkin.checkin(
			'Inventory Full. Returning to surface. Please come to empty me')
		print('Inventory Full. Empty me and press <ENTER>')
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


-- before we do anything we postion the turtle above the pit
terrapin.dig()

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

print('Layer chunks generated :')
print(textutils.serialize(layer_depths))

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

print('Layer starts generated:')
print(textutils.serialize(layer_start_depths))


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
terrapin.goToStart()

terrapin.turn(2)
terrapin.forward()
