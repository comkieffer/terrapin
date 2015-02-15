
--[[--
Fill all the holes in the specfied area so that the ground is flat.

@script Fill
]]

local lapp      = require 'sanelight.lapp'
local ui        = require "ui"
local terrapin  = require "terrapin"
local checkin   = require "checkin.client"
local SmartSlot = require "smartslot"

function fill(smartslot)
	local depth = 1

	-- detect the depth we need to fill
	while not terrapin.detectDown() do
		terrapin.down()
		depth = depth + 1
	end

	-- do the filling
	for k = 1, depth - 1 do
		terrapin.up()
		terrapin.placeDown(smartslot())

		if smartslot:update() == 0 then
			error("no more blocks to place. ABORTING", 2)
		end
	end
end

local args = { ... }

--- @usage
local usage = [[
	<width> (number)
	<length> (number)
]]

local cmdLine = lapp(usage, args)

local block_slots = terrapin.getOccupiedSlots()
smartslot = SmartSlot(block_slots)

if smartslot:update() == 0 then
	error("Cannot start without any blocks to place.")
end

-- we suppose that the fill will be 3 deep, this is only a guideline.
local required_moves = 3 * cmdLine.length * cmdLine.width
if not ui.confirmFuel(required_moves) then
	return
end

checkin.startTask('Fill', cmdLine)

terrapin.forward()
fill(smartslot)

terrapin.visit(cmdLine.width, cmdLine.length, true, fill, smartslot)

checkin.endTask()
