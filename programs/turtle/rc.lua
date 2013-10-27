
local terrapin = require "terrapin"

keyActionHandlers = {
	[200] = {"forward", terrapin.forward},
	[208] = {"back", terrapin.back},
	[203] = {"left", terrapin.turnLeft},
	[205] = {"right", terrapin.turnRight},
	[28]  = {"exit", function() running = false end} --Enter
}

print "waiting for input ... "

running = true
while running do
	eventType, keyCode = os.pullEvent("key")

	if keyActionHandlers[keyCode] then
		print(keyActionHandlers[keyCode][1])
		keyActionHandlers[keyCode][2]()
	end
end