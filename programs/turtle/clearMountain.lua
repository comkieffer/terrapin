

local args = { ... }
local usage = [[
<width>  (number)
<length> (number)
]]

local cmdLine = lapp(usage, args)

-- estimate fuel consumption. 
-- we suppose that a "mountain" is on averag 3 blocks high
local required_moves = (cmdLine.length * 5) * cmdLine.width
if not ui.confirmFuel(required_moves) then
	return
end

for i = 1, cmdLine.width do
	for j = 1, cmdLine.length do
		terrapin.dig() 

		-- dig all blocks above us 
		local steps = 0		
		while terrapin.detectUp() do
			terrapin.digUp()
			steps = steps + 1
		end

		terrapin.down(steps)
	end
	print(width, cmdLine.length)
	terrapin.turn(2)
	terrapin.forward(cmdLine.length)

	-- position for next mine
	if i ~= cmdLine.width then
		terrapin.turnLeft()
		terrapin.forward()
		terrapin.turnLeft()
	end
end
