
--[[--
	TODO

	@script replacewall
]]
local lapp     = require "pl.lapp"
local ui       = require "ui"
local terrapin = require "terrapin"

local args, usage = {... }, [[
Replace the blocks that for a wall in a room. Only use indoors !
If you use this script outside you may lose your turtle
<direction> (left|right)
]]

local cmdLine = lapp(usage, args)

local turnFn
if cmdLine.direction = "left" then
	turnFn = terrapin.right()
else
	turnFn = terrapin.turnLeft()
end

--Find the slots where building materials are stored
local material_slots = terrapin.getOccupiedSlots()
if #material_slots == 0 then
	error("Please insert building materials into the turtle")
end

terrapin.select(material_slots[1])

-- start replacing

function doSlice()
	while not terrapin.detectUp() do
		terrapin.dig(0)
		terrapin.place()

		if terrapin.getItemCount() == 0 then
			material_slots:pop()

			-- If we have finished all the building materials go back to the bottom of the
			-- wall and exit.

			if #material_slots == 0 then
				error("Out of building materials")
			end

			-- else just slect the next slot with materials
			terrapin.select(material_slots[1])
		end
	end

	-- go back down to the bottom of the wall
	while not terrapin.detectDown() do terrapin.down() end
end

while true do
	doSlice()

	-- move to next line
	turnFn()
	if terrapin.detect() then
		-- we are facing a block. We interpret this as meaning that we have reached the end
		-- of the wall
		return
	end

	terrapin.forward()
	turnFn(-1)
end
