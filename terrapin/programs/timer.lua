
local args = { ... }
local usage = [[
<interval> (number) In seconds
-t, --trigger       In trigger mode the timer will start only when a signal is received on the input input-side
-i, --input-side  (default "left") 
-o, --output-side (default "right")
]]

local cmdLine = lapp(usage, args);

if not rsx.isValidSide(cmdLine.input_side) then
	print(cmdLine.input_side .. " is not a valid side.")
	return
end

if not rsx.isValidSide(cmdLine.output_side) then
	print(cmdLine.output_side .. " is not a valid side")
	return
end

print("Timer : wait " .. cmdLine.interval .. "s")

while true do
	if cmdLine.trigger then
		rsx.listen(cmdLine.input_side)
	end

	sleep(cmdLine.interval)
	rsx.pulse(cmdLine.output_side)
end