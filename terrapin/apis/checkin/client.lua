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
		["status"] = status,
		["progress"] = progress,
		["task"]   = checkin.currentTask(),
	})
end

--- Ping the daemon to check whether it is up or not
function checkin.ping()
	os.queueEvent("checkin_ping")
	local timer_id = os.startTimer(0.5)

	while true do
		local event = os.pullEvent()

		-- If the checkin daemon is running then it should answer with a
		-- checkin_pong event
		if event == "checkin_pong" then
			return true
		elseif  event == "timer" then
			return false
		end
	end
end

--- Return the current task.
function checkin.currentTask()
	return checkin.task_stack[#checkin.task_stack]
end

--- Start a new task.
-- 	This pushes a new task to the task stack and send a checkin mesage indicating
-- 	that a new task has started.
--
-- 	@param task_name The name of the new task
-- 	@param task_data Any additional data that might be useful to understand the
-- 		behaviour of the program. This will be serialized with
--		textutils.serialize
function checkin.startTask(task_name, task_data)
	checkin._pushTask(task_name)
	local checkin_message = string.format(
		'Starting task %s. Task Data : %s', task_name, textutils.serialize(task_data)
	)
	checkin.checkin(checkin_message)
end

---	End a task
--	This should be called when your program exits. It will send a last checkin
--	message to inform the server that it is finished.
function checkin.endTask()
	local task = checkin.currentTask()

	checkin.checkin('Ending task ' .. task)
end

--- Push a new task to the task stack
--	@local
function checkin._pushTask(task_name)
	checkin.task_stack:append(task_name)
end

--- Remove the topmost task from the task stack.
-- 	@local
function checkin._popTask()
	if #checkin.task_stack > 1 then
		checkin.task_stack:pop()
	else
		error("Cannot remove the last item from the task stack.")
	end

	return checkin.currentTask()
end

return checkin
