
local terrapin = require "terrapin"

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

running = true
while running do
	eventType, keyCode = os.pullEvent("key")

	if keyActionHandlers[keyCode] then
		keyActionHandlers[keyCode][2]()
		print(keyActionHandlers[keyCode][1])
	end
end
