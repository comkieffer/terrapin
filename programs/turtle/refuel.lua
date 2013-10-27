
local terrapin = require "terrapin"

local args = { ... }

local fuel_slot = 1

if #args == 1 then
	fuel_slot = tonumber(args[1])	
end

io.write("Current fuel level : " .. turtle.getFuelLevel() .."\n")

local fuel_count = terrapin.getItemCount(fuel_slot)
terrapin.select(fuel_slot)

if fuel_count == 0 then 
	io.write("No fuel in slot " .. fuel_slot .. "\n")
	return
else
	io.write("pulling " .. fuel_count .. " from slot " .. fuel_slot .. "\n")
	turtle.refuel(fuel_count)
end

io.write("Fuel after refueling : " .. turtle.getFuelLevel() .. "\n")  