--[[--

Send messages to the checkin daemon on the machine.

This requires the checkin daemon to be running on the machine. See the
documentation for checkin-server for more information

@module checkin-client

]]

List = require "sanelight.List"

local checkin = {
	["task_stack"] = List({ "Idle" }),
}

---	Post a checkin to the daemon.
--	To send an update you must first use checkin.pushTask to push a new task to
-- 	task stack. This allows the checkin message to relay the current task to the
-- 	server.
--
-- 	@param status The status message
-- 	@param progress a number betwwen 0 and 100 representing the progress of the
-- 		current task.
function checkin.checkin(status, progress)
	if #checkin.task_stack == 1 then
		error("Before you can start pushing updates you must start a task.")
	end

	-- log('Sent checkin event with status: ' .. status)
	os.queueEvent("checkin", {
		["type"]     = "checkin",
		["status"]   = status,
		["progress"] = progress,
		["task"]     = checkin.currentTask(),
	})
end

--- Post an info message to the daemon.
-- Unlike checkin info messages are meant to be sent by the OS not programs.
-- It is just a hack around the fact that OS messages are sent when the task
-- stack is just composed of 'Idle'.
--
-- @param message The message to send
function checkin.warning(message)
	os.queueEvent("checkin", {
		["type"]     = "info",
		["status"]   = message,
		["task"]     = 'Terrapin OS',
	})
end

--- Ping the daemon to check whether it is up or not
function checkin.ping()
	os.queueEvent("checkin_status")
	local timer_id = os.startTimer(0.5)

	while true do
		local event, data = os.pullEvent()

		-- If the checkin daemon is running then it should answer with a
		-- checkin_pong event
		if event == "checkin_status_data" then
			return data
		elseif event == "timer" and data == timer_id then
			return false
		end
	end
end

return checkin
