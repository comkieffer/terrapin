
local terrapin = require "terrapin"
local args = { ... }


keyActionHandlers = {
	[200] = {"forward", terrapin.dig},
	[208] = {"back", terrapin.back},
	[203] = {"left", terrapin.turnLeft},
	[205] = {"right", terrapin.turnRight},
	[22]  = {"up", terrapin.digUp},
	[32]  = {"down", terrapin.digDown},
	[28]  = {"exit", function() running = false end} --Enter
}

print "waiting for input ... "

-- If we have args we just execute them
if #args > 1 then
	if #args == 2 then
		local actions = {
			["f"] = terrapin.dig,
			["b"] = terrapin.back,
			["r"] = terrapin.turnRight,
			["l"] = terrapin.turnLeft,
			["u"] = terrapin.digUp,
			["d"] = terrapin.digDown,
		}

		-- If the action is valid exectute it.
		if actions[ args[1] ] then
			for i = 0, tonumber(args[2]) do
				actions[ args[1] ]()
			end
		end
	else
		error('Malformed Command line')
	end

	return
end

-- Looks like the command line is empty. Go to interactive mode ...
running = true
while running do
	eventType, keyCode = os.pullEvent("key")

	if keyActionHandlers[keyCode] then
		keyActionHandlers[keyCode][2]()
		print(keyActionHandlers[keyCode][1])
	end
end
