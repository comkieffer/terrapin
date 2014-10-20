
--[[
	Send a redstone pulse on the secified side every 'delay' seconds

	@script pulse
]]

function usage()
	print "pulse side delay"
	print ""
	print "Pulses the specified side every 'delay' seconds"
end

local args = { ... }

if #args ~= 2 then
	usage()
	return
end

local side = args[1]
local delay = tonumber(args[2])

-- Dump the sides table into a list for easier searching
local valid_sides = List(rs.getSides())

assert(valid_sides.contains(side), "Invalid side : " .. side)
assert(delay > 0, "Invalid delay, must be a positive number")

io.write("Pulsing on side '" .. side .. "' every " .. delay .. " seconds.\n")

while true do
	rsx.pulse(side, 0.5)
	io.write(".")
	sleep(delay)
end
