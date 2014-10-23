
--[[--
A simple tree farmer.

The tree farm shoulod be com posed of a line of trees. There can be holes
between saplings.

The turtle should be placed one block above the ground a couple of blocks away
from the first sapling. When the  program is started the turtle will fell trees
harvesting all their wood until it arrives at an 'oak_stairs' block and turn
back. In future the actual limit block used will eb configurable.

The turtle will not cut trees on the return trip.

@script treefarm
]]

lapp     = require "pl.lapp"
stringx  = require 'pl.stringx'
terrapin = require "terrapin"
checkin  = require "checkin"

local end_block = 'oak_stairs'
local total_blocks_dug = 0

local function is_wood(block)
	return stringx.endswith(block.name, 'log')
end

local args = { ... }
local usage = [[
	See terrapin documentation at www.comkieffer.com/terrapin for usage
]]

terrapin.enableInertialNav()
checkin.startTask('TreeFarm', {})

terrapin.dig()

-- run the farm bot
while true do
	-- check to see if have reached our limit block :
	success, block = terrapin.inspect()
	if success and stringx.endswith(block.name, end_block) then
		break
	end

	local blocks_dug_so_far = terrapin.state.blocks_dug
	terrapin.explore(is_wood)

	if terrapin.state.blocks_dug ~= blocks_dug_so_far then
		local blocks_dug = terrapin.state.blocks_dug - blocks_dug_so_far
		total_blocks_dug = total_blocks_dug + blocks_dug

		checkin.checkin("Found Tree. Cut " .. blocks_dug .. "blocks.")
	end

	terrapin.dig()
end

-- go home :
checkin.checkin(
	'Digging run complete. Returning home. Got ' .. total_blocks_dug ..
	'Wood blocks this run.'
)
terrapin.goToStart()


