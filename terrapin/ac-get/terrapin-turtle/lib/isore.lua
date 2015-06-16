
local Counter = require 'sanelight.counter'

local isOre = {
	ore_counter = Counter(),

	patterns = {
		-- generic match. Works on most ores
		'ore$',

		-- Support for dense ores
		'^denseores',

		-- consider obsidian a valuable ressource
		'^minecraft:obsidian',
	}
}

setmetatable(isOre, {__call = function(self, block)
		if not block then return false end

		for _, pattern in ipairs(isOre.patterns) do
			if block.name:lower():match(pattern) then
				self.ore_counter(block.name)
				return true
			end
		end

		return false
	end
})

function isOre.resetCounter()
	isOre.ore_counter = Counter()
end

function isOre.getMined()
	return isOre.ore_counter:getItems()
end

return isOre
