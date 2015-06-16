
local isOre = {
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
				return true
			end
		end

		return false
	end
})


return isOre
