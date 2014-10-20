
--[[--
	Replace the blocks in the floor or a ceiling.

	The turtle inventory should be filled with one block type. The type of block
	that will make up the final floor/ceiling. Any block that does not match this
	block will be replaced.

	if the -u or --up option is used instead of looking down the turtle will look
	up and replace blocks in the ceiling.

	@script replace
]]

local lapp      = require 'pl.lapp'
local ui        = require "ui"
local terrapin  = require "terrapin"
local checkin   = require "checkin"
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
		local res, remaining, err = assert(placeFn())
		if not res then error(err) end

		if smartslot.update() == 0 then
			error("no more blocks to place. ABORTING", 2)
		end
	end
end


local args = { ... }
local usage = [[
	Scans the floor or ceiling of the defined area and replaces all the blocks
	that do not match the specified block type.
	The turtle inventory should only contain one type of block.

	<width>
	<length>
	-u, --up  Look up instead of down
]]

local cmdLine = lapp(usage, args)

slots = terrapin.getOccupiedSlots()
smartslot = SmartSlot(slots)

if smartslot.update() == 0 then
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

local required_fuel = x * (y + 1)
if not ui.confirmFuel(required_moves) then
	return
end

--preplace turtle
terrapin.forward()
replace(cmdLine)

for i = 1, x, 2 do -- iterate slices
	for j = 1, y - 1 do -- do first slice
		terrapin.forward()
		replace(cmdLine, smartslot)
	end

	if i + 1 <= x then
		terrapin.turnRight()
		terrapin.forward()
		terrapin.turnRight()
		replace(cmdLine, smartslot)

		for j = 1, y - 1 do
			terrapin.forward()
			replace(cmdLine, smartslot)
		end
	else
		terrapin.turn(2)
		terrapin.forward(y - 1)
	end

	-- if necessary align for next line
	-- print (i, ", ", x)
	if i < x - 1 then
		-- print "realign"
		terrapin.turnLeft()
		terrapin.forward()
		terrapin.turnLeft()
		replace(cmdLine, smartslot)
	end
end
