
local lapp = require "pl.lapp"
local List = require "pl.List"
local pretty = require "pl.pretty"
local tablex = require "pl.tablex"

local ui = require "ui"
local terrapin = require "terrapin"

-- TODO stop placing torches when they have run out
function makeAlcove(torch_slots)
	local continue_placing_torches = true
	terrapin.turnRight()
	terrapin.dig(0)
	

	_, remaining_torches = terrapin.place(torch_slots[1])
	if remaining_torches == 0 then
		torch_slots.pop(cmdLine.torch_slots)

		if #torch_slots == 0 then
			continue_placing_torches = false
		end
	end

	terrapin.turnLeft()

	return continue_placing_torches
end

function digMine(cmdLine)
	local steps = 0
	local place_torches = not cmdLine.no_torches

	for i = 1, cmdLine.length do
		terrapin.dig()
		terrapin.digDown(0)

		if cmdLine.intelligent_mining then
			terrapin.explore(cmdLine.trash_blocks)
		end
		
		if place_torches and (i % 10 == 0) then
			-- makeAlcove returns false when we have run out of torches
			place_torches = makeAlcove(cmdLine.torch_slots)
		end

		steps = steps + 1
		if #terrapin.getFreeSlots() == 0 then 
			if cmdLine.ender_chest then
				terrapin.turn(2)
				terrapin.place(cmdLine.ender_chest_slot)

				-- empty inventory into slot
				if cmdLine.intelligent_mining then
					terrapin.dropAllExcept( 
						tablex.merge(cmdLine.torch_slots, cmdLine.trash_blocks, true) 
					)
					tablex.foreach(cmdLine.trash_blocks, function(value, key)
						-- leave 1 item in the slot
						terrapin.drop(value, -1)
					end)


				else
					terrapi.dropAllExcept(cmdLine.torch_slots)
				end

				-- pick up the chest again
				terrapin.select(cmdLine.ender_chest_slot)
				terrapin.dig(0)
				terrapin.turn(2)
			else
				-- go dump at the beginning of the mine
				terrapin.turn(2)
				terrapin.forward(steps)

				if place_torches then
					terrapin.drop(1)
				end

				print("Inventory Full -- Press ENTER to dump inventory")
				read()
				terrapin.dropAllExcept(cmdLine.torch_slots .. cmdLine.trash_blocks)

				terrapin.turn(2)
				terrapin.forward(steps)
			end
		end
	end

	-- return to mine entrance
	terrapin.down()
	terrapin.turn(2)

	if cmdLine.intelligent_mining then
		for i = 1, cmdLine.length do
			terrapin.explore(cmdLine.trash_blocks)
			terrapin.dig()
		end
	else
		terrapin.forward(cmdLine.length)
	end
end

local args = { ... }
local usage = [[
Dig a series of mineshafts. Recommended setup is torches, ender chest and intelligent mining enabled.
For a complete description of the options see the documentation.

<mines> (default 1)          How many mines to dig
-d, --direction (default r)  Where to turn to start the next mine
-n, --no-torches             Do not lay torches
-l, --length (default 100)   What length should the mine be
-s, --spacing (default 3)    How far apart should 2 mines be
-e, --ender-chest            Use an enderchest to dump mined inventory
-i, --intelligent-mining     Dump materials into ender chest when overflowing
]]
local cmdLine = lapp(usage, args)

--check fuel level
local required_moves = cmdLine.length * 2 + 2
if not ui.confirmFuel(required_moves) then
	return
end

-- set options

-- Torches can be in slots 1 -> 4, To identify torch slots the turtle just looks for full slots 
-- in that range. Do not put anything but torches in there.
local torch_slots = List({1, 2, 3, 4}):filter(function(el) 
		if terrapin.getItemCount(el) == 0 then 
			return false
		else 
			return true
		end
	end
)

-- Test whether the turtle has torches in its inventory
if next(torch_slots) == nil and not(cmdLine.no_torches) then
	error("Add torches to turtle inventory or specify -n option")
end


if not(cmdLine.no_torches) then 
	local required_torches = math.floor(cmdLine.length / 10) 
	local total_torches = tablex.reduce(function(a, b) return a + b end, torch_slots)

	if (required_torches < total_torches) then
		if not ui.confirm("Not enough torches to completely light up the gallery.\n"
		                  .. required_torches .. " needed, " .. total_torches 
		                  .. " available.\n\n Continue anyway ?"
		    ) then
			return
		end
	end
end

cmdLine.torch_slots = torch_slots

-- The ender-chest, if present should be store in slot 5
if cmdLine.ender_chest then
	if terrapin.getItemCount(5) == 0 then
		error("The ender chest needs to be in slot 5")
	else
		cmdLine.ender_chest_slot = 5
	end
end

-- figure out which slots contain the blocks that don't interest us
if cmdLine.intelligent_mining then
	-- get the trash blocks table
	local trash_blocks = terrapin.getOccupiedSlots()
	
	-- remove torch slots from junk slots
	for i = 1, #cmdLine.torch_slots do
		trash_blocks:pop(cmdLine.torch_slots[i])
	end

	-- remove ender chest slot from junk slots
	if cmdLine.ender_chest_slot then
		trash_blocks:pop(cmdLine.ender_chest_slot)
	end

	if #trash_blocks == 0 then
		io.write("\n\nThe turtle needs to know waht blocks are consider useless.")
		io.write("You must add at least one block type to discard for the program to work\n")
		io.write("Suggestions are : dirt, sand, gavel, smoothstone\n")

		return false
	end

	print(
		"Intelligent mining enabled. Considering blocks in the follwing slots as "
		.. "trash : " .. trash_blocks:join(", ")
	)

	cmdLine.trash_blocks = { unpack(trash_blocks) }
end

-- tell terrapin how to match blocks in explore mode :
-- in this mode the valuable blocks are the ones that don't match the compare
-- function
terrapin.search_for_valuable_blocks = false

-- start main program
if cmdLine.mines > 0 then
	for i = 1, cmdLine.mines do
		io.write("digging mine " .. 1 .. " of " .. cmdLine.mines .. "\n")
		terrapin.digUp()
		digMine(cmdLine)
 		-- terrapin.dropAllExcept({1})

		if i ~= cmdLine.mines then -- on the last mine we don't need to go to the next
			if cmdLine.direction == "r" then
				terrapin.turnLeft()
				terrapin.dig(cmdLine.spacing + 1)
				terrapin.turnLeft()
			elseif cmdLine.direction == "l" then
				terrapin.turnRight()
				terrapin.dig(cmdLine.spacing + 1)
				terrapin.turnRight()
			else
				error(cmdLine.direction .. " is not a valid direction.")
			end
		end
	end
end