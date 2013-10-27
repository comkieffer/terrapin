
local lapp = require "pl.lapp"
local List = require "pl.List"

local ui = require "ui"
local terrapin = require "terrapin"

-- TODO stop placing torches when they have run out
function makeAlcove(torch_slots)
	local continue_placing_torches = true
	terrapin.turnRight()
	terrapin.dig(0)
	

	_, remaining_torches = terrapin.place(torch_slots[1])
	if remaining_torches == 0 then
		torch_slots.pop(1)

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

		if place_torches and (i % 10 == 0) then
			-- makeAlcove returns false when we have run out of torches
			place_torches = makeAlcove(cmdLine.torch_slots)
		end

		if cmdLine.intelligent_mining then
			terrapin.explore(cmdLine.trash_blocks)
		end

		steps = steps + 1
		if #terrapin.getFreeSlots() == 0 then 
			if cmdLine.ender_chest then
				terrapin.turn(2)
				terrapin.place(cmdLine.ender_chest_slot)
				terrapin.dropAllExcept(cmdLine.torch_slots)
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

				terrapin.dropAllExcept({1})

				terrapin.turn(2)
				terrapin.forward(steps)
			end
		end
	end

	-- return to mine entrance
	terrapin.down()
	terrapin.turn(2)
	terrapin.forward(cmdLine.length)
end

local args = { ... }
local usage = [[
Dig a series of mineshafts. Recommended setup is torhes, ender chest and intelligent mining enabled.
For a complete description of the options see the documentation.

<mines> (default 1)
-d, --direction (default right)
-n, --no-torches 
-l, --length (default 100)
-s, --spacing (default 3)
-e, --ender-chest (use an enderchest to dump mined inventory)
-i, --intelligent-mining
]]

local cmdLine = lapp(usage, args)

--check fuel level
local required_moves = cmdLine.length * 2 + 2
if not ui.confirmFuel(required_moves) then
	return
end

-- set options
local torch_slots = List({1, 2, 3, 4}):filter(function(el) 
		if terrapin.getItemCount(el) == 0 then 
			return false
		else 
			return true
		end
	end
)

local required_torches = math.floor(cmdLine.length / 10) 
local total_torches = torch_slots:reduce(function(a, b) return a + b end)

if not(cmdLine.no_torches) and (required_torches > total_torches) then
	if not ui.confirm("Not enough torches to completely light up the gallery.\n"
	                  .. required_torches .. " needed, " .. terrapin.getItemCount(1) 
	                  .. " available.\n\n Continue anyway ?"
	    ) then
		return
	end
end

cmdLine.torch_slots = torch_slots

if cmdLine.ender_chest and terrapin.getItemCount(5) ~= 0 then
	cmdLine.ender_chest_slot = 5
end

if cmdLine.intelligent_mining then
	-- get the trash blocks table
	local trash_blocks = terrapin.getOccupiedSlots()
	
	-- remove torch slots
	for i = 1, #cmdLine.torch_slots do
		trash_blocks:pop(cmdLine.torch_slots[i])
	end

	-- remove ender chest slot
	if cmdLine.ender_chest_slot then
		trash_blocks:pop(cmdLine.ender_chest_slot)
	end

	if #trash_blocks == 0 then
		io.write("\n\nThe turtle needs to know waht blocks are consider useless.")
		io.write("You must add at least one block type to discard for the program to work\n")
		io.write("Suggestions are : dirt, sand, gavel, smoothstone\n")

		return false
	end

	cmdLine.trash_blocks = trash_blocks
end

if cmdLine.intelligent_mining and not cmdLine.ender_chest and not
	ui.confirm("When using intelligent mining using ender chest is recommended. Without it your "
	           .. "turtle might have to return extremely often to the start of the mine rendering "
	           ..  "progress extremely slow.\n\n Continue anyway ?") then
	return false
end


if cmdLine.mines > 0 then
	for i = 1, cmdLine.mines do
		io.write("digging mine " .. 1 .. " of " .. cmdLine.mines .. "\n")
		terrapin.digUp()
		digMine(cmdLine)
 		terrapin.dropAllExcept({1})

		if i ~= cmdLine.mines then -- on the last mine we don't need to go to the next
			if cmdLine.direction == "right" then
				terrapin.turnLeft()
				terrapin.dig(cmdLine.spacing + 1)
				terrapin.turnLeft()
			elseif cmdLine.direction == "left" then
				terrapin.turnRight()
				terrapin.dig(cmdLine.spacing + 1)
				terrapin.turnRight()
			else
				error(cmdLine.direction .. " is not a valid direction.")
			end
		end
	end
end