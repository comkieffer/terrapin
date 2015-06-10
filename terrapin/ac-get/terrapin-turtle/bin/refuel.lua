
--[[--
Pull fuel from the specified slot.

@script Refuel
]]

local lapp     = require "sanelight.lapp"
local terrapin = require "terrapin"
local checkin  = require "checkin.client"

local args, usage = { ... }, [[
Refuel the turtle from the inventory
<fuel-slot> (default 1) the slot to pull fuel from
]]
local cmdLine = lapp(usage, args)

checkin.startTask('refuel', cmdLine)

local initial_fuel_level = terrapin.getFuelLevel()
io.write("Current fuel level : " .. initial_fuel_level .."\n")

local fuel_count = terrapin.getItemCount(cmdLine.fuel_slot)
terrapin.select(cmdLine.fuel_slot)

if fuel_count == 0 then
	io.write("No fuel in slot " .. cmdLine.fuel_slot .. "\n")
	return
else
	io.write("pulling " .. fuel_count .. " from slot " .. cmdLine.fuel_slot .. "\n")
	turtle.refuel(fuel_count)
end

if terrapin.getFuelLevel() == initial_fuel_level then
	error("Item in slot " .. cmdLine.fuel_slot .. " is not a fuel")
else
	local current_fuel = turtle.getFuelLevel()
	checkin.checkin(('Pulled %i units of fuel from slot %i'):format(
		current_fuel - initial_fuel_level, cmdLine.fuel_slot))
	io.write("Fuel after refueling : " .. current_fuel .. "\n")
end

checkin.endTask()
