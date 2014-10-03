
--- Send progress and status updates to an external server
--
-- The checkin module allows you to notify an external web facing server about
-- changes inside your computer/turtle application.
--
-- Messages are passed from the any active program to the background daemon
-- using a special "checkin" event.
-- The minimal setup to send checkin messages requires you add the following
-- snippet to your /startup :
--
-- 	parallel.waitForAny(
--		checkin.daemon,
--		function()
--			shell.run("shell", "/init")
--		end
--	)
--
-- The daemone will immediately checkin with the server. It will checkin again
-- every minute unless it receives another checkin event.
--
-- Before you can send a checkin event you need to start a new task with :
--
-- 	checkin.startTask('task_name', additional_data)
--
-- Where task_name is the name of the task and additional_data is any other data
-- that can be serialized with textutils.serialize that you believe may be
-- useful to understand the behaviour of the program.
--
-- To checkin now you just need to call :
--
--	checkin.checkin('checkin message', progress)
--
-- Where checkin_message is the message to send and checkin is the progress
-- expressed as a number between 1 and 100
--
--
-- There is one major gotcha you should be careful about.
--
-- The checkin client that sends messages to the server and the checkin server
-- are operating in different enironments and have no shared data. Their only
-- communication channel is the event.
-- This means that you cannot expect the server to know anything about the task
-- stack.
--

List = require "pl.list"

if turtle then
	terrapin = require "terrapin"
end

local checkin = {
	--- After how long should new updates be posted automatically
	["interval"] = 60,

	["task_stack"] = List({ "Idle" }),
}

local log_file_name = "/checkin_log.txt"
local function log(string)
	local logfile = assert(fs.open(log_file_name, "a"))
	logfile.write(string .. "\n")
	logfile.close()
end

-- Run the background daemon that actually does the updating.
-- The daemon will post "ping" updates automatically until you kill it.
function checkin.daemon()

	-- clear log file :
	f = fs.open(log_file_name, "w")
	if f then
		f.close()
	end

	log("Daemon Started")

	-- Set the firs timer event to fire almost immediately
	checkin["timer"] = os.startTimer(1)

	while true do
		local event, data = os.pullEvent()

		if event == "checkin" then
			log('Manual Checkin - staus = ' ..data["status"])

			-- checkin with the posted data. Since we have a post in the
			-- timeframe set a new timer. This implicitely discards the new one.
			checkin._post(data)
			checkin["timer"] = os.startTimer(checkin["interval"])

		elseif event == "timer" and data == checkin["timer"] then
			log('Automatic checkin')
			-- We have reached the end of our timer with no checkins. We
			-- perform the default checkin
			checkin._post({["status"] = "ping"})
			checkin["timer"] = os.startTimer(checkin["interval"])
		end
	end

	log('Exiting daemon')
end

-- Post the data to the server.
--
-- You should never have a reason to call this method directly. It builds the
-- data package and serializes it.
--
-- If the caller is a computer then only its name, id, task, status and progress
-- will be posted. If it is a turtle then its current fuel level will be posted.
-- If the inertial navigation fucntionality of the terrapin module is enabled
-- then the relative position will be posted too.
--
function checkin._post(data)
	local package = {
		["turtle_id"]   = os.getComputerID(),
		["turtle_name"] = os.getComputerLabel() or "N/A",
		["status"]      = data["status"] or "",
		["task"]        = data["task"] or "Idle",
		["progress"]    = data["progress"] or "",
	}

	if turtle then
		package["fuel"] = turtle.getFuelLevel()

		if terrapin.inertial_nav.enabled then
			local pos = terrapin.getPos()
			package["rel_pos_x"] = pos.x
			package["rel_pos_z"] = pos.z
			package["rel_pos_y"] = pos.y
		end
	end

	-- log('\tData : ' .. textutils.serialize(data))
	-- log('\tPackage : ' .. textutils.serialize(package))

	local post_data = ""
	for key, value in pairs(package) do
		post_data = post_data .. "&" .. key .. "=" .. value
	end

	-- strip the first & from the string
	post_data = post_data:sub(2)

	http.post('http://localhost:8100/checkin', post_data)
end

-- 	Post a checkin to the daemon.
--	To send an update you must first use checkin.pushTask to push a new task to
-- 	task stack. This allows the checkin message to relay the current task to the
-- 	server.
--
-- @param status The status message
-- @param progress a number betwwen 0 and 100 representing the progress of the
-- 		current task.
function checkin.checkin(status, progress)
	if #checkin.task_stack == 1 then
		error("Before you can start pushing updates you must start a task.")
	end

	os.queueEvent("checkin", {
		["status"] = status,
		["progress"] = progress,
		["task"]   = checkin.currentTask(),
	})
end

--- Return the current task.
function checkin.currentTask()
	return checkin.task_stack[#checkin.task_stack]
end

--- Start a new task.
-- This pushes a new task to the task stack and send a checkin mesage indicating
-- that a new task has started.
--
-- @param task_name The name of the new task
-- @param task_data Any additional data that might be useful to understand the
-- 		behaviour of the program. This will be serialized with
--		textutils.serialize
function checkin.startTask(task_name, task_data)
	checkin.pushTask(task_name)
	checkin.checkin('Starting ' .. task_name .. '. Task Data : ' ..
		textutils.serialize(task_data))
end

--- Push a new task to the task stack
function checkin.pushTask(task_name)
	checkin.task_stack:append(task_name)
end

--- Remove the topmost task from the task stack.
-- This should be called when your programs exits.
function checkin.popTask()
	if #checkin.task_stack > 1 then
		checkin.task_stack:pop()
	else
		error("Cannot remove the last item from the task stack.")
	end

	return checkin.currentTask()
end


return checkin
