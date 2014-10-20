
--[[--
	Cut down a tree.

	Place the turtle in front of the tree. It will dig up until it has nothing
	overhead and come back down.

	@script cut
]]

local terrapin = require "terrapin"

if terrapin.detect() then
	terrapin.dig()
end

local tree_size = 0
while terrapin.detectUp() do
	terrapin.digUp()
	tree_size = tree_size + 1
end

terrapin.digDown(tree_size)
