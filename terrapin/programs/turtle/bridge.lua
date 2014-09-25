
local lapp = require 'pl.lapp'
local terrapin = require 'terrapin'

local args = { ... }
local usage = [[
	<length> (number)
]]

local cmdLine = lapp(usage, args)

local placeable_blocks = terrapin.getOccupiedSlots()
if #placeable_blocks == 0 then
	error('No blocks to place')
end

for i = 1, cmdLine.length do
	terrapin.dig()

	local status, remaining, err = terrapin.placeDown(
		placeable_blocks[1]
	)

	if not status then
		error(err)
	end

	if remaining == 0 then
		placeable_blocks:pop(1)
	end

	if #placeable_blocks == 0 then
		error('No more Blocks')
	end
end

terrapin.turn(2)
terrapin.dig(cmdLine.length)
