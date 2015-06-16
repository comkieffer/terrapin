
local List  = require 'sanelight.list'
local class = require 'sanelight.class'

class.Counter()

function Counter:_init()
	self.items = {}
end

function Counter:__call(item)
	if self.items[item] then
		self.items[item] = self.items[item] + 1
	else
		self.items[item] = 1
	end

	return self.items[item]
end

function Counter:getItems()
	local items = List{}
	for k,v in pairs(self.items) do
		items:append({name = k, count = v})
	end

	return items:sorted(function(first, second)
		return first.count > second.count
	end)
end

return Counter
