
--[[--
Replace the blocks in the floor or a ceiling.

The turtle inventory should be filled with one block type. The type of block
that will make up the final floor/ceiling. Any block that does not match this
block will be replaced.

if the -u or --up option is used instead of looking down the turtle will look
up and replace blocks in the ceiling.

@script Replace
]]

local lapp      = require 'sanelight.lapp'
local ui        = require "ui"
local terrapin  = require "terrapin"
local checkin   = require "checkin.client"
local SmartSlot = require "smartslot"

function replace(cmdLine, smartslot)
	local digFn, placeFn, compareFn

	if cmdLine.direction == "down" then
		digFn, placeFn, compareFn = terrapin.digDown, terrapin.placeDown, terrapin.compareDown
	else
		digFn, placeFn, compareFn = terrapin.digUp, terrapin.placeUp, terrapin.compareUp
	end

	if not compareFn() then
		digFn(0)
		local res, remaining, err = assert(placeFn(smartslot()))
		if not res then error(err) end

		if smartslot:update() == 0 then
			error("no more blocks to place. ABORTING", 2)
		end
	end
end


local args = { ... }
local usage = [[
	Scans the floor or ceiling of the defined area and replaces all the blocks
	that do not match the specified block type.
	The turtle inventory should only contain one type of block.

	<width>  (number) Width of Area
	<length> (number) Length of Area
	-u, --up  Look up instead of down
]]

local cmdLine = lapp(usage, args)

local block_slots = terrapin.getOccupiedSlots()
smartslot = SmartSlot(block_slots)


if smartslot:update() == 0 then
	error("Cannot start without any blocks to place.")
end

if cmdLine.up then
	cmdLine.direction = "up"
else
	cmdLine.direction = "down"
end

terrapin.enableInertialNav()
checkin.startTask('Replace', cmdLine)

terrapin.select(smartslot())

local required_moves = cmdLine.width * (cmdLine.length + 1)
if not ui.confirmFuel(required_moves) then
	return
end

--preplace turtle
terrapin.forward()
replace(cmdLine, smartslot)

terrapin.visit(cmdLine.width, cmdLine.length, replace, cmdLine, smartslot)

checkin.endTask()
