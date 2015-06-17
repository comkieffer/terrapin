
local Counter = require 'sanelight.counter'

local isOre = {
	ore_counter = Counter(),

	patterns = {

		'ore$',                -- generic match. Works on most ores
		'^denseores',          -- Support for dense ores
		'orequartz$',          -- Applied energistics quartz ore
		'^minecraft:obsidian', -- consider obsidian a valuable ressource
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
