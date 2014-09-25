
local usage = [[
Factory control computer

<interval> (number) interval between pulses
<output>   (string) output side
<input>    (string) item counter input side
-r, --reporting-interval (default 60) interval between reports
]]

local args = { ... }
local cmdLine = lapp(usage, args)

if not (rsx.isValidSide(cmdLine.output) and rsx.isValidSide(cmdLine.input) then
	print "\nERROR : Invalid side"
end

local cfg = config.load("factory")
cfg.total_items = cfg.total_items or 0

local item_count = 0

local pulse_timer  = os.startTimer(cmdLine.interval)
local report_timer = os.startTimer(cmdLine.reporting_interval)

io.write("starting factory control system. Press Ctrl to exit\n\n")

while true 
	local event, p1 = os.pullEvent()

	if event == key and p1 == ?? then
		io.write("Shutting down ... \n")
		return
	elseif event == timer then
		if p1 = pulse_timer then
			rsx.pulse(cmdLine.output)
			pulse_timer = os.startTimer(cmdLine.interval)
		elseif p1 = report_timer then 
			-- ignore for the moment
			item_count = 0
			config.save("factory", cfg)
		end
	elseif event = "redstone" then
		-- since cc does not give us a way of detecting on which side the rs event occured 
		-- we just suppose that all rs events are from the item detector
		item_count = item_count + 1
		cfg.total_items = cfg.total_items + 1
	end
do