
-- Generate startup message with computer/turtle information
local computer_id, computer_label = os.getComputerID(), os.getComputerLabel()
local startup_msg = ""

if computer_label then
	startup_msg =
		"+\n" ..
		"| Running Terrapin API Collection v2.0\n" ..
		"| \n" ..
		"| Label : " .. os.getComputerLabel() .. " (Id: " .. os.getComputerID() .. ")\n"

	if turtle then
		startup_msg = startup_msg .. "| Fuel Level : " .. turtle.getFuelLevel() .. "\n"
	end

else
	startup_msg =
		"WARNING : This computer does not have a label. If you break it all " ..
		"files stored in this computer will be destroyed.\n\n## Computer ID: " ..
		computer_id .. '##\n'
end

print("\n" .. startup_msg .. "+\n")
