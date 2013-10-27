
require "terrapin"

function usage()
  print "USAGE : digstair depth"
  return false
end

function digStair()
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
	for i = 1, depth do
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

args = { ... }

if #args < 1 then
  usage()
  return false
else
  depth = tonumber(args[1])
end

for i = 1, 3 do
	digStair()
	terrapin.turn(2)

	for j = 1, depth do 
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