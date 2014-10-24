
--[[--
File: digtunnel

Digs a tunnel of the specified proportions
Note: the tunnel starting surface must be flat.
      place the terrapin in the lower left corner
	  and run the program.

Warning : the terrapin will auto empty if it is full

@script digtunnel
]]--

local lapp = require "pl.lapp"

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin"
local libdig   = require 'libdig'

--[[
Dig a tunnel of the specified dimensions.

Tunnel is a misnomer. This can be used to dig out any area from the bottom up.
If you need to dig from the top down look at DigPit instead.

When the program is started the turtle will move to the top of the area to clear
and dig out layers up to 3 blocks high.

@script DigTunnel
]]

local args = { ... }
local usage = [[
	<width> (number)
	<height> (number)
	<length> (number)
	-e, --ender-chest dump inventory into ender chest.
]]

local cmdLine = lapp(usage, args)

assert(cmdLine.width > 0)
assert(cmdLine.height > 0)
assert(cmdLine.length > 0)

-- fix the types of the parameters
cmdLine.width = tonumber(cmdLine.width)
cmdLine.height = tonumber(cmdLine.height)
cmdLine.length = tonumber(cmdLine.length) + 1


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
	libdig.digLayer(layer_heights[i], cmdLine.width, cmdLine.length)
end

-- Now we can go back to our starting point
terrapin.goToStart()

checkin.endTask()
