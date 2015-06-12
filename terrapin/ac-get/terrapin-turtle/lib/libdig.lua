
--[[--
A set of digging primitives.

LibDig provides a set of higher level primitives for efficient digging. Combined
with terrapin.visit() it makes creating complex and efficient digging programs a
breeze.

The assumption behind libdig is that you will be digging rectangular slices. If
you need more complex shapes it should be simple enough to make this library
support it.

For some examples of how libdig can be used check out @see
terrapi.programs.turtle.digmine and @see terrapin.turtle.digpit

@module libdig
]]

local terrapin = require 'terrapin'

local libdig = {
}

-- Dig out a layer 3 blocks high.
local function diglayer3(width, length, afterMove)
	local function onMove()
		terrapin.digUp(0)
		terrapin.digDown(0)
		afterMove()
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer2(width, length, afterMove)
	local function onMove()
		terrapin.digUp(0)
		afterMove()
	end

	terrapin.visit(width, length, true, onMove)
end

local function diglayer1(width, length, afterMove)
	-- Since we are only digging a 1 high layer the movement of the turtle will
	-- clear out all the blocks

	terrapin.visit(width, length, true, afterMove)
end

function libdig.digLayer(height, width, length, afterMove)
	if height == 1 then
		return diglayer1(width, length, afterMove)
	elseif height == 2 then
		return diglayer2(width, length, afterMove)
	elseif height == 3 then
		return diglayer3(width, length, afterMove)
	else
		error('"height" parameter must be an integer between 1 and 3. Was: ' .. height)
	end
end

return libdig
