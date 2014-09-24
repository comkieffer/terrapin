
-- [TODO] - upgrade to lapp
local terrapin = require "terrapin"

function usage()
	print "replace width length [up|down]"
	print ""
	print "scans the floor or ceiling of the area defined by width and length replacing all blocks that do not match the block type given in the inventory"
end

function replace(direction)
	local digFn, placeFn, compareFn

	if direction == "down" then
		digFn, placeFn, compareFn = terrapin.digDown, terrapin.placeDown, terrapin.compareDown
	else
		digFn, placeFn, compareFn = terrapin.digUp, terrapin.placeUp, terrapin.compareUp
	end

	if not compareFn() then 
		digFn(0)
		local res, remaining, err = assert(placeFn())

		if remaining == 0 then
			table.remove(placeable_blocks, 1)

			if #placeable_blocks == 0 then
				error("no more blocks to place. ABORTING", 2)
			end

			terrapin.select(placeable_blocks[1])
		end
	end
end

local args = { ... }

-- has to be global
placeable_blocks = terrapin.getOccupiedSlots()
local x, y, direction, mode

-- configure turtle mode
if #args == 2 and args[1] == "smart" then
	direction = args[2]
	print("Starting in smart mode (" .. direction .. ")")
 	mode = 1
elseif #args == 2 then
	x, y, direction = tonumber(args[1]), tonumber(args[2]), "down"
	print("Starting in normal(2) mode (" .. direction .. ")")
	mode = 2
elseif #args == 3 then
	x, y, direction = tonumber(args[1]), tonumber(args[2]), args[3]
	print("Starting in normal mode (" .. direction .. ")")
	mode = 2
elseif #args ~= 3 or #placeable_blocks == 0 then 
	usage()
	return
end

if #placeable_blocks == 0 then 
	usage()
	return
end

terrapin.select(tonumber(placeable_blocks[1]))

if mode == 1 then
	local first_line = true
	repeat 
		if first_line then
			first_line = false
		else
			if terrapin.getFuelLevel() < 1 then
				io.write("Insuficient fuel to continue ... Aborting\n")
				return
			end

			terrapin.forward()
			terrapin.turnLeft()
		end

		local slice_length = 0

		while not terrapin.detect() do
			terrapin.forward()
			replace(direction)
			slice_length = slice_length + 1
		end

		terrapin.turn(2)
		terrapin.forward(slice_length)

		terrapin.turnLeft()
	until terrapin.detect()

elseif mode == 2 then
	local required_fuel = x * (y + 1)
	if terrapin.getFuelLevel() < required_fuel then
		io.write("insuficient fuel to continue ... Aborting\n")
		return
	end

	--preplace turtle 
	terrapin.forward()
	replace(direction)

	for i = 1, x, 2 do -- iterate slices 
		for j = 1, y - 1 do -- do first slice
			terrapin.forward()
			replace(direction)
		end

		if i + 1 <= x then 
			terrapin.turnRight()
			terrapin.forward()
			terrapin.turnRight()
			replace(direction)

			for j = 1, y - 1 do
				terrapin.forward()
				replace(direction)
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
			replace(direction)
		end 
	end
end

