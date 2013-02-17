
terrapin = {
	-- Configuration options
	["max_move_attempts"] = 10,
	["wait_between_digs"] = 0.5,
	["wait_between_failed_moves"] = 0.5, 

	-- State variables
	["current_slot"] = 1,

	-- inertial nav API
	["inertial_nav_enabled"] = false,
	["directions"] = {
		-- when turning left +1
		-- when turning right -1
		["+x"] = 0, ["-z"] = 1, ["-x"] = 2, ["+z"] = 3
	},
 	["current_facing_direction"] = 0,
	["relative_pos"] = {
		--  +x is the direction the turtle is facing when inertial nav is enabled
		--  +y is up 
		["x"] = 0, ["y"] = 0, ["z"] = 0
	},

	-- turtle vars
	["last_slot"] = 16,
	["error_on_move_without_fuel"] = true,

	-- turtle functions that simply get passed through
	["detect"]       = turtle.detect,
	["detectUp"]     = turtle.detectUp,
	["detectDown"]   = turtle.detectDown,
	["drop"]         = turtle.drop,
	["dropUp"]       = turtle.dropUp,
	["dropDown"]     = turtle.dropDown,
	["suck"]         = turtle.suck,
	["suckUp"]       = turtle.suckUp,
	["suckDown"]     = turtle.suckDown
	["getItemCount"] = turtle.getItemCount,
	["compare"]      = turtle.compare,
	["compareUp"]    = turtle.compareUp,
	["compareDown"]  = turtle.compareDown,
	["getFuelLevel"] = turtle.getFuelLevel,
	["refuel"]       = turtle.refuel,
} 

-- 
-- Internal "template" functions.
-- assert level is set to 4 so that the error will occur on the caller 
-- of the function, no the function itself.
--
local function _update_relative_pos(moveFn)
	local pos, dirs, dir = terrapin.relative_pos, terrapin.directions, terrapin.current_facing_direction

	if moveFn == turtle.up then
		pos.y = pos.y + 1
	elseif moveFn == turtle.down then
		pos.y = pos.y - 11
	else
		if moveFn == turtle.forward then 
			if dir == dirs["+x"] then
				pos.x = pos.x + 1
			elseif dir == dirs["-x"] then
				pos.x = pos.x - 1
			elseif dir == dirs["+z"] then
				pos.z = pos.z + 1
			elseif dir == dirs["-z"] then
				pos.z = pos.z - 1
			else
				error ("Unknown direction : " .. dir)
			end
		elseif moveFn == turtle.back then
			if dir == dirs["+x"] then
				pos.x = pos.x - 1
			elseif dir == dirs["-x"] then
				pos.x = pos.x + 1
			elseif dir == dirs["+z"] then
				pos.z = pos.z - 1
			elseif dir == dirs["-z"] then
				pos.z = pos.z + 1
			else
				error ("Unknown direction : " .. dir)
			end
		end
	end
end

local function _tryMove(moveFn)
	assert_function(1, moveFn, 4)

	local attempts, has_moved = 0, false
	if turtle.getFuelLevel() == 0 then
		if terrapin["error_on_move_without_fuel"] then
			error("No more fuel. Aborting", 2)
		else
			return false
		end
	end
	
	repeat
		has_moved = moveFn()
		attempts = attempts + 1
		-- print("move stats : hm = ", has_moved, ", att = ", attempts) 

		-- If we are unable to move retry at max n times
		if attempts > 1 then 
			sleep(terrapin.wait_between_failed_moves) 
		end
	until has_moved == true or attempts == terrapin.max_move_attempts

	if terrapin.inertial_nav_enabled and has_moved then
		_update_relative_pos(moveFn)
	end

	return has_moved
end

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

	return dug, moved
end

local function _move(moveFn, steps)
	assert_function(1, moveFn, 4)
	assert_int(2, steps, 4)

	if steps == 0 then return 0 end

	local moves = 0
	for i = 1, steps do
		if _tryMove(moveFn) then
			moves = moves + 1
		end
	end

	return moves
end

local function _turn(steps)
	assert_int(1, steps, 4)
	local turnFn

	if steps > 0 then
		turnFn = turtle.turnLeft
	else
		turnFn = turtle.turnRight
	end

	if terrapin.inertial_nav_enabled then
		terrapin.current_facing_direction = (terrapin.current_facing_direction + steps) % 4
	end
	
	if steps < 0 then steps	= -steps end

 	for i = 1, steps do
		turnFn()
	end
end

function terrapin._place(slot, placeFn)
	turtle.select(slot)
	local item_count = turtle.getItemCount(slot)
	
	if item_count == 0 then 
		turtle.select(terrapin.current_slot)
		return false, 0, "nothing in slot"
	end

	if placeFn() then
		turtle.select(terrapin.current_slot)
		return true, item_count - 1
	else
		turtle.select(terrapin.current_slot)
		return false, item_count, "unable to place block"
	end
end

--
-- Implementations - Movement
-- 

function terrapin.dig(steps)
	steps = steps or 1
	return _dig(turtle.dig, turtle.forward, turtle.detect, steps)
end

function terrapin.digUp(steps)
	steps = steps or 1
	return _dig(turtle.digUp, turtle.up, turtle.detectUp, steps)
end

function terrapin.digDown(steps)
	steps = steps or 1
	return _dig(turtle.digDown, turtle.down, turtle.detectDown, steps)
end


function terrapin.forward(steps)
	steps = steps or 1
	return _move(turtle.forward, steps)
end

function terrapin.back(steps)
	steps = steps or 1
	return _move(turtle.back, steps)
end

function terrapin.up(steps)
	steps = steps or 1
	return _move(turtle.up, steps)
end

function terrapin.down(steps)
	steps = steps or 1
	return _move(turtle.down, steps)
end


function terrapin.turnLeft(steps)
	steps = steps or 1
	_turn(steps)
end

function terrapin.turn(steps)
	steps = steps or 1
	if steps > 1 then
		terrapin.turnLeft(steps)
	else
		terrapin.turnRight(-steps)
	end
end

function terrapin.turnRight(steps)
	steps = steps or 1
	_turn(-steps)
end

--
-- Extra detection function
--

function terrapin.detectLeft()
	terrapin.turnLeft()
	local detected = terrapin.detect()
	terrapin.turnRight()

	return detected
end

function terrapin.detectRight()
	terrapin.turnRight()
	local detected = terrapin.detect()
	terrapin.turnLeft()

	return detected
end

--
-- Implementations - Inventory
--

function terrapin.place(slot)
	local slot = slot or terrapin.current_slot
	return terrapin._place(slot, turtle.place)
end

function terrapin.placeDown(slot)
	local slot = slot or terrapin.current_slot
	return terrapin._place(slot, turtle.placeDown)
end

function terrapin.placeUp(slot)
	local slot = slot or terrapin.current_slot
	return terrapin._place(slot, turtle.placeUp)
end

function terrapin.select(slot)
	turtle.select(slot)
	terrapin.current_slot = slot

	return turtle.getItemCount(slot), turtle.getItemSpace(slot)
end

function terrapin.getFreeSlots()
	local freeSlots = {}
	for slot = 1, terrapin.last_slot do
		if turtle.getItemCount(slot) == 0 then
			table.insert(freeSlots, slot)
		end
	end

	return freeSlots
end

function terrapin.getOccupiedSlots()
	local occupiedSlots = List()
	for slot = 1, terrapin.last_slot do
		if turtle.getItemCount(slot) > 0 then
			occupiedSlots:append(slot)
		end
	end

	return occupiedSlots
end

function terrapin.getFullSlots()
	local fullSlots = List()
	for slot = 1, terrapin.last_slot do
		if turtle.getItemSpace(slot) == 0 then
			fullSlots:append(slot)
		end
	end

	return fullSlots
end

function terrapin.dropAll()
	for i = 1, terrapin.last_slot do
		turtle.select(i)
		turtle.drop()
	end
end

-- this is broken
function terrapin.dropAllExcept(exceptions)
	for i = 1, terrapin.last_slot do
		if not tablex.find(exceptions, i) then
			turtle.select(i)
			turtle.drop()
		end
	end

	turtle.select(terrapin.current_slot)
end

function terrapin.selectNext(slots)
	if #slots >= 2 then
		if turtle.getItemCount(slots[1]) == 0 then
			slots:pop(1)
			terrapin.select(slots[1])
			return slots[1]
		end
	else
		return false
	end
end

--
-- Inertial/Relative Movement stuff
--

function terrapin.enableInertialNav()
	terrapin.inertial_nav_enabled = true
	terrapin.resetInertialNav()
end

function terrapin.disableInertialNav()
	terrapin.inertial_nav_enabled = false
end

function terrapin.resetInertialNav()
	terrapin.relative_pos = {["x"] = 0, ["y"] = 0, ["z"] = 0}
	terrapin.current_facing_direction = 0
end

function terrapin.getPos()
	return terrapin.relative_pos
end

--
-- Utility Functions
--

function terrapin.compareTo(slot)
	-- we call turtle.select directly, bypassing the terrapin API to avoid 
	-- changing the value of terrapin.current_slot
	turtle.select(slot)

	local ret_val = turtle.compare()
	turtle.select(terrapin.current_slot)

	return ret_val
end

--
-- Smart mining Stuff - template functions
--

local function _isOre(compareFnc, ores)
	if not compareFnc then error("no compare function", 2) end 
	if not ores then error("no ores var", 2) end

	for i = 1, #ores do
		terrapin.select(i)

		if compareFnc() then -- found ore
			return true
		end
	end

	return false -- found nothing
end

--
-- Smart mining Stuff Implementation
--

function terrapin.isOre(ores)
	return _isOre(terrapin.compare, ores)
end

function terrapin.isOreUp(ores)
	return _isOre(terrapin.compareUp, ores)
end

function terrapin.isOreDown(ores)
	return _isOre(terrapin.compareDown, ores)
end

terrapin.explore = nil -- forward declartion
function terrapin.explore(ores, sides)
	-- local sides = sides or List("front", "back", "up", "down", "left", "right")

	if terrapin.isOre(ores) then 
		terrapin.dig()
		terrapin.explore(ores)
		terrapin.back()
	end

	if terrapin.isOreUp(ores) then
		terrapin.digUp()
		terrapin.explore(ores)
		terrapin.digDown()
	end

	if terrapin.isOreDown(ores) then
		terrapin.digDown()
		terrapin.explore(ores)
		terrapin.digUp()
	end

	terrapin.turnLeft()
	if terrapin.isOre(ores) then
		terrapin.dig()
		terrapin.explore(ores)
		terrapin.back()
	end

	terrapin.turnRight(2)
	if terrapin.isOre(ores) then
		terrapin.dig()
		terrapin.explore(ores)
		terrapin.back()
	end

	-- realign the turtle
	terrapin.turnLeft()
end