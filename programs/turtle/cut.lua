
require "terrapin"

if terrapin.detect() then
	terrapin.dig()
end

local tree_size = 0
while terrapin.detectUp() do
	terrapin.digUp()
	tree_size = tree_size + 1
end

terrapin.digDown(tree_size)