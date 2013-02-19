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
	rs.setOutput(side, true)
	sleep(0.1)
	rs.setOutput(side, false)
	sleep(0.2)
end

--- When give a string, return true if it is a valid side
-- @side the string to test
-- @return true if the string is a valid side
function rsx.isValidSide(side)
	return rsx.sides.contains(side)
end
