
--[[--
Create transparent Mega-Slots from multiple slots.

A smart slot is an abstraction over a set of slots. It allows you to create a
virtual slot that never runs out !

The simplest way to create a smart slot is simply to pass the name of the item
you want it to contain:

	local Smartslot = require "smartslot"

	MySlot = Smartslot('minecraft:cobblestone')

When you need to access the Smartslot simply call it:

	local slot = MySlot()

This will select the slot. You can now access the contents of the lots easily.
If the Smartslot was unable to locate items that match then `slot` will be nil.
This allows you to check it it has run out easily:

	if not MySlot() then
		error('Nothing left to select')
	end

You can also retrieve the total number of items in the slot with:

	MySlot:count()

For more advanced usage you can pass a function into the constructor. This
allows you to have a more specific filter eg:

	local MySlot = SmartSlot(function(bloc)
		return block and block.damage > 100
	end)

@classmod SmartSlot
]]--

local class = require "sanelight.class"
local utils = require "sanelight.utils"

local terrapin = require 'terrapin'

class.SmartSlot()

--- Create the Smartslot.
--
-- @param predicate A string matching the name of the block to accept or a
--  function that accepts a table (the output of turtle.getItemDetail()) and
--  returns a boolean (True to accept the block)
function SmartSlot:_init(predicate)
	if type(predicate) == 'string' then
		self.predicate = function(block)
			return block and (block.name == predicate)
		end
	elseif utils.is_callable(predicate) then
		self.predicate = predicate
	else
		error(
			'Argument Error: expected string or callable as argument 1. ' ..
			'Got ' .. type(predicate)
		)
	end

	self.last_used_slot = 1
end

--- Select a slot in the Smartslot
--
-- @return The selected slot or nil if no slots could be found
function SmartSlot:select()
	local slot_details = terrapin.getItemDetail(self.last_used_slot)

	if self.predicate(slot_details) then
		terrapin.select(self.last_used_slot)
		return self.last_used_slot
	else
		local slots = terrapin.filterSlots(self.predicate)
		if #slots > 0 then
			terrapin.select(slots[1])
			self.last_used_slot = slots[1]
			return slots[1]
		end
	end

	return nil
end


--- Count the number of items in the inventory that match the predicate
--
-- @return The sum of all the items in the inventory that match the predicate
function SmartSlot:count()
	return terrapin.filterSlots(self.predicate):reduce(
		function(total, slot)
			return total + terrapin.getItemCount(slot)
		end, 0
	)
end

--- An alias from Smartslot:select()
function SmartSlot:__call()
	return self:select()
end

return SmartSlot
