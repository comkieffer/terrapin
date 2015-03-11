
--[[--
A simple tree farmer.

The tree farm shoulod be com posed of a line of trees. There can be holes
between saplings.

The turtle should be placed one block above the ground a couple of blocks away
from the first sapling. When the  program is started the turtle will fell trees
harvesting all their wood until it arrives at an 'oak_stairs' block and turn
back. In future the actual limit block used will eb configurable.

If the program is run in --leaves mode then the turtle will also collect leaves.
The leaves will be broken but the turtle will collect saplings and apples that
might fall.

Running the turtle in leaves mode will make the individual runs VERY slow. For
larger tree farms it will also cause the program to bust the stack because of
the recursive calls to explore.

The turtle will not cut trees on the return trip.

@script TreeFarm
]]

lapp     = require "sanelight.lapp"
stringx  = require 'sanelight.stringx'
terrapin = require "terrapin"
checkin  = require "checkin.client"

local end_block = 'oak_stairs'
local total_blocks_dug = 0

local function is_wood(block)
	return stringx.endswith(block.name, 'log')
end

local function is_wood_or_leaves(block)
	return stringx.endswith(block.name, 'log') or stringx.endswith(block.name, 'leaves')
end

local args = { ... }
local usage = [[
	See terrapin documentation at www.comkieffer.com/terrapin for usage

	-l, --leaves Gut leaves as well
]]

local cmdLine = lapp(usage, args)

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
	if cmdLine.leaves then
		terrapin.explore(is_wood_or_leaves)
	else
		terrapin.explore(is_wood)
	end

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
