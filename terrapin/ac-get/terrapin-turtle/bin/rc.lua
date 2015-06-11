
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

@script Rc
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

-- If we have args we just execute them
if #args >= 1 then
	local actions = {
		["f"] = terrapin.dig,
		["b"] = terrapin.back,
		["r"] = terrapin.turnRight,
		["l"] = terrapin.turnLeft,
		["u"] = terrapin.digUp,
		["d"] = terrapin.digDown,
	}

	for _, command in ipairs(args) do
		-- If the action is valid exectute it.
		local action, repeats
		if #command == 1 then
			action  = command:sub(1,1)
			repeats = 1
		elseif #command == 2 then
			action  = command:sub(1,1)
			repeats = tonumber(command:sub(2,2))
		else
			error('Malformed command: ' .. command)
		end

		if actions[action] then
			actions[action](repeats)
		else
			error(('"%s" is not a valid action code'):format(action))
		end
	end

	return
end

-- Looks like the command line is empty. Go to interactive mode ...
running = true
print "waiting for input ... "
while running do
	eventType, keyCode = os.pullEvent("key")

	if keyActionHandlers[keyCode] then
		keyActionHandlers[keyCode][2]()
		print(keyActionHandlers[keyCode][1])
	end
end
