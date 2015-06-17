
--[[--
Dig mines and excavate all the discovered ores.

The simplest invocation of this smart mining tool will dig a mineshaft 2 blocks high and 1 block high and mine all the ores it finds. An alcove will be
to the right every 10 blocks to house a torch to illuminate the mine. This
makes the light level in the mine high enough to prevent mob spawns.

It can also be used to dig a series of mineshafts. For example to 4 dig new mines every 3 blocks from left to right you would call it as :

	digmine 4

To dig new mines towards the left instead with a spacing of 5 blocks you would
use :

	digmine 4 --direction l --spacing 5

The program decides that anything whose name ends in 'ore' is an ore and should
be mined. Future versions of this script will allow the user to customise the
what the turtle considers an ore.

@script DigMine
]]

local lapp      = require "sanelight.lapp"
local List      = require "sanelight.List"

local ui        = require "ui"
local terrapin  = require "terrapin"
local checkin   = require "checkin.client"
local isOre     = require "isore"
local SmartSlot = require 'smartslot'

-- TODO stop placing torches when they have run out
function makeAlcove(torch_slot)
	local continue_placing_torches = true
	terrapin.turnRight()
	terrapin.dig(0)

	if not torch_slot() then
		checkin.warning('No more torches to place. Will not place any more torches.')
		continue_placing_torches = false
	end

	terrapin.place()
	terrapin.turnLeft()

	return continue_placing_torches
end

local function explore_and_count_dug(cmdLine)
	local blocks_dug = terrapin.startExplore(function(block)
		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end

		return isOre(block)
	end)

	if blocks_dug > 0 then
		checkin.checkin('Found mineral vein. Dug ' .. blocks_dug .. 'blocks.')
		cmdLine.valuable_blocks_dug = cmdLine.valuable_blocks_dug + blocks_dug
	end
end

local function onInventoryFull(cmdLine)
	checkin.checkin("Inventory Full -- Returning to mineshaft Start.")

	-- go dump at the beginning of the mine. We need to make sure that we follow
	-- the mine when going back to the start. This is why we set the order of the
	-- moves to follow 'x' last. This ensures that dig through as few blocks as
	-- possible before moving back into the mine.
	local current_pos = terrapin.getPos()
	terrapin.goToStart({'y', 'z', 'x'})

	-- Try to find a chest in which to dump our shit

	local block = terrapin.inspect()
	if block and block.name:lower():match('chest$') then
		local exclude_slots = cmdLine.torch_slot:slots()
		terrapin.dropAllExcept(exclude_slots)
	else
		print("Inventory Full -- Press ENTER to continue")
		read()
	end

	terrapin.goTo(current_pos, {'x', 'y', 'z'})
end

function digMine(cmdLine)
	local steps = 0
	local place_torches = not cmdLine.no_torches


	function do_checkin()
		local total_steps = 2*cmdLine.length

		if steps % 5 == 0 then
			progress = steps / total_steps * 100
			checkin.checkin(
				('Completed %i of %i moves. Progress = %f')
					:format(steps, total_steps, progress)
				, progress
			)
		end
	end

	for i = 1, cmdLine.length do
		terrapin.dig()
		terrapin.digDown(0)

		if cmdLine.intelligent_mining then
			explore_and_count_dug(cmdLine)
		end

		if place_torches and (i % 10 == 0) then
			-- makeAlcove returns false when we have run out of torches
			place_torches = makeAlcove(cmdLine.torch_slot)
		end

		steps = steps + 1
		do_checkin()

		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end
	end

	-- return to mine entrance
	terrapin.down()
	terrapin.turn(2)

	if cmdLine.intelligent_mining then
		if cmdLine.intelligent_mining then
			explore_and_count_dug(cmdLine)
		end

		steps = steps + 1
		do_checkin()

		if #terrapin.getFreeSlots() == 0 then
			onInventoryFull()
		end
	end
end

local args = { ... }

---  @usage
local usage = [[
Dig a series of mineshafts. Recommended setup is torches, ender chest and intelligent mining enabled.
For a complete description of the options see the documentation.

-n, --no-torches             Do not lay torches
-l, --length (default 100)   What length should the mine be
-i, --intelligent-mining     Dump materials into ender chest when overflowing
]]
local cmdLine = lapp(usage, args)
cmdLine.valuable_blocks_dug = 0

--check fuel level
local required_moves = cmdLine.length * 2 + 2
if not ui.confirmFuel(required_moves) then
	return
end

terrapin.enableInertialNav()
checkin.startTask('DigMine', cmdLine)

-- set options

-- Torches can be in slots 1 -> 4, To identify torch slots the turtle just looks for full slots
-- in that range. Do not put anything but torches in there.
local torch_slot = SmartSlot('torch$')

if not(cmdLine.no_torches) then
	local required_torches = math.floor(cmdLine.length / 10)
	local total_torches = torch_slot:count()

	if (required_torches > total_torches) then
		if not ui.confirm("Not enough torches to completely light up the gallery.\n"
		                  .. required_torches .. " needed, " .. total_torches
		                  .. " available.\n\n Continue anyway ?"
		    ) then
			return
		end
	end
end

-- We add the torch_slot to the command line object so that we can pass it
-- around easily.
cmdLine.torch_slot = torch_slot

terrapin.digUp()
digMine(cmdLine)
local mined = isOre.getMined()

if #mined > 0 then
	print "Ores in vein: "
	for k = 1, math.min(5, #mined) do
		print(('%3i - %s'):format(mined[k].count, mined[k].name))
	end
end


if cmdLine.intelligent_mining then
	checkin.checkin('DigMine : Finished -- excavated ' ..
		cmdLine.valuable_blocks_dug .. ' blocks')
end

checkin.endTask()
