
function fillLine(cmdLine)
	for j = 1, cmdLine.length do
		local depth = 1

		-- detect the depth we need to fill
		while not terrapin.detectDown() do
			depth = depth + 1
		end

		-- do the filling
		for k = 1, depth - 1 do
			terrapin.up()
			terrapin.placeDown()
		end

		terrapin.dig()
	end
end

local args = { ... }
local usage = [[
<width> (number)
<length> (number)
]]

local cmdLine = lapp(usage, args)

-- we suupose that the fill will be 3 deep, this is only a guideline.
local required_moves = 3 * cmdLine.length * cmdLine.width()
if not ui.confirmFuel(requiredFuel) then
	return
end

for i = 1, cmdLine.width, 2 do
	fillLine()

	-- align the turtle for the return run
	terrapin.turnRight()
	terrapin.dig()
	terrapin.turnRight()

	fillLine()

	-- allign for new line 
	if i ~= cmdLine.width then
		terrapin.turnLeft()
		terrapin.dig()
		terrapin.turnLeft()
	end
end

if cmdLine.width % 2 == 1 then
	fillLine()
	terrapin.turn(2)
	terrapin.forward(cmdLine.length)
end