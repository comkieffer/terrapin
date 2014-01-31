
-- TODO : automatically empty inventory
local lapp     = require "pl.lapp"
local ui       = require "ui"
local terrapin = require "terrapin"

local args = { ... }
local usage = [[
	<width>  (number)
	<length> (number)
	<depth>  (number)
]]

local cmdLine = lapp(usage, args)

local required_moves = cmdLine.width * cmdLine.length * (cmdLine.depth + 1)
if not ui.confirmFuel(required_moves) then
	return
end

terrapin.dig()

for i = 1, cmdLine.width do
	for j = 1, cmdLine.length do
		terrapin.digDown(cmdLine.depth)
		terrapin.digUp(cmdLine.depth)

		if j ~= cmdLine.length then
			terrapin.dig()
		else
			terrapin.turn(2)
			terrapin.forward(cmdLine.length - 1)
			terrapin.dropAll()
			terrapin.turnLeft()
			terrapin.forward()
			terrapin.turnLeft()
		end
	end
end