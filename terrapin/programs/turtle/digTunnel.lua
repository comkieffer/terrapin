--[[
	File: digtunnel

	Digs a tunnel of the specified proportions
	Note: the tunnel starting surface must be flat.
	      place the terrapin in the lower left corner
		  and run the program.

	Warning : the terrapin will auto empty if it is full

	@script digtunnel
]]--

local lapp = require "pl.lapp"

local ui       = require "ui"
local terrapin = require "terrapin"
local checkin  = require "checkin"

function digSlice(cmdLine)
	local dug_return_run = false
	local first_run = true

	terrapin.resetInertialNav()

	if cmdLine.height == 1 then
		-- print "Digging 1 run, 1 high tunnel"
		terrapin.dig(cmdLine.length)
		terrapin.turn(2)
	elseif cmdLine.height == 2 then
		-- print "digging 1 run 2 high tunnel"
		for i = 1, cmdLine.length do
			terrapin.dig()
			terrapin.digUp(0)
		end
		terrapin.turn(2)
	else
		for j = 1, cmdLine.height, 6 do
			-- print("A new beginning j = ", j)
			-- print ("if j + 3 (", j + 3, ") <= ", cmdLine.height + 1, ", dig an extra 3")

			if j + 3 <= cmdLine.height + 1  then
				print "true"
				dug_return_run = false

				if first_run then
					terrapin.digUp()
					first_run = false
				else
					terrapin.digUp(3)
				end

				for k = 1, cmdLine.length do
					terrapin.digUp(0)
					terrapin.digDown(0)
					terrapin.dig()
				end
				terrapin.digDown(0)
				terrapin.digUp(0)

				terrapin.turn(2)
			else
				print "false"
			end

			-- print ("if j + 6 (", j + 6, ") <= ", cmdLine.height + 1, ", dig an extra 3")

			if j + 6 <= cmdLine.height + 1  then
				print "true"
				dug_return_run = true

				terrapin.digUp(3)

				for k = 1, cmdLine.length do
					terrapin.digUp(0)
					terrapin.digDown(0)
					terrapin.dig()
				end
				terrapin.digDown(0)
				terrapin.digUp(0)

				terrapin.turn(2)
			else
				print "false"
			end

		end

		if cmdLine.height % 3 == 2 then
			-- print ("digging an extra 2")
			dug_return_run = not dug_return_run

			terrapin.digUp(2)

			for i = 1, cmdLine.length do
				terrapin.digUp(0)
				terrapin.dig()
			end

		elseif cmdLine.height % 3 == 1 then
			-- print "Digging and extra 1"
			dug_return_run = not dug_return_run

			terrapin.digUp(2)
			terrapin.dig(cmdLine.length)
--		else
--			print "No digging this time"
--			terrapin.forward(cmdLine.length)
		end
	end

	if not dug_return_run then
		-- print "Just going home ... "
		terrapin.forward(cmdLine.length)
	end

	-- go back down to start height
	-- print ("Currently at ", terrapin.getPos().y, " blocks high. Digging down.")
	terrapin.down(terrapin.getPos().y)
end

local args = { ... }
local usage = [[
	<width> (number)
	<height> (number)
	<length> (number)
	-e, --ender-chest dump inventory into ender chest.
]]

local cmdLine = lapp(usage, args)

-- check fuel level
local required_moves = cmdLine.length * cmdLine.height * cmdLine.width  -- digging moves
                     + 2 * (cmdLine.height - 1) * cmdLine.width -- repositioning after each slice

if not ui.confirmFuel(required_moves) then
	return
end

-- we use inertial nav to track the height of the turtle.
terrapin.enableInertialNav()

checkin.startTask('DigTunnel', cmdLine)

for i = 1, cmdLine.width - 1 do
	checkin.checkin('Digging Slice ' .. i .. " of " .. cmdLine.width)
	digSlice(cmdLine)

	-- print "dug slice ... pausing"
	-- read()

	terrapin.turnLeft()
	terrapin.dig()
	terrapin.turnLeft()
end

digSlice(cmdLine)
checkin.endTask()
