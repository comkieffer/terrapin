--[[--

Send messages to the checkin daemon on the machine.

This requires the checkin daemon to be running on the machine. See the
documentation for checkin-server for more information

@module checkin-client

]]

local List   = require "sanelight.List"
local utils  = require "sanelight.utils"
local tablex = require "sanelight.tablex"

local checkin = {}

--- Start a task
--
-- The daemon will only accept checkin messages if there is a running task. If
-- you attempt to call checkin.checkin() without having first pushed a task to
-- stack with checkin.startTask an error will be thrown.
--
-- @param task_name The name of the task
-- @param task_data Any additional data you want to send to the server
function checkin.startTask(task, task_data)
	os.queueEvent('checkin:task_start', task, task_data)

	if not utils.pullEvent('checkin:task_started', 2) then
		error('Unable to start task: Checkin daemon timed out.')
	end
end

--- End a task
-- TODO
function checkin.endTask()
	os.queueEvent('checkin:task_end')

	if not utils.pullEvent('checkin:task_ended', 2) then
		error('Unable to end task: Checkin daemon timed out.')
	end
end

---	Post a checkin to the daemon.
--	To send an update you must first use checkin.pushTask to push a new task to
-- 	task stack. This allows the checkin message to relay the current task to the
-- 	server.
--
-- 	@param status The status message
-- 	@param progress a number betwwen 0 and 100 representing the progress of the
-- 		current task.
function checkin.checkin(status, progress)
	utils.assert_arg(1, status, 'string')

	os.queueEvent("checkin:checkin", {
		["status"]   = status,
		["progress"] = progress,
	})

	if not utils.pullEvent('checkin:checkedin', 2) then
		error('Unable to send checkin: Checkin daemon timed out.')
	end
end

--- Post an info message to the daemon.
-- Unlike checkin info messages are meant to be sent by the OS not programs.
-- It is just a hack around the fact that OS messages are sent when the task
-- stack is just composed of 'Idle'.
--
-- @param message The message to send
function checkin.warning(message)
	utils.assert_arg(1, message, 'string')
	os.queueEvent("checkin:warning", message)

	if not utils.pullEvent('checkin:warned', 2) then
		error('Unable to send warning: Checkin daemon timed out.')
	end
end

--- Log something to the server.
-- Unlike checkin messages log items do not report progress. They are meant as
-- way to push logs of the device. By storing them on the server they are easily
-- accessible and do not clutter the storage of the machine
-- Generally you should not call this method directly but instead use the
-- logging subsystem:
--
--		local logger = Logger()
--		logger.addCheckinSink()
--		logger.info('Testing the new log system !')
--
-- @param message The message to send to the server
-- @param sage     Whether to wait for confirmation or not. Log messages are not
--	important. Generally we want the logging system to take up as few ressources
--	as possible. Waiting for confirmation every time might slow down the program
--	to unacceptable levels.
function checkin.log(message, safe)
	utils.assert_arg(1, message, 'string')
	safe = safe or true

	os.queueEvent('checkin:log-item', message)

	-- Only check for the return event if the user absolutely wants it
	if true and not(utils.pullEvent('checkin:logged-item', 2)) then
		error('Unable to send log message: Checkin daemon timed out.')
	end
end

--- Ping the daemon to check whether it is up or not
function checkin.status()
	os.queueEvent("checkin:status")
	local timer_id = os.startTimer(10)

	while true do
		local event, data = os.pullEvent()

		-- If the checkin daemon is running then it should answer with a
		-- checkin_pong event
		if event == "checkin:status_data" then
			return data
		elseif event == "timer" and data == timer_id then
			return nil
		end
	end
end

return checkin
