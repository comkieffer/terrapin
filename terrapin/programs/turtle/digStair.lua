
local lapp     = require "pl.lapp"
local terrapin = require "terrapin"




function digStair(cmdLine)
	-- start
	terrapin.digUp(2)

	-- layer 1
	terrapin.dig(1)

	--layer 2
	terrapin.digDown()
	terrapin.dig(1)

	--layer 3
	terrapin.digDown()
	terrapin.turn(2)
	terrapin.dig(1, false)
	terrapin.turn(2)
	terrapin.forward()
	terrapin.dig(1)

	-- real stuff
	for i = 1, cmdLine.depth do
	  terrapin.digDown()
	  terrapin.turn(2)
	  terrapin.dig(2)
	  terrapin.turn(2)
	  terrapin.dig(3)
	end
end

function climbStair()
		terrapin.dig() -- just make sure we can move terrapin.forward
		terrapin.digUp()
end

local  args, usage = { ... }, [[
Dig stairs downwards. 
<depth> (number)    How deep should the stairs go
<width> (default 3) How wide should they be
]]

local cmdLine = lapp(usage, args)



for i = 1, cmdLine.width do
	digStair(cmdLine)
	terrapin.turn(2)

	for j = 1, cmdLine.depth do 
		terrapin.dig() -- just make sure we can move terrapin.forward
		terrapin.digUp()
	end

	terrapin.forward(3)
	
	if not (i == 3) then
		terrapin.turnLeft()
		terrapin.dig()
		terrapin.turnLeft()
	end
end