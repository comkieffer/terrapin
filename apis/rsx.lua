
rsx = {
	sides = List(rs.getSides())
}

function rsx.pulse(side)
	rs.setOutput(side, true)
	sleep(0.1)
	rs.setOutput(side, false)
	sleep(0.2)
end

function rsx.isValidSide(side)
	return rsx.sides.contains(side)
end

return rsx