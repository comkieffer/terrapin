
local terrapin = {}

--[[
		INTERNAL METHODS
]]

--- Try to move and graciously fail if the movement is impossible.
-- @param moveFn The movement function to try
-- @return The number of blocks that the turlte has effectively moved
local function _tryMove(moveFn)
	assert_function(1, moveFn, 4)

	-- Check that the fuel level is sufficient
	local attempts, has_moved = 0, false
	if turtle.getFuelLevel() == 0 then
		if terrapin["error_on_move_without_fuel"] then
			error("No more fuel. Aborting", 2)
		else
			return 0
		end
	end

	-- Try to move.
	repeat
		has_moved = moveFn()
		attempts = attempts + 1

		-- If we are unable to move retry at max n times
		if attempts > 1 then
			sleep(terrapin.wait_between_failed_moves)
		end
	until has_moved == true or attempts == terrapin.max_move_attempts

	if not has_moved and terrapin["error_on_failed_move"] then
		error('Move Failed Aborting')
	end

	if terrapin.inertial_nav.enabled and has_moved then
		terrapin._update_relative_pos(moveFn)
	end

	return has_moved
end

--- Move the turtle.
--  Internally this just calls _tryMove until the turtle has moved the specified
-- 	number of blocks.
-- @param moveFn The movement function to use
-- @param steps The number of steps to move
-- @return The number of steps the turtle actually moved
local function _move(moveFn, steps)
	if steps == 0 then return 0 end

	local moves = 0
	for i = 1, steps do
		if _tryMove(moveFn) then
			moves = moves + 1
		end
	end

	return moves
end

--- Turn the specified number of steps
-- @param steps The amount of times the turtle should turn. If steps is positive
--		then the turtle turns right, otherwise it turns left.
local function _turn(steps)
	local turnFn

	if steps > 0 then
		turnFn = turtle.turnRight
	else
		turnFn = turtle.turnLeft
	end

	if terrapin.inertial_nav.enabled then
		terrapin.inertial_nav.current_facing_direction =
			(terrapin.inertial_nav.current_facing_direction + steps) % 4
	end

	if steps < 0 then steps	= -steps end

 	for i = 1, steps do
		turnFn()
	end
end

--[[
		PUBLIC METHODS
]]

--- Movement functions
-- @section Movement

-- If a move action fails the turtle will try again a short time later. The timeout and maximum
-- number of tries is controllable in the configuration object.
-- @param steps the distance to move
-- @return the number of times the turtle was able to move
function terrapin.forward(steps)
	steps = steps or 1
	return _move(turtle.forward, steps)
end

--- Move the specified number of steps backward
-- If a move action fails the turtle will try again a short time later. The timeout and maximum
-- number of tries is controllable in the configuration object.
-- @param steps the distance to move
-- @return the number of times the turtle was able to move
function terrapin.back(steps)
	steps = steps or 1
	return _move(turtle.back, steps)
end

--- Move the specified number of steps up
-- If a move action fails the turtle will try again a short time later. The timeout and maximum
-- number of tries is controllable in the configuration object.
-- @param steps the distance to move
-- @return the number of times the turtle was able to move
function terrapin.up(steps)
	steps = steps or 1
	return _move(turtle.up, steps)
end

--- Move the specified number of steps down
-- If a move action fails the turtle will try again a short time later. The timeout and maximum
-- number of tries is controllable in the configuration object.
-- @param steps the distance to move
-- @return the number of times the turtle was able to move
function terrapin.down(steps)
	steps = steps or 1
	return _move(turtle.down, steps)
end

--- Turn the specified number of times towards the right. If steps is negative then turn towards
-- the left the specified number of times.
-- @param steps how many times to turn
function terrapin.turn(steps)
	steps = steps or 1
	_turn(steps)
end

--- TurnLeft
-- @param steps how many tiems to turn.
function terrapin.turnLeft(steps)
	steps = steps or 1
	_turn(-steps)
end

--- TurnLeft
-- @param steps how many tiems to turn.
function terrapin.turnRight(steps)
	steps = steps or 1
	_turn(steps)
end

--- Digging Function
-- @section digging functions

local function _dig(digFn, moveFn, detectFn, steps)
	assert_function(1, digFn, 4)
	assert_function(2, moveFn, 4)
	assert_function(3, detectFn, 4)
	assert_int(4, steps)

	local moved, dug = 0, 0

	if steps == 0 then
		while detectFn() do
			digFn()
			dug = dug + 1
			sleep(terrapin.wait_between_digs)
		end
	else
		for i = 1, steps do
			while detectFn() do
				digFn()
				dug = dug + 1
				sleep(terrapin.wait_between_digs)
			end

			_tryMove(moveFn)
			moved = moved + 1
		end  -- end for
	end -- end if steps == 0

	terrapin.state.blocks_dug = terrapin.state.blocks_dug + dug

	return dug, moved
end

--- Dig the specified number of steps
-- @param steps the distance to dig
-- @return how many blocks were dug, how many times did the turtle succsfully move forward.
--
-- the number of blokcs dugs and the number of moves will be different if the turtle has dug
-- through gravel or sand. To keep track of the turtles position using the inertial navigation
-- API is recommended
function terrapin.dig(steps)
	steps = steps or 1
	return _dig(turtle.dig, turtle.forward, turtle.detect, steps)
end

--- Dig the specified number of steps up
-- @param steps the distance to dig
-- @return how many blocks were dug, how many times did the turtle succsfully move forward.
-- (These should always be the same)
function terrapin.digUp(steps)
	steps = steps or 1
	return _dig(turtle.digUp, turtle.up, turtle.detectUp, steps)
end

--- Dig the specified number of steps
-- @param steps the distance to dig
-- @return how many blocks were dug, how many times did the turtle succsfully move forward.
-- (These should always be the same)
function terrapin.digDown(steps)
	steps = steps or 1
	return _dig(turtle.digDown, turtle.down, turtle.detectDown, steps)
end

--- Detection functions
-- @section detect

--- Detect whether there is a block to the left of the turtle.
-- @return true if a block was detected
function terrapin.detectLeft()
	terrapin.turnLeft()
	local detected = terrapin.detect()
	terrapin.turnRight()

	return detected
end

--- Detect whether there is a block to the right of the turtle.
-- @return true if a block was detected
function terrapin.detectRight()
	terrapin.turnRight()
	local detected = terrapin.detect()
	terrapin.turnLeft()

	return detected
end

return terrapin
