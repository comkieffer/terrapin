
--[[--
An extension of the go tool from standard computercraft.

When started without arguments it will wait for the user to press keys to
move the turtle.

	ARROW : horizontal movement
	U, D  : up, down
	ENTER : exit

It can also execute movement commands from the command line :

	rc f 1

would move the turtle forward once. The full list of commands is :

	f, b, r, l, u, d

@script rc
]]

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
if #args >= 1 then
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
			for i = 1, tonumber(args[2]) do
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
