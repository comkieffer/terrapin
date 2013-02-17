
local args = { ... }
local length

if #args >= 1 then
	length = tonumber(args[1])
else
	error("Missing length param")
end

if not ui.confirmFuel(length * 2) then
	return
end

for i = 1, length do
	terrapin.dig()
	terrapin.digUp(0)
	terrapin.digDown(0)
end

terrapin.turn(2)
terrapin.dig(length)