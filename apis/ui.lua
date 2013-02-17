
ui = {}

function ui.confirm(msg)
	io.write(msg .. "(y/n) ")
	local res = io.read()

	if not (res == "y" or res == "Y") then
		return false
	else
		return true
	end
end

if turtle then
	function ui.confirmFuel(requiredMoves)
		if terrapin.getFuelLevel() < requiredMoves then
			return ui.confirm("Insuficient fuel to complete operation\nContinue Anyway ? ")
		else
			return true
		end
	end
end