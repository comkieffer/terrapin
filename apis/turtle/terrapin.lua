
--- A powerful set of extensions to the default turtle API
-- This is the meat of the Terrapin API compilation. It enables smart digging (will dig through
-- gravel and sand fine), inertial navigation, block detection and smart mining. It also provieds
-- a full abstraction of the turtle API. 
--
-- To enable terrapin just replace all instances of turtle.* with terrapin.*
--
-- @module terrapin

local List   = require "pl.List"
local tablex = require "pl.tablex"

local utils  = require "utils"

--- Configuration options for terrapin.
-- Eventually it will be possible to override them from a configuration file
local terrapin = {
	["max_move_attempts"] = 10,          -- how many times to retry moves if they fail
	["wait_between_digs"] = 0.5,         -- how long to wait between 2 consecutive digs.
	                                     -- This is useful when mining gravel or sand. 
	                                     -- Too slow and digging is slow, too fast and some
	                                     -- gravel won't get mined
	["wait_between_failed_moves"] = 0.5, -- How long to wait before trying to move again after
	                                     -- a failure

	-- State variables
	["state"] = {
		["current_slot"] = 1,
	},

	-- inertial nav API settings
	["inertial_nav"] = {
		["enabled"] = false,
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
	},

	-- explore api settings
	["explore"] = {
	},

	-- turtle vars
	["last_slot"] = 16,
	["error_on_move_without_fuel"] = true,

	-- turtle functions that simply get passed through
	["detect"]       = turtle.detect,
	["detectUp"]     = turtle.detectUp,
	["detectDown"]   = turtle.detectDown,
	["suck"]         = turtle.suck,
	["suckUp"]       = turtle.suckUp,
	["suckDown"]     = turtle.suckDown, 
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
	local pos  = terrapin.inertial_nav.relative_pos
	local dirs = terrapin.inertial_nav.directions
	local dir  = terrapin.inertial_nav.current_facing_direction

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

	if terrapin.inertial_nav.enabled then
		terrapin.inertial_nav.current_facing_direction = 
			(terrapin.inertial_nav.current_facing_direction + steps) % 4
	end
	
	if steps < 0 then steps	= -steps end

 	for i = 1, steps do
		turnFn()
	end
end

local function _place(slot, placeFn)
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

--- Move the specified number of steps
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
	_turn(steps)
end

--- TurnLeft
-- @param steps how many tiems to turn.
function terrapin.turnRight(steps)
	steps = steps or 1
	_turn(-steps)
end

--
-- Extra detection function
--

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

--
-- Implementations - Inventory
--

--- Place a block from slot *slot* in front of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block 
-- @return the number of items remaining in the slot
-- @return and optional error message 
function terrapin.place(slot)
	local slot = slot or terrapin.current_slot
	return _place(slot, turtle.place)
end

--- Place a block from slot *slot* in under of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block 
-- @return the number of items remaining in the slot
-- @return and optional error message 
function terrapin.placeDown(slot)
	local slot = slot or terrapin.current_slot
	return _place(slot, turtle.placeDown)
end

--- Place a block from slot *slot* in over of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block 
-- @return the number of items remaining in the slot
-- @return and optional error message 
function terrapin.placeUp(slot)
	local slot = slot or terrapin.current_slot
	return _place(slot, turtle.placeUp)
end

--- Select a slot in the inventory.
-- @param slot the slot to select
-- @return the number of items in the slot
-- @return the amount of free space in the slot
function terrapin.select(slot)
	turtle.select(slot)
	terrapin.current_slot = slot

	return turtle.getItemCount(slot), turtle.getItemSpace(slot)
end

--- Get a list of free slots in the turtle.
-- @return a List() containing all the slots with no objects
function terrapin.getFreeSlots()
	local freeSlots = {}
	for slot = 1, terrapin.last_slot do
		if turtle.getItemCount(slot) == 0 then
			table.insert(freeSlots, slot)
		end
	end

	return freeSlots
end

--- Get a list of occupied slots in the turtle.
-- @return a List() containing all the slots with at least 1 item.
function terrapin.getOccupiedSlots()
	local occupiedSlots = List()
	for slot = 1, terrapin.last_slot do
		if turtle.getItemCount(slot) > 0 then
			occupiedSlots:append(slot)
		end
	end

	return occupiedSlots
end

--- Get a list of all the full slots.
-- @return a List() containg all the lots with no space left.
function terrapin.getFullSlots()
	local fullSlots = List()
	for slot = 1, terrapin.last_slot do
		if turtle.getItemSpace(slot) == 0 then
			fullSlots:append(slot)
		end
	end

	return fullSlots
end

--
-- Drop Functions
--

local function _drop(dropFn, slot, amount)
	turtle.select(slot)
	if amount >= 0 then 
		dropFn(amount)
	else
		dropFn(turtle.getItemCount(slot) + amount)
	end

	turtle.select(terrapin.current_slot)
end

--- Drop @c amount items from @c slot 
-- if amount is negative then -amount is the number of items that will be left 
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items 
--        to leave in the inventory after the drop

function terrapin.drop(slot, amount)
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.drop, slot, amount)
end

--- Drop @c amount items from @c slot 
-- if amount is negative then -amount is the number of items that will be left 
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items 
--        to leave in the inventory after the drop
function terrapin.dropDown(slot, amount)
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.dropDown, slot, amount)
end

--- Drop @c amount items from @c slot 
-- if amount is negative then -amount is the number of items that will be left 
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items 
--        to leave in the inventory after the drop
function terrapin.dropUp()
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.dropUp, slot, amount)
end

--- Drop all the items in the rutle's inventory.
function terrapin.dropAll()
	for i = 1, terrapin.last_slot do
		turtle.select(i)
		turtle.drop()
	end
end

--- Drop all the items in the turtle's inventory except for thos contained in the exceptions table
-- @param exceptions a table containing the number of every slot that should not be emptied
function terrapin.dropAllExcept(exceptions)
	for i = 1, terrapin.last_slot do
		if not tablex.find(exceptions, i) then
			turtle.select(i)
			turtle.drop()
		end
	end

	turtle.select(terrapin.current_slot)
end

--[[
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
]]

--
-- Inertial/Relative Movement stuff
--

--- Enable the inertial movement API
function terrapin.enableInertialNav()
	terrapin.inertial_nav_enabled = true
	terrapin.resetInertialNav()
end

--- Disable the inertial movement API
function terrapin.disableInertialNav()
	terrapin.inertial_nav_enabled = false
end

--- Reset the inertial movement API.
-- position and ritation will be reset to their starting values.
function terrapin.resetInertialNav()
	terrapin.inertial_nav.relative_pos = {["x"] = 0, ["y"] = 0, ["z"] = 0}
	terrapin.inertial_nav.current_facing_direction = 0
end

--- Get the turtle's position relative to when the API was last enabled or reset.
function terrapin.getPos()
	return terrapin.inertial_nav.relative_pos
end

--
-- Utility Functions
--

--- Compare the block directly in front of the turtle a any block in it's inventory.
-- @param slot the slot the item with which to compare the blokc in front of the turtle
-- @return true if the blocks contained in the selected slot and the blokc in front of the turtle 
-- are the same
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

function terrapin.setExploreMode(search_for_valuable_blocks)
	if typeof(search_for_valuable_blocks) ~= "boolean" then
		error ("terrapin.setExploreMode : expected boolean")
	end

	terrapin.search_for_valuable_blocks = search_for_valuable_blocks
end

--
-- @param search_for_valuable_blocks if set to true we consider the blocks in the *blocks* array
-- as trash. Otherwise we consider them valuable.
local function _isOre(detectFn, compareFn, blocks)
	if not detectFn then error("no detect function", 2) end 
	if not compareFn then error("no compare function", 2) end 
	if not blocks then error("no trash_blocks var", 2) end

	if detectFn() then
		for i = 1, #blocks do
			terrapin.select(blocks[i])

			-- match the block in front of us with the currently selected block
			-- in the inventory. If compare() return true then the block is trash
			if compareFn() then 
				return false
			end
		end

		-- We have gone through our trash_blocks and not found a match. The block 
		-- is important.
		return true
	else -- we are looking at empty space, water or lava
		return false
	end
end

--
-- Smart mining Stuff Implementation
--

function terrapin.isOre(trash_blocks)
	return _isOre(terrapin.detect, terrapin.compare, trash_blocks)
end

function terrapin.isOreUp(trash_blocks)
	return _isOre(terrapin.detectUp, terrapin.compareUp, trash_blocks)
end

function terrapin.isOreDown(trash_blocks)
	return _isOre(terrapin.detectDown, terrapin.compareDown, trash_blocks)
end

terrapin.explore = nil -- forward declartion

--- Inspect all blocks around the turtle and detect if any are interesting. 
-- Interesting blocks are defined by default. If a block is not trash then
-- we consider it interesting.
-- This cause unexpected blocks like wood, fences, cobbleston to be counted as 
-- valuable blocks. A more complete approach would require giving the turtle a
-- copy of each ore we want to extract. This requires more setup time, especially
-- in modded versions of minecraft (ftb, tekkit, ...)
-- The trash_blocks array which contains the slots in the turtle that contain
-- common blocks (smooth stone, dirt, ...)
--
-- @param trash_blocks what blocks should be considered interesting
function terrapin.explore(trash_blocks)
	assert(trash_blocks, "Missing require parameter : trash_blocks", 2)
	-- local sides = sides or List("front", "back", "up", "down", "left", "right")

	if terrapin.isOre(trash_blocks) then 
		terrapin.dig()
		terrapin.explore(trash_blocks)
		terrapin.back()
	end

	if terrapin.isOreUp(trash_blocks) then
		terrapin.digUp()
		terrapin.explore(trash_blocks)
		terrapin.digDown()
	end

	if terrapin.isOreDown(trash_blocks) then
		terrapin.digDown()
		terrapin.explore(trash_blocks)
		terrapin.digUp()
	end

	terrapin.turnLeft()
	if terrapin.isOre(trash_blocks) then
		terrapin.dig()
		terrapin.explore(trash_blocks)
		terrapin.back()
	end

	terrapin.turnRight(2)
	if terrapin.isOre(trash_blocks) then
		terrapin.dig()
		terrapin.explore(trash_blocks)
		terrapin.back()
	end

	-- realign the turtle
	terrapin.turnLeft()
end

return terrapin
