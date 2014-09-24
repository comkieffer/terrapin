
local lapp     = require "pl.lapp"
local ui       = require "ui"
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
]]

local cmdLine = lapp(usage, args)

-- estimate fuel consumption.
-- we suppose that a "mountain" is on averag 3 blocks high
local required_moves = (cmdLine.length * 5) * cmdLine.width
if not ui.confirmFuel(required_moves) then
	return
end

terrapin.enableInertialNav()

for i = 1, cmdLine.width do
	for j = 1, cmdLine.length do
		terrapin.dig()

		-- dig all blocks above us
		local steps = 0
		while terrapin.detectUp() do
			terrapin.digUp()
			steps = steps + 1
		end

		terrapin.down(steps)

		if #terrapin.getFreeSlots() == 0 then
			inventoryFull()
		end

	end
	print(width, cmdLine.length)
	terrapin.turn(2)
	terrapin.dig(cmdLine.length)

	-- position for next mine
	if i ~= cmdLine.width then
		terrapin.turnLeft()
		terrapin.dig()
		terrapin.turnLeft()
	end
end
