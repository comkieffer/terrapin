
require "terrapin"

local args = { ... } 

local turn_amount

function usage()
	print "digNext direction"
end

if #args ~= 1 then
	usage()
	return
end

if args[1] == "left" then
	turn_amount = 1
elseif args[1] == "right" then
	turn_amount == -1
else
	usage()
end


terrapin.up()
terrapin.turn(turn_amount)

local first_iteration = true

repeat
	if first_iteration then
		first_iteration = false
	else
		terrapin.turn(-turn_amount)
	end

	terrapin.forward(4)
	--turn to face potential mine
	terrapin.turn(turn_amount)
until terrapin.detect()

terrapin.down()

shell.run("digMine")

