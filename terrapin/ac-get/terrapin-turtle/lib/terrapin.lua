
--[[-- A powerful set of extensions to the default turtle API.

This is the meat of the Terrapin API compilation. It enables smart digging (will
dig through gravel and sand fine), inertial navigation, block detection and
smart mining. It also provieds a full abstraction of the turtle API.

The terrapin API is fully compatible with the turtle API. You can replace all
instances of turtle in your code with terrapin and your code will still work.

## Getting started

All the packages of the terrapin API collection use 'require' to load modules
instead of os.loadAPI(). This design choice is explained in the introduction to
the terrapin API collection. As a user the only thing you need to know is that
you need to require terrapin at the beginning of your program:

	local terrapin = require 'terrapin'

The API can be decomposed into different sets of functions:

- Smart Movement & Digging
- Inventory Management
- Inertial Navigation
- Exlporation / Intelligent mining

### Smart Movement

The smart movement function replace the stock turtle movement functions. They
allow you to write terrapin.move(10) to move 10 block forward or
terrapin.digUp(10) to 10 blocks up.

The digging functions will dig until the block in front of them is actually free
before finishing. This means that digging through grave or sand is not an issue.

### Inventory Management

The inventory management functions provide shortcuts for common operations.

-- Check that the turtle API hasn't changed for these. Are they redundant

### Inertial Navigation

The inertial navigation system allows you to track where the turtle is in space
relative to the point where it was initialised. In most cases this is more
useful than absolute positioning.

To start simply initialise the inertial navigation subsystem :

	terrapin.enableInertialNav()

This resets the position and sets the enabled flag. Whenever you use a terrapin
movement function the position will be updated. To get the current position and
facing direction you can use :

	local pos, dir = terrapin.getPos(), terrapin.getFacing()


To move somewhere just use :

	terrapin.goTo(coords)
	terrapin.turnTo('+x')

	-- or, to go to {0 0 0}

	terrapin.goToStart()

### Exploration

The exploration module powers the intelligent mode of the digmine script. It
allows turtles to autonomously dig out entire veins of ores or other valuable
blocks. You just need to provide it with a suitable filter function.

To start exploring you just need to call terrapin.explore with a suitable
function. A simple filter to just mine vanilla minecraft ores is:

	terrapin.explore(function(block)
		return (block and block.name:match('ore$'))
	end)

This will not handle ores from other mods very well. See the isOre library for a
more complete implementation.

The other useful part of the explore subsystem is terrapin.visit(). This
function allows to write programs that pass over every block in a rectangular
area in an efficient manner without much code. This powers the clear and fill
scripts for example.

@module terrapin
]]

local List    = require "sanelight.List"
local utils   = require "sanelight.utils"
local tablex  = require "sanelight.tablex"
local stringx = require "sanelight.stringx"
local types   = require "sanelight.types"

local Persist = require "persist"

--[[
              CONFIGURTION FOR TERRAPIN
]]

local terrapin = {
	-- how many times to retry moves if they fail
	["max_move_attempts"] = 10,

	-- how long to wait between 2 consecutive digs.
	-- This is useful when mining gravel or sand. Too slow and digging is slow,
	-- too fast and somegravel won't get mined
	["wait_between_digs"] = 0.5,

	-- How long to wait before trying to move again after a failure
	["wait_between_failed_moves"] = 0.5,

	-- State variables
	["state"] = {
		["blocks_dug"]   = 0,
	},

	-- inertial nav API settings
	["inertial_nav"] = {
		["enabled"] = false,
		["directions"] = {
			-- when turning left +1
			-- when turning right -1
			["+x"] = 0, ["+z"] = 1, ["-x"] = 2, ["-z"] = 3
		},
	},

	-- turtle vars
	["last_slot"] = 16,

	-- Beware, the code has not received enough testing for different values of
	-- variables. Unpredicatble things might happen if you change them.
	["error_on_move_without_fuel"] = true,
	["error_on_failed_move"] = true,
}

--[[
            TERRAPIN METHODS
]]

-- Set the __index function to look for keys that aren't present in the terrapin
-- API in the turtle API. This means that we don't have to play catchup at every
-- release of CC. Any new methods will be found automatically.
setmetatable(terrapin, {
	['__index'] = function(self, key)
		if turtle[key] then
			return turtle[key]
		else
			error(key .. " is not a valid method for terrapin", 2)
		end
	end
})

--[[

              Terrapin Movement APIs

]]

local function _update_relative_pos(moveFn)
	local pos  = terrapin.inertial_nav.relative_pos
	local dirs = terrapin.inertial_nav.directions
	local dir  = terrapin.inertial_nav.current_facing_direction

	if moveFn == turtle.up then
		pos.y = pos.y + 1
	elseif moveFn == turtle.down then
		pos.y = pos.y - 1
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

--- Try to move and graciously fail if the movement is impossible.
-- @param moveFn The movement function to try
-- @return The number of blocks that the turlte has effectively moved
local function _tryMove(moveFn)
	utils.assert_arg(1, moveFn, 'function')

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
		_update_relative_pos(moveFn)
	end

	if has_moved then
		total_moves = Persist('terrapin', 'total_moves')
		total_moves:set((total_moves:get() or 0) + 1)

		local rel_pos = {}
		if terrapin.inertialNavEnabled() then
			rel_pos = terrapin.getPos()
		end

		os.queueEvent('terrapin:moved', rel_pos)
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
-- @section digging

local function _dig(digFn, moveFn, detectFn, steps)
	utils.assert_arg(1, digFn, 'function')
	utils.assert_arg(2, moveFn, 'function')
	utils.assert_arg(3, detectFn, 'function')
	utils.assert_arg(4, steps, 'number')

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

				local status, block = turtle.inspect()
				os.queueEvent('terrapin:dug', block)

				sleep(terrapin.wait_between_digs)
			end

			_tryMove(moveFn)
			moved = moved + 1
		end  -- end for
	end -- end if steps == 0

	if dug > 0 then
		total_blocks_dug = Persist('terrapin', 'total_blocks_dug')
		total_blocks_dug:set((total_blocks_dug:get() or 0) + dug)
	end

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
-- @return how many blocks were dug, how many times did the turtle succesfully move forward.
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

--- Retrieve the number of blocks a turtle has dug since it was created.
--
-- This is implemented using persistent variables
function terrapin.total_blocks_dug()
	return Persist('terrapin', 'total_blocks_dug'):get() or 0
end

--- Retrieve the number of blocks a turtle has moved since it was created.
--
-- This is implemented using persistent variables
function terrapin.total_moves()
	return Persist('terrapin', 'total_moves'):get() or 0
end

--[[

              Terrapin Inventory APIs

]]

--- Inventory Management
-- @section inventory

--- Internal method. Place a block and return useful information about the slot.
local function _place(slot, placeFn)
	turtle.select(slot)
	local item_count = turtle.getItemCount(slot)

	if item_count == 0 then
		-- turtle.select(terrapin.current_slot)
		return false, 0, "nothing in slot"
	end

	if placeFn() then
		-- turtle.select(terrapin.current_slot)
		return true, item_count - 1
	else
		-- turtle.select(terrapin.current_slot)
		return false, item_count, "unable to place block"
	end
end

--- Place a block from slot *slot* in front of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block
-- @return the number of items remaining in the slot
-- @return and optional error message
function terrapin.place(slot)
	local slot = slot or turtle.getSelectedSlot()
	return _place(slot, turtle.place)
end

--- Place a block from slot *slot* in under of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block
-- @return the number of items remaining in the slot
-- @return and optional error message
function terrapin.placeDown(slot)
	local slot = slot or turtle.getSelectedSlot()
	return _place(slot, turtle.placeDown)
end

--- Place a block from slot *slot* in over of the turtle.
-- @param slot the slot from which to pull the block
-- @return true if the turtle was able to place the block
-- @return the number of items remaining in the slot
-- @return and optional error message
function terrapin.placeUp(slot)
	local slot = slot or turtle.getSelectedSlot()
	return _place(slot, turtle.placeUp)
end

--- Select a slot in the inventory.
-- @param slot the slot to select
-- @return the number of items in the slot
-- @return the amount of free space in the slot
function terrapin.select(slot)
	turtle.select(slot)

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

--- Wrapp turtle.getItemDetail but return more information.
--
-- In addition to returning information about the item we return informatio
-- about the slot.
--
-- @param slot The slot to inspect
-- @return A table containing the standard getItemDetail data (name, damage),
-- the number of items in the slot and the number of free spots in the slot
function terrapin.getItemDetail(slot)
	local slot_info = turtle.getItemDetail(slot)

	if slot_info then
		slot_info['slot']  = slot
		slot_info['items'] = terrapin. ???
		slot_info['free space'] = terrapin. ???

		return slot_info
	end

	return nil
end

--- Apply a predicate to the each inventory slot
--
-- This allows you to retrieve a list of all the slots that match a certain
-- criteria. If, for example, you wanted a list of all the slots containing
-- items from vanilla minecraft and not mods you would do:
--
-- 	local mc_slots = terrapin.filterSlots(function(slot_info))
--		return (slot_info and slot_info:match('^minecraft:'))
-- 	end)
--
-- @param pred The predicate to apply
-- @return The slots that match the predicate
function terrapin.filterSlots(pred)
	local valid_slots = List()

	for slot = 1, terrapin.last_slot do
		local data = terrapin.getItemDetail(slot)

		if data and pred(data) then
			valid_slots:append(slot)
		end
	end

	return valid_slots
end

--- Transfer items from one slot to another.
--
-- If the destination slot doesn't have enough room for the items in the source
-- slot then the source slot will not be empty after the transfer. It will
-- contain all the leftover items.
--
-- @param source_slot The slot from which to take the items
-- @param dest_slot The slot in which to put the items
-- @return The number of items in the source slot and the number fo items in
--	the destination slot
function terrapin.transferItems(source_slot, dest_slot)
	local old_slot = turtle.getSelectedSlot()

	turtle.select(source_slot)
	turtle.transferTo(dest_slot)

	local items_in_source = turtle.getItemCount(source_slot)
	local items_in_dest = turtle.getItemCount(dest_slot)
	turtle.select(old_slot)

	return items_in_source, items_in_dest
end

-- Attempt to compact the inventory by stacking blokcs together.
-- When mining turtles just stick blocks in the first avalalble slot. We
-- manually restack them to free up space
--
-- @param fixed_slots a List() containing slots who must not be moved !
function terrapin.compactInventory(fixed_slots)
	local fixed_slots = fixed_slots or List()
	local all_slots = List()

	-- Find all the non empty slots.
	for i = 1, terrapin.last_slot do
		if terrapin.getItemCount(i) > 0 then
			all_slots:append({
				["slot"]   = i,
				["name"]   = terrapin.getItemDetail(i).name,
				["amount"] = terrapin.getItemCount(i),
			})
		end
	end

	-- Relocateable slots are slots who's content can be moved.
	local relocateable_slots = all_slots:filter(function(el)
		return not fixed_slots:contains(el)
	end)

	for i = 1, #relocateable_slots do
		local this_slot = all_slots[i]

		for j = i + 1, #all_slots do
			local that_slot = relocateable_slots[j]

			if this_slot["name"] == that_slot["name"] then
				local source_items, _ = terrapin.transferItems(this_slot["slot"], that_slot["slot"])

				-- If the current slot is empty we can stop looking for places
				-- into which to put its contents.
				if source_items == 0 then
					break
				end
			end
		end -- #all_slots
	end -- #relocateable_slots
end

-- Drop Functions
-- @section drop

local function _drop(dropFn, slot, amount)
	local old_slot = turtle.getSelectedSlot()

	turtle.select(slot)
	if amount >= 0 then
		dropFn(amount)
	else
		dropFn(turtle.getItemCount(slot) + amount)
	end

	turtle.select(old_slot)
end

--- Drop amount items from slot
-- if amount is negative then -amount is the number of items that will be left
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items
--  to leave in the inventory after the drop

function terrapin.drop(slot, amount)
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.drop, slot, amount)
end

--- Drop amount items from slot
-- if amount is negative then -amount is the number of items that will be left
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items
--  to leave in the inventory after the drop
function terrapin.dropDown(slot, amount)
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.dropDown, slot, amount)
end

--- Drop amount items from slot
-- if amount is negative then -amount is the number of items that will be left
-- in the slot after the drop
--
-- @param slot The slot to drop the items from
-- @param amount The amount of items to drop (amount >= 0) or the number of items
--  to leave in the inventory after the drop
function terrapin.dropUp(slot, amount)
	amount = amount or terrapin.getItemCount(slot)
	_drop(turtle.dropUp, slot, amount)
end

--- Drop all the items in the rutle's inventory.
function terrapin.dropAll()
	for i = 1, terrapin.last_slot do
		terrapin.drop(i)
	end
end

--- Drop all the items in the turtle's inventory except for thos contained in the exceptions table
-- @param exceptions a table containing the number of every slot that should not be emptied
function terrapin.dropAllExcept(exceptions)
	for i = 1, terrapin.last_slot do
		if not tablex.find(exceptions, i) then
			terrapin.drop(i)
		end
	end
end

--- Compare the block directly in front of the turtle a any block in it's inventory.
-- @param slot the slot the item with which to compare the blokc in front of the turtle
-- @return true if the blocks contained in the selected slot and the blokc in front of the turtle
-- are the same
function terrapin.compareTo(slot)
	local old_slot = turtle.getSelectedSlot()
	turtle.select(slot)

	local ret_val = turtle.compare()

	turtle.select(old_slot)
	return ret_val
end

--- Extends turtle.getItemDetail by adding a 'mod' and an 'item' field.
-- Whilst not revolutionary this avoids some tedious string splitting everytime
-- we want to pretty print an item name. This function is 100% compatible with
-- the vanilla version. The 'name' field is not changed at all.
--
-- @param slot The slot to analyze or the current slot
-- @return A table containing the following :
--		{ ['mod'], ['item'], ['name'], ['damage'], ['count'] }
function terrapin.getItemDetail(slot)
	data = turtle.getItemDetail(slot)

	if data then
		data['mod'], data['item'] = stringx.split(data['name'], ':')
	end

	return data
end

--[[

              Terrapin Inertial Navigation APIs

]]

--- Inertial/Relative Movement stuff
-- @section inertial

--- Enable the inertial movement API
function terrapin.enableInertialNav()
	terrapin.inertial_nav.enabled = true
	terrapin.resetInertialNav()
	terrapin.inertial_nav.initial_pos = terrapin.getPos()
end

--- Is the inertial anav subsystem enabled ?
function terrapin.inertialNavEnabled()
	return terrapin.inertial_nav.enabled
end

--- Disable the inertial movement API
function terrapin.disableInertialNav()
	terrapin.inertial_nav.enabled = false
end

--- Reset the inertial movement API.
-- position and ritation will be reset to their starting values.
function terrapin.resetInertialNav()
	terrapin.inertial_nav.relative_pos = {["x"] = 0, ["y"] = 0, ["z"] = 0}
	terrapin.inertial_nav.current_facing_direction = 0
end

--- Get the turtle's position relative to when the API was last enabled or reset.
function terrapin.getPos()
	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	pos = tablex.copy(terrapin.inertial_nav.relative_pos)
	pos['turn'] = terrapin.inertial_nav.current_facing_direction

	return pos
end

-- Get the direction the turtle is facing
function terrapin.getFacing()
	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	return terrapin.inertial_nav.current_facing_direction
end

--- Turn to face the specfied direction.
--
-- Directions can be specified in 2 ways :
-- - As human readable strings : "+x", "-x", "+z", "-z"
-- - As a number indicating the amount of times the turtle should turn right to
-- face that direction.
--
-- @param direction The direction to turn to
function terrapin.turnTo(direction)
	assert(direction)

	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	local target_dir, turns = 0, 0

	if type(direction) == 'string' then
		if not terrapin.inertial_nav.directions[direction] then
			error('ERROR: "' .. direction ..'" is not a valid direction.' )
		else
			target_dir = terrapin.inertial_nav.directions[direction]
		end
	elseif type(direction) == 'number' then
		target_dir = direction
	end

	-- print('DEBUG: Target dir  : ' ..target_dir)
	-- print('DEBUG: Current dir : ' .. terrapin.inertial_nav.current_facing_direction)

	while terrapin.inertial_nav.current_facing_direction ~= target_dir do
		terrapin.turn()
		-- print('DEBUG: Turning - facing : ' .. terrapin.inertial_nav.current_facing_direction)
	end

	return turns
end

--- Move to the specified postio in the world.
--
-- The position shoudl be a table like :
--
-- 		{ ["x"] = 0, ["y"] = 10, ["z"] = 0, ["turn"] = 0 }
--
-- The table specifies the 3 coordinates relative to the turtle :
-- - the 'x' axis extends in front of the turtle
-- - the 'y' axis extends above and below the turtle
-- - the 'z' axis extends to the left and right of the turtle
--
-- The final component 'turn' identifies the direction the turtle should face.
--  @see terrapin.turnTo for more information on this.
--
-- @param position the position to move to
-- @param move_order (option) The order in which to execute the moves
function terrapin.goTo(position, move_order)
	move_order = move_order or {"x", "z", "y"}

	current_pos = terrapin.getPos()

	pos_diff = {
		["x"] = current_pos["x"] - position["x"],
		["y"] = current_pos["y"] - position["y"],
		["z"] = current_pos["z"] - position["z"],
		["turn"] = (position["turn"] - current_pos["turn"]) % 4
	}

	local function goto_y()
		if pos_diff['y'] ~= 0 then
			if pos_diff['y'] > 0 then
				terrapin.digDown(pos_diff['y'])
			else
				terrapin.digUp(-pos_diff['y'])
			end
		end
	end

	local function goto_x()
		if pos_diff['x'] ~= 0 then
			if pos_diff['x'] > 0 then
				terrapin.turnTo('-x')
				terrapin.dig(pos_diff['x'])
			else
				terrapin.turnTo('+x')
				terrapin.dig(-pos_diff['x'])
			end
		end
	end

	local function goto_z()
		if pos_diff['z'] ~= 0 then
			if pos_diff['z'] > 0 then
				terrapin.turnTo('-z')
				terrapin.dig(pos_diff['z'])
			else
				terrapin.turnTo('+z')
				terrapin.dig(-pos_diff['z'])
			end
		end
	end

	for i = 1, #move_order do
		if move_order[i] == 'x' then
			goto_x()
		elseif move_order[i] == 'z' then
			goto_z()
		elseif move_order[i] == 'y' then
			goto_y()
		else
			error('Found invalid move direction : ' .. move_order[i])
		end
	end

	-- turn to face the right direction
	terrapin.turnTo(position["turn"])
end

-- Returns to the position where the inertialNav was initiated and turns to face
-- the right direction
function terrapin.goToStart( ... )
	terrapin.goTo(terrapin.inertial_nav.initial_pos, ... )
end

--[[

              Terrapin Exploration APIs

]]

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
	if not types.is_callable(callback) then
		error('Expected callable as argument 1. Was '.. type(callback), 2)
	end

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
	utils.assert_arg(1, width, 'number')
	utils.assert_arg(2, length, 'number')
	utils.assert_arg(3, dig, 'boolean')
	utils.assert_arg(4, onMoveFinished, 'function')

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
