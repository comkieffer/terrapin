
--[[--
	Get the block information for the blocks immediatel under, over and in front
	of the turtle.

	This is useful as debugging tool to make sure that blocks have the right
	name.

	@script inspect
]]

terrapin = require "terrapin"

local function inspect(inspectFn, direction)
	local success, data = inspectFn()

	if success then
		print(direction .. " :")
		print("\tBlock name: ", data.name)
		print("\tBlock metadata: ", data.metadata)
	else
		print("Inspect failed.")
	end
end

inspect(terrapin.inspect, 'Front')
inspect(terrapin.inspectUp, 'Up')
inspect(terrapin.inspectDown, 'Down')
