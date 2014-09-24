
--[[
	Dig a pit of the specified width, length and depth

	The pit will start on the square in front of the turtle and extend to the
	right of the turtle.
]]

-- TODO : automatically empty inventory
local lapp = require "pl.lapp"
local ui = require "ui"
local terrapin = require "terrapin"

local function inventoryFull()
	dig_pos = terrapin.getPos()

	terrapin.goToStart()
	terrapin.dropAll()

	terrapin.goTo(dig_pos)
end

local args = { ... }
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

terrapin.dig()

-- Save this as the start position. We should be just over the edge of the
-- quarry facing the chest.
terrapin.turn(2)
terrapin.enableInertialNav()

for i = 1, cmdLine.width do
	for j = 1, cmdLine.length do
		for k = 1, cmdLine.depth
			terrapin.digDown()

			if #terrapin.getFreeSlots() == 0 then
				inventoryFull()
			end
		end

		-- climb back to the top. We shouldn't mine anything on the way up
		terrapin.digUp(cmdLine.depth)

		if j ~= cmdLine.length then
			terrapin.dig()
			if #terrapin.getFreeSlots() == 0 then
				inventoryFull()
			end
		else
			-- We have reached the end of our line. Time to move to the next one
			terrapin.turn(2)
			terrapin.forward(cmdLine.length - 1)
			terrapin.turnLeft()
			terrapin.forward()
			terrapin.turnLeft()
		end
	end
end

terrapin.goToStart()
terrapin.dropAll()
