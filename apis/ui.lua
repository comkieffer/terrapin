
--- A set of helper functions for common ui tasks 
-- @module ui

local ui = {}

--- Print a msg on the screen and ask for the user confirm or stop the operation.
-- @param msg the message that will be shown to the user
-- @return true or false according to the user's decision
function ui.confirm(msg)
	io.write(msg .. "(y/n) ")
	local res = io.read()

	if not (res == "y" or res == "Y") then
		return false
	else
		return true
	end
end

--- Draw a simple progress bar ([=====>    ])
-- @param start the initial value
-- @param last the target value
-- @param current the current value
-- @length the length the generated string should be
-- @return the string containing the generated element
function ui.progress(start, last, current, length)
	local str = "["
	local progress = current / (last - start)

	length = length - 2 -- remove the beginning and [ from the length
	for i in 1, math.floor(length / progress) - 1 do 
		str = str .. "="
	end

	str = str .. ">"

	for i = math.floor(length / progress), length do
		str = str .. " "
	end

	str = str .. "]"

	return str
end

if turtle then
	local terrapin = require "terrapin"
	
	--- A special case of ui.confirm. 
	-- Given an amount of moves that will be performed by the scrippt, check that the 
	-- remaining fuel is sufficient.
	--
	-- @param requiredMoves The amopunt of moves necessary to complete the script
	-- @return true if the user wishes to continue even though the turtle has insuficient fuel.
	function ui.confirmFuel(requiredMoves)
		if terrapin.getFuelLevel() < requiredMoves then
			return ui.confirm("Insuficient fuel to complete operation\nContinue Anyway ? ")
		else
			return true
		end
	end
end

return ui
