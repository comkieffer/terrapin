
--[[--
Simple persistent variables.

Persistent variables have been a pain point in computercraft for a long time.
This API makes them a breeze. The value of the variables is saved to a file in
`/terrapin/variables` every time they are set.

To create a persistent variable simply call:

	local Perist = require "persist"
	local Myvar = Persist('myprogram', 'myvar')

When the variable is created of the very first time it doesn't have a value. You
can set it's value at any time with:

	MyVar:set('Something')

And retrieve it with:

	MyVar:get()

Note: I purposefully avoided developping a solution that made persistent
variables look like ordinary tables with metamethod magic to make it obvious
that these variables are different.

@classmod persist
]]--

local utils = require "sanelight.utils"
local class = require "sanelight.class"

class.Persist()

--- Create a persistent variable
--
-- The namespace serves to avoid name collions. 2 different programs can use
-- variables with the same name as long as they use a distinct namespace.
--
-- @param namespace A namespace to store the variable in
-- @param name The name of the variable
function Persist:_init(namespace, name)
	utils.assert_arg(1, namespace, 'string')
	utils.assert_arg(2, name, 'string')

	self.persist_base_dir = '/terrapin/variables'

	self.variable_path = fs.combine(
		fs.combine(self.persist_base_dir, namespace),  name)

	if fs.exists(self.variable_path) then
		local persisted = fs.open(self.variable_path, 'r')

		if persisted then
			self._value = textutils.unserialize(persisted.readAll())
			persisted.close()
		else
			error('Unable to open persistent variable file: '..self.variable_path)
		end
	else
		self:set(nil)
	end
end

--- Set the value of the persistent variable
--
-- @param value The value of the variable
function Persist:set(value)
	self._value = value

	persisted = fs.open(self.variable_path, 'w')
	if self._value and persisted then
		persisted.write(textutils.serialize(self._value))
		persisted.close()
	end
end


--- Get the value of the persistent variable
--
-- @return The Value
function Persist:get()
	return self._value
end

return Persist
