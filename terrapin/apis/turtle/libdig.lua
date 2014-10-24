
--[[--
TODO

@module libdig
]]

local terrapin = require 'terrapin'

local libdig = {
}


-- Dig out a layer 3 blocks high.
local function diglayer3(width, length)
	local function onMove()
		terrapin.digUp(0)
		terrapin.digDown(0)
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer2(width, length)
	local function onMove()
		terrapin.digUp(0)
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer1(width, length)
	-- Since we are only digging a 1 high layer the movement of the turtle will
	-- clear out all the blocks
	local function onMove()
	end

	terrapin.visit(width, length, true, onMove)
end

function libdig.digLayer(height, width, length)
	if height == 1 then
		return diglayer1(width, length)
	elseif height == 2 then
		return diglayer2(width, length)
	elseif height == 3 then
		return diglayer3(width, length)
	else
		error('"height" parameter must be an integer between 1 and 3. Was: ' .. height)
	end
end

return libdig
