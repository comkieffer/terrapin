
--- A SmartSlot is a wrapper around several slots used to create one "mega-slot"
--
-- The mega slot is created by passing it a list of slots. When you need to
-- pull items from the SmartSlot just call it to get the current slot. Once you
-- have placed a block call :update() to update the SmartSlot and remove any
-- empty slots from it.
--
-- Smart slots are very finnicky. They assume that you will religiously call
-- update immediately after placing blocks.
--

local class = require "pl.class"
local List  = require "pl.list"

local terrapin = require 'terrapin'

class.SmartSlot()

function SmartSlot:_init(initial_slots)
	self.slots = List(initial_slots)
	self:update()
end


--- Update the smart slot to remove any empty slots and return the number of
-- remaining items in the samrt slot.
function SmartSlot:update()
	local new_slots = List()
	for idx, slot in ipairs(self.slots) do
		if terrapin.getItemCount(slot) ~= 0 then
			new_slots:append(slot)
		end
	end
	self.slots = new_slots

	local blocks_remaining = 0
	for _,slot in ipairs(self.slots) do
		blocks_remaining = blocks_remaining + terrapin.getItemCount(slot)
	end

	return blocks_remaining
end

--- Get the index of the slot from which to pull objects from.
function SmartSlot:__call()
	if #self.slots > 0 then
		return self.slots[1]
	else
		error("Tried to get a slot number from an empty smart slot", 2)
	end
end

return SmartSlot
