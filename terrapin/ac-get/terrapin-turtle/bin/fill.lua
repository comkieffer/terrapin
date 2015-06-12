
--[[--
Fill all the holes in the specfied area so that the ground is flat.

@script Fill
]]

local lapp      = require 'sanelight.lapp'
local ui        = require "ui"
local terrapin  = require "terrapin"
local checkin   = require "checkin.client"
local Smartslot = require "smartslot"

function mkAfterMove(cmdLine, FillerSlot)
	local total_moves, current_moves = cmdLine.length * cmdLine.width, 0

	local function doCheckin()
		if current_moves % 10 == 0 then
			progress = current_moves/total_moves * 100
			checkin.checkin(
				('Completed %i of %i moves. Progress = %f'):format(
					current_moves, total_moves, progress), progress
			)
		end
	end

	function fill()
		local depth = 1
		current_moves = current_moves + 1

		-- detect the depth we need to fill
		while not terrapin.detectDown() do
			terrapin.down()
			depth = depth + 1
		end

		-- do the filling
		for k = 1, depth - 1 do
			terrapin.up()

			if not (FillerSlot()) then
				error('No more blocks to place')
			end
			terrapin.placeDown()
		end

		print "calling do checkin"
		doCheckin()
	end

	return fill
end

local args = { ... }

--- @usage
local usage = [[
	<width> (number)
	<length> (number)
]]

local cmdLine = lapp(usage, args)

-- we suppose that the fill will be 3 deep, this is only a guideline.
local required_moves = 3 * cmdLine.length * cmdLine.width
if not ui.confirmFuel(required_moves) then
	return
end

-- Make sure that we have enough materials to fill all the holes
local materials = terrapin.getOccupiedSlots()
if #materials == 0 then
	error('No filling materials detected.')
end

local filler_mat = terrapin.getItemDetail(materials[1])
local FillerSlot = Smartslot(filler_mat.name)
print('Using ' .. filler_mat.name .. ' to fill holes.\n')

local required_materials = 3 * cmdLine.length * cmdLine.width
local confirm_msg =
	('Estimating an average hole depth of 3 blocks you will need %i blocks. ' ..
	 'Unfortunately you only have %i filler blocks available. Continue ?')
	:format(required_materials, FillerSlot:count())

if required_materials > FillerSlot:count() and not ui.confirm(confirm_msg) then
	return
end

terrapin.enableInertialNav()
checkin.startTask('Fill', cmdLine)

terrapin.visit(cmdLine.width, cmdLine.length, true, mkAfterMove(cmdLine, FillerSlot))
checkin.checkin('Finished fill. Going back to start position')
terrapin.goToStart()

checkin.endTask()
