
local stringx = require "sanelight.stringx"

local terrapin = require "terrapin"
local isOre    = require "isore"
local checkin  = require "checkin.client"

local valuable_blocks_dug = 0

local function explore_and_count_dug()
	local blocks_dug = terrapin.startExplore(isOre)

	if blocks_dug > 0 then
		checkin.checkin('Found mineral vein. Dug ' .. blocks_dug .. 'blocks.')
		valuable_blocks_dug = valuable_blocks_dug + blocks_dug

		if valuable_blocks_dug % 10 == 0 then
			checkin.checkin('Found '.. valuable_blocks_dug ..'valuable ores so far ...')
		end
	end
end

checkin.startTask('digVein')
explore_and_count_dug()

local mined = isOre.getMined()

if #mined > 0 then
	print "Ores in vein: "
	for k = 1, math.min(5, #mined) do
		print(('%3i - %s'):format(mined[k].count, mined[k].name))
	end
end

checkin.checkin('DigVein found '.. valuable_blocks_dug ..'valuable ore blocks.')
checkin.endTask()