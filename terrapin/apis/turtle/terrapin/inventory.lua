
local terrapin = {}

--- Inventory Management
-- @section inventory

-- [TODO] - Revisit Slot mangament. There are too many ways that the current
--          slot might change that are not under control of terrapin.
--          does it even make sense to keep track of the current slot ?
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

--- Transfer items from one slot to another
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
		print('Considering slot: ', this_slot["slot"])

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

return terrapin
