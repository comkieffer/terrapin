
--[[--
Get the block information for neighbouring blocks.

When run the turtle will call 'inspect' on the block immediately in front
of it, immediately underneath it and immediately above it.

This is useful as debugging tool to make sure that blocks have the right
name.

@script Inspect
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
