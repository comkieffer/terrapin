
--[[--

Send progress and status updates to an external server.

The checkin module allows you to notify an external web facing server about
changes inside your computer/turtle application.

Messages are passed from the any active program to the background daemon
using a special "checkin" event.
The minimal setup to send checkin messages requires you add the following
snippet to your /startup :

	checkin = require "checkin.server"
	parallel.waitForAny(
		checkin.daemon,
		function()
			shell.run("shell", "/init")
		end
	)

The daemon will immediately checkin with the server. It will checkin again
every minute unless it receives another checkin event.

Before you can send a checkin event you need to start a new task with :

	checkin = require "checkin.client"
	checkin.startTask('task_name', additional_data)

Where task_name is the name of the task and additional_data is any other data
that can be serialized with textutils.serialize that you believe may be
useful to understand the behaviour of the program.

To checkin now you just need to call :

	checkin.checkin('checkin message', progress)

Where checkin_message is the message to send and checkin is the progress
expressed as a number between 1 and 100

Rememeber to finish your programs with :

	checkin.endTask()

This tels the server that the current task finished without any errors.

There is one major gotcha you should be careful about.

The checkin client that sends messages to the server and the checkin server
are operating in different enironments and have no shared data. Their only
communication channel is the event.
This means that you cannot expect the server to know anything about the task
stack.

@module checkin-server

]]

local List   = require "sanelight.List"
local tablex = require "sanelight.tablex"
local utils  = require "sanelight.utils"

local has_terrapin, terrapin = pcall( require, 'terrapin' )

local checkin = {
	--- After how long should new updates be posted automatically
	["interval"] = 60,

	["sent_messages"] = 0,
	["failed_messages"] = 0,

	-- These variables are used to monitor the connection state
	["configuration_ok"] = false,
	["is_server_available"] = false,
	["was_last_message_successful"] = false,
	["consecutive_failed_messages"] = 0,

	-- These variables are used to monitor the current task
	["task_stack"] = List{ "Idle" },
	["last_message_from_task"] = nil,

	["cfg"] = nil,
	["checkin_cfg_file"] = 'terrapin-checkin',
}

local Logger = require "log"
checkin.logger = Logger('/log/checkin-log.txt')

checkin.message_handlers = {
	--- Start a new task.
	-- 	This pushes a new task to the task stack and send a checkin mesage indicating
	-- 	that a new task has started.
	--
	-- 	@param task_name The name of the new task
	-- 	@param task_data Any additional data that might be useful to understand the
	-- 		behaviour of the program. This will be serialized with
	--		textutils.serialize
	["checkin:task_start"] = function(task_name, task_data)
		utils.assert_arg(1, task_name, 'string')
		task_data = task_data or {}

		checkin.logger:log('Starting new task: ' .. task_name)

		checkin.task_stack:append(task_name)
		local checkin_message = ('Starting task %s. Task Data : %s'):format(
			task_name, textutils.serialize(task_data)
		)

		checkin._post{ ["type"] = "task-start", ["status"] = checkin_message, }
		checkin["timer"] = os.startTimer(checkin["interval"])

		os.queueEvent('checkin:task_started')
	end,

	---	End a task
	--	This should be called when your program exits. It will send a last checkin
	--	message to inform the server that it is finished.
	["checkin:task_end"] = function()
		if tablex.size(checkin.task_stack) <= 1 then
			error('No tasks to remove from stack.', 2)
		end

		local current_task = checkin.task_stack[#checkin.task_stack]
		local checkin_message = ('Ending Task: %s'):format(current_task)

		checkin._post{ ["type"] = "task-end", ["status"] = checkin_message }
		checkin["timer"] = os.startTimer(checkin["interval"])
		checkin.task_stack:pop()

		os.queueEvent('checkin:task_ended')
	end,

	--- Send a checkin message
	-- TODO
	["checkin:checkin"] = function(data)
		utils.assert_arg(1, data, 'table')

		if tablex.size(checkin.task_stack) <= 1 then
			os.queueEvent(
				'checkin:checkin_failed',
				'You cannot push a checkin before adding a task.'
			)
			return
		end

		checkin._post{ ["type"] = "checkin",
			["status"] = data["status"], ["progress"] = data["progress"]}
		checkin["timer"] = os.startTimer(checkin["interval"])

		os.queueEvent('checkin:checkedin')
	end,

	--- Send an error message to the server and clear the task stack.
	--
	-- This is not a general purpose function. only indtended to be called by
	-- the replacement error fuction as a way to send error messages to the
	-- server. If you want to send error messsages from a script use the
	-- checkin.warning function. Unlike checkin.error it will not clear the entire task stack.
	--
	["checkin:error"] = function(error_msg)
		utils.assert_arg(1, error_message, 'string')

		checkin._post{ ["type"] = "error", ["status"] = error_msg }
		checkin["timer"] = os.startTimer(checkin["interval"])

		while #checkin.task_stack > 1 do
			checkin.task_stack:pop()
		end

		os.queueEvent('checkin:errored')
	end,

	["checkin:warning"] = function(warning_msg)
		utils.assert_arg(1, warning_msg, 'string')

		checkin._post{ ["type"] = "warning", ["status"] = warning_msg}
		checkin["timer"] = os.startTimer(checkin["interval"])

		os.queueEvent('checkin:warned')
	end,

	["checkin:log-item"] = function(log_msg)
		utils.assert_arg(1, log_msg, 'string')

		checkin._post{ ["type"] = "log-item", ["status"] = log_msg}
		checkin["timer"] = os.startTimer(checkin["interval"])

		os.queueEvent('checkin:logged-item')
	end,

	["checkin:status"] = function()
		os.queueEvent(checkin.makeStatus())
	end,

	--- If the timer runs out without the daemon receiving a new checkin then
	--  it should send one.
	--
	-- @param data The timer_id
	["timer"] = function(data)
		if data == checkin["timer"] then
			checkin.logger:log('Sending automatic checkin.')

			checkin._post({["type"] = "checkin", ["status"] = "ping"})
			checkin["timer"] = os.startTimer(checkin["interval"])
		end
	end,
}

local checkin_cfg = (require "config").read "terrapin-checkin"
if not checkin_cfg then
	error('Unable to locate configuration file.')
end
checkin = tablex.merge(checkin, checkin_cfg)

-- Discover if this computer is a turtle or not, is it an advanced computer ?
local function getComputerType()
	local computer_type = ""

	if term.isColor() then
		computer_type = "Advanced "
	end

	if turtle then
		computer_type = computer_type .. "Turtle"
	else
		computer_type = computer_type .. "Computer"
	end

	return computer_type
end

function checkin.loadConfig()
	checkin.logger:log('Loading checkin configuration file ...')

	local status, checkin_cfg = pcall(
		(require "config").read, checkin['checkin_cfg_file'])
	if not status then
		checkin.logger:log('An error occurred whilst loading the configuration. Error: ' ..
			checkin_cfg)
	else
		if not(checkin_cfg['World Name'] and checkin_cfg['Checkin URL'] and
			checkin_cfg['API Token']) then

			checkin.logger:log('Malformed configuration file. The checkin functionality ' ..
				'will be disbled.')
		else
			checkin['configuration_ok'] = true
			checkin.cfg = checkin_cfg
		end
	end

end

--- Run the background daemon that actually does the updating.
-- The daemon will post "ping" updates automatically until you kill it.
function checkin.daemon()

	checkin.loadConfig()
	checkin["computer_type"] = getComputerType()

	checkin.logger:log("Daemon Started")
	checkin.logger:log('Is the terrapin api available ? ' .. tostring(has_terrapin))

	-- Set the firs timer event to fire almost immediately
	checkin["timer"] = os.startTimer(1)

	while true do
		local event, data = os.pullEvent()

		-- If the checkin configration is invalid we must drop all non ping packets.
		if checkin.cfg or (event == 'checkin:status') then
			if checkin.message_handlers[event] then
				checkin.message_handlers[event](data)
			end
		end
	end

	checkin.logger:log('Exiting daemon')
end

--- Post the data to the server.
--	@local
--
-- 	You should never have a reason to call this method directly. It builds the
-- 	data package and serializes it.
--
-- 	If the caller is a computer then only its name, id, task, status and progress
-- 	will be posted. If it is a turtle then its current fuel level will be posted.
-- 	If the inertial navigation functionality of the terrapin module is enabled
-- 	then the relative position will be posted too.
--
-- @param data 	A table containing the following keys :
--		["type"]     - "checkin", "warning", "error"
--		["status"]   - The actual message to post to the server
-- 		["progress"] - The current task progress. Only relevant for "checkin"
--		               type messages.
--	All the other data in the checkin can be determined by the server.
--
function checkin._post(data)
	local package = {
		["api_token"]     = checkin.cfg["API Token"],
		["world_name"]    = checkin.cfg["World Name"],

		["world_ticks"]   = os.day()*24000 + (os.time() * 1000 + 18000)%24000,

		["computer_id"]   = os.getComputerID(),
		["computer_name"] = os.getComputerLabel() or "N/A",
		["computer_type"] = checkin["computer_type"],

		["type"]          = data["type"],
		["status"]        = data["status"] or "",
		["progress"]      = data["progress"],
		["task"]          = checkin["task_stack"][#checkin["task_stack"]],
	}

	if has_terrapin then
		package["fuel"]             = turtle.getFuelLevel()
		package["total_blocks_dug"] = terrapin.total_blocks_dug()
		package["total_moves"]      = terrapin.total_moves()

		if terrapin.inertial_nav.enabled then
			local pos = terrapin.getPos()
			package["rel_pos_x"] = pos.x
			package["rel_pos_z"] = pos.z
			package["rel_pos_y"] = pos.y
		end
	end

	local post_data = ""
	for key, value in pairs(package) do
		post_data = post_data .. "&" .. key .. "=" .. tostring(value)
	end

	-- strip the first & from the string
	post_data = post_data:sub(2)
	-- checkin.logger:log('Checkin Payload: ' .. textutils.serialize(package))

	--local h = http.post(checkin["server_url"], post_data)
	local h = http.post(checkin['Checkin URL'], post_data)
	checkin["sent_messages"] = checkin["sent_messages"] + 1

	if h then
		checkin["was_last_message_successful"] = true
		checkin["consecutive_failed_messages"] = 0
		checkin["is_server_available"] = true

	else
		checkin.logger:log(('POST to %s Failed'):format(checkin['Checkin URL']))

		checkin["was_last_message_successful"] = false
		checkin["consecutive_failed_messages"] =
			checkin["consecutive_failed_messages"] + 1
		checkin["failed_messages"] = checkin["failed_messages"] + 1

		if  checkin["consecutive_failed_messages"] > 5 then
			checkin["is_server_available"] = false
		end
	end
end

function checkin.makeStatus()
	return "checkin:status_data", {
		["status"] = 'OK',
		["configuration_ok"]    = checkin["configuration_ok"],
		["is_server_available"] = checkin["is_server_available"],
		["sent_messages"]       = checkin["sent_messages"],
		["failed_messages"]     = checkin["failed_messages"],
		["task_stack"]          = checkin.task_stack,
		["current_task"]        = checkin.task_stack[#checkin.task_stack],
	}
end

return checkin
