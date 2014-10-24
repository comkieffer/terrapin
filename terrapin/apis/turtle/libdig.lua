
--[[--
TODO

@module libdig
]]

local terrapin = require 'terrapin'

local libdig = {
}

-- A simple placeholder function
local function _dummy()
end

-- Dig out a layer 3 blocks high.
local function diglayer3(width, length, onInventoryFull)
	local function onMove()
		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end

		terrapin.digUp(0)
		terrapin.digDown(0)
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer2(width, length, onInventoryFull)
	local function onMove()
		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end

		terrapin.digUp(0)
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer1(width, length, onInventoryFull)
	-- Since we are only digging a 1 high layer the movement of the turtle will
	-- clear out all the blocks
	local function onMove()
		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end
	end

	terrapin.visit(width, length, true, onMove)
end

function libdig.digLayer(height, width, length, onInventoryFull)
	if height == 1 then
		return diglayer1(width, length, onInventoryFull)
	elseif height == 2 then
		return diglayer2(width, length, onInventoryFull)
	elseif height == 3 then
		return diglayer3(width, length, onInventoryFull)
	else
		error('"height" parameter must be an integer between 1 and 3. Was: ' .. height)
	end
end

return libdig
