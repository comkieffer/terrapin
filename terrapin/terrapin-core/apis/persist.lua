
--[[--
Simple persistent variables

@module persist
]]

local utils = require "sanelight.utils"
local class = require "sanelight.class"

class.Persist()

function Persist:_init(namespace, name)
	utils.assert_arg(1, namespace, 'string')
	utils.assert_arg(2, name, 'string')

	self.persist_base_dir = '/terrapin/variables'

	self.variable_path = fs.combine(
		fs.combine(self.persist_base_dir, namespace),  name)

	if fs.exists(self.variable_path) then
		persisted = fs.open(self.variable_path, 'r')

		-- Hey we're failing silently. I'm scared of calling error here beacuse
		-- I'm afraid of getting into an infinite loop where error calls does a
		-- checkin which requires the persist module, that fails ...
		if persisted then
			self._value = textutils.unserialize(persisted.readAll())
			persisted.close()
		end
	else
		self:set(nil)
	end
end

function Persist:set(value)
	self._value = value

	persisted = fs.open(self.variable_path, 'w')
	if self._value and persisted then
		persisted.write(textutils.serialize(self._value))
		persisted.close()
	end
end

function Persist:get()
	return self._value
end

return Persist
