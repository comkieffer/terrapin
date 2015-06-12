
--- Create transparent Mega-Slots from multiple slots.
--
-- The mega slot is created by passing it a list of slots. When you need to
-- pull items from the SmartSlot just call it to get the current slot. Once you
-- have placed a block call :update() to update the SmartSlot and remove any
-- empty slots from it.
--
-- Smart slots are very finnicky. They assume that you will religiously call
-- update immediately after placing blocks.
--
-- @classmod SmartSlot
--

local class = require "sanelight.class"
local utils = require "sanelight.utils"

local terrapin = require 'terrapin'

class.SmartSlot()

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

function SmartSlot:count()
	return terrapin.filterSlots(self.predicate):reduce(
		function(total, slot)
			return total + terrapin.getItemCount(slot)
		end, 0
	)
end

function SmartSlot:__call()
	return self:select()
end

return SmartSlot
