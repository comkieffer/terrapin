
List = require "pl.list"

if turtle then
	terrapin = require "terrapin"
end

local checkin = {
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
-- This builds the data package and serializes it.
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

function checkin.currentTask()
	return checkin.task_stack[#checkin.task_stack]
end

function checkin.startTask(task_name, task_data)
	checkin.pushTask(task_name)
	checkin.checkin('Starting ' .. task_name .. '. Task Data : ' ..
		textutils.serialize(task_data))
end

function checkin.pushTask(task_name)
	checkin.task_stack:append(task_name)
end

function checkin.popTask()
	if #checkin.task_stack > 1 then
		checkin.task_stack:pop()
	else
		error("Cannot remove the last item from the task stack.")
	end

	return checkin.currentTask()
end


return checkin
