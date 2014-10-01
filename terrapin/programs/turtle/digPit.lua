
--[[
	Dig a pit of the specified width, length and depth

	The pit will start on the square in front of the turtle and extend to the
	right of the turtle.
]]

-- TODO : automatically empty inventory
local lapp = require "pl.lapp"
local ui = require "ui"
local terrapin = require "terrapin"
local checkin = require "checkin"

local function inventoryFull()
	checkin.checkin('Invetory Full. Returning to surface.')
	dig_pos = terrapin.getPos()

	terrapin.goToStart()
	terrapin.dropAll()

	checkin.checkin('Invetory emptied. Returning to pit.')
	terrapin.goTo(dig_pos)
end

local args = { ... }
local usage = [[
	<width>  (number)
	<length> (number)
	<depth>  (number)
]]

local cmdLine = lapp(usage, args)
checkin.startTask('DigPit', cmdLine)

local required_moves = cmdLine.width * cmdLine.length * (cmdLine.depth + 1)
if not ui.confirmFuel(required_moves) then
	return
end

terrapin.dig()

-- Save this as the start position. We should be just over the edge of the
-- quarry facing the chest.
terrapin.turn(2)
terrapin.enableInertialNav()

-- turn back to face the right direction again.
terrapin.turn(2)

for i = 1, cmdLine.width do
	for j = 1, cmdLine.length / 2 do
		checkin.checkin('Digging pit ' .. j .. ' of ' .. cmdLine.length / 2 ..
			' in slice ' .. i .. ' of ' .. cmdLine.width .. '.')

		-- Dig Down
		for k = 1, cmdLine.depth do
			-- dig ahead and down to cut down on resource usage
			-- TODO : Make this work for odd lengths.

			terrapin.dig(0)
			terrapin.digDown()

			if #terrapin.getFreeSlots() == 0 then
				inventoryFull()
			end
		end

		-- climb back to the top. We shouldn't mine anything on the way up
		terrapin.dig()
		terrapin.digUp(cmdLine.depth)

		-- Move forward to dig the next hole if we're not at the end
		if j < cmdLine.length / 2 then
			terrapin.dig(1)
			if #terrapin.getFreeSlots() == 0 then
				inventoryFull()
			end
		else
			-- When we reach the end of the current line we should move to dig
			-- the next one.
			if i < cmdLine.width then
				terrapin.turn(2)
				terrapin.forward(cmdLine.length - 1)
				terrapin.turnLeft()
				terrapin.forward()
				terrapin.turnLeft()
			end
		end

	end
end

checkin.checkin('Finished digging. Returning to starting point.')
terrapin.goToStart()
terrapin.dropAll()
