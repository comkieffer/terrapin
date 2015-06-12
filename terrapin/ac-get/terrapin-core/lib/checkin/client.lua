--[[--

Send messages to the checkin daemon on the machine.

This requires the checkin daemon to be running on the machine. See the
documentation for checkin-server for more information. To see if the server is
running you can use the `ckstat` program.

## Introduction:

To start using the checkin API to make your programs report their progress you
first need to create an account on [TerrapinWeb](#). The website acts as a
central hub for checkin messages and provides a simple interface to view the
status of your computers and turtles. If you'd rather host the service on your
own check out the readme in `terrapin/terrapin_web` for instructions.

Once you have an account you need to tell the server about your world. Click on
the 'Create New World' button in the sidebar. Now you need to load the world
specfic configuration on the server. If you have created a world you should see
a button in the top right labelled: 'Generate Configuration'. If you click on it
the server will generate it.

You now need to get the configuration onto your computer. In minecraft open up
the computer and type `fetch-cfg` followed by the configuration code provided
by the server. Once the program has finished running restart the computer. On
startup it will start sending checkins. If you reaload the world page on the
website you should see your computer. If you don't see it run `ckstat` to ensure
that the checkin daemon is running properly.

## Developping

To use checkins in your programs you simply need to include that api:

	local checkin = require "checkin.client"

Before you can start sending messages you will need to start a task:

	checkin.startTask('task-name')

Remember to finsih it before exiting the script:

	checkin.endTask()

This allows the server to know what your computers are doing and disply nice
statistics.

When you do something worth reporting in your program simply call:

	checkin.checkin('I did something !')

to tell the server. You can also tell it how far along you are by adding a
progress value. Progress should be expressed as a percentage (ie. a number
between 0 and 100).

	checkin.checkin('Halfway there !', 50)

The daemon will send a checkin on it's own if it has been 1 minute since the
last message you sent. This allows the server to know if the computer is still
alive. It is best practive to make sure that you are sending a checkin manually
more tha once a minute.

If something unexpected happens you can use `checkin.warning' to send a message.
Messages sent with 'checkin.warning' will be more visible on the computer page
and if you have enabled the push bullet integration they will trigger a
notification.

@module checkin-client
]]

local List   = require "sanelight.List"
local utils  = require "sanelight.utils"
local tablex = require "sanelight.tablex"

local checkin = {}

--- Start a task.
--
-- The daemon will only accept checkin messages if there is a running task. If
-- you attempt to call checkin.checkin() without having first pushed a task to
-- stack with checkin.startTask an error will be thrown.
--
-- @param task The name of the task
-- @param task_data Any additional data you want to send to the server
function checkin.startTask(task, task_data)
	os.queueEvent('checkin:task_start', task, task_data)

	if not utils.pullEvent('checkin:task_started', 2) then
		error('Unable to start task: Checkin daemon timed out.')
	end
end

--- End a task
--
-- Tell the daemon that you have finished the current task. Sending this message
-- allows the server to calculate detailed statistics about your computer.
function checkin.endTask()
	os.queueEvent('checkin:task_end')

	if not utils.pullEvent('checkin:task_ended', 2) then
		error('Unable to end task: Checkin daemon timed out.')
	end
end

---	Post a checkin to the daemon.
--
-- To send an update you must first use checkin.pushTask to push a new task to
-- task stack. This allows the checkin message to relay the current task to the
-- server.
--
-- 	@param status   The status message
-- 	@param progress A number betwwen 0 and 100 representing the progress of the
--   current task.
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
--
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
--
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
-- @param safe Whether to wait for confirmation or not. Log messages are not
--  important. Generally we want the logging system to take up as few ressources
--  as possible. Waiting for confirmation every time might slow down the program
--  to unacceptable levels.
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
