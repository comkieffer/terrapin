
local terrapin = {}

--
-- Smart mining Stuff - template functions
--

-- Internal method.
-- Read data using the inspectFn function from a block and pass the data to the
-- callback to determine if the block is "valuable" or not.
--
-- @param inspectFn The function to use to inspect the block
-- @param callback  The function to use to determine if the block is valuable
--
-- @eturn False if the inspected block is empty or not valuable. True otherwise.
local function _isValuable(inspectFn, callback)
	local success, block = inspectFn()

	if success then
		return callback(block)
	else
		return false
	end
end

--
-- Smart mining Stuff Implementation
--

function terrapin.isValuable(callback)
	return _isValuable(turtle.inspect, callback)
end

function terrapin.isValuableUp(callback)
	return _isValuable(turtle.inspectUp, callback)
end

function terrapin.isValuableDown(callback)
	return _isValuable(turtle.inspectDown, callback)
end

terrapin.explore = nil -- forward declaration

--- Inspect all blocks around the turtle and detect if any are interesting.
--
-- The interestingness of a block is determined by the callback provided to the
-- function. It will receive as its first and only parameter the block data
-- returned by the inspect method
--
-- @param callback The callback function used to determine if a block is
--  valuable or not.
function terrapin.explore(callback)
	-- local sides = sides or List("front", "back", "up", "down", "left", "right")

	if terrapin.isValuable(callback) then
		terrapin.dig()
		terrapin.explore(callback)
		terrapin.back()
	end

	if terrapin.isValuableUp(callback) then
		terrapin.digUp()
		terrapin.explore(callback)
		terrapin.digDown()
	end

	if terrapin.isValuableDown(callback) then
		terrapin.digDown()
		terrapin.explore(callback)
		terrapin.digUp()
	end

	for i = 1, 3 do
		-- Check the left side of the turtle, then the back then the right side
		terrapin.turnLeft()
		if terrapin.isValuable(callback) then
			terrapin.dig()
			terrapin.explore(callback)
			terrapin.back()
		end
	end

	-- realign the turtle
	terrapin.turnLeft()
end

-- This is the entry point to the explore subsystem.
--
-- It will provide some metrics about the explore session. At the moment it only
-- provies de number of blocks dug. In the future it might return a detailed
-- analysis of the types of block dug, how many blocks were checked total, ...
--
-- @param onBlock The callback function to call with the block data to decide
-- 	whether or not to dig it out.
-- @return The number of blocks dug
function terrapin.startExplore(onBlock)
	local blocks_dug_so_far = terrapin.state.blocks_dug

	terrapin.explore(onBlock)

	local total_blocks_dug = 0
	if terrapin.state.blocks_dug ~= blocks_dug_so_far then
		local blocks_dug = terrapin.state.blocks_dug - blocks_dug_so_far
		total_blocks_dug = total_blocks_dug + blocks_dug
	end

	return total_blocks_dug
end

--- Move the turtle so that it passes above every block in the specfied area.
--
-- After moving the onMoveFinished callback will be called.
-- You can chose whether to use a forward() or dig() as the movement function.
-- It is recommended to use the forward by setting 'dig = false' so that your
-- turtle will not destroy the area if you make a mmistake with the parameters.
--
-- The area that the turtle will visit starts immediately starts at the turtle
-- position and extends forwards and to the right.
--
-- @param width  The width of the area
-- @param length The length of the area
-- @param dig    What movement function to use. if dig == false then
--  terrapin.forward() is called. If dig is true then terrapin.dig() will be
--  called instead.
-- @param onMoveFinished The callback function to call after every move has finished

function terrapin.visit(width, length, dig, onMoveFinished, ...)
	dig = dig or false
	local extra = { ... }

	local moveFn = terrapin.forward
	if dig then
		moveFn = terrapin.dig
	end

	for i = 1, width, 2 do -- iterate slices
		for j = 1, length - 1 do -- do first slice
			terrapin.dig()
			onMoveFinished(unpack(extra))
		end

		if i + 1 <= width then
			terrapin.turnRight()
			moveFn()
			terrapin.turnRight()
			onMoveFinished(unpack(extra))

			for j = 1, length - 1 do
				moveFn()
				onMoveFinished(unpack(extra))
			end
		else
			terrapin.turn(2)
			terrapin.dig(length - 1)
		end

		-- if necessary align for next line
		-- print (i, ", ", x)
		if i < width - 1 then
			-- print "realign"
			terrapin.turnLeft()
			moveFn()
			terrapin.turnLeft()

			onMoveFinished(unpack(extra))
		end
	end
end

return terrapin
