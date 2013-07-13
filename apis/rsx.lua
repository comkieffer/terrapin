--- Extra functions for easier redstone management.
--
-- @module rsx

rsx = {
	sides = List(rs.getSides())
}

--- Emit a redstone pulse on the specified side
-- Warning : the pulse duration may be too short to register on some redpower machines.
-- Further testing is required.
-- @param side the side on which to output the pulse
function rsx.pulse(side)
	local pulse_length = length or 0.5

	rs.setOutput(side, true)
	sleep(pulse_length)
	rs.setOutput(side, false)
end

--- Wait until the redstone input on the specified side becomes high
-- @param side the side to listen on
function rsx.listen(side)
	while true do
		local rs_event = os.pullEvent("redstone")
		if redstone.getInput(side) then
			return
		end
	end
end

--- When give a string, return true if it is a valid side
-- @side the string to test
-- @return true if the string is a valid side
function rsx.isValidSide(side)
	return rsx.sides.contains(side)
end
