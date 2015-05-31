
-- Simple log method
local function log(string)
	local logfile = fs.open('/startup_log.txt', 'a')
	logfile.write(
		('day %d @ %s - %s\n')
		:format(os.day(), textutils.formatTime(os.time(), true), string)
	)
	logfile.close()
end

--- Ping the daemon to check whether it is up or not
function checkin_ping()
	log('Detecting checkin daemon ...')
	os.queueEvent("checkin:status")
	local timer_id = os.startTimer(0.5)

	while true do
		local event = os.pullEvent()

		-- If the checkin daemon is running then it should answer with a
		-- checkin_pong event

		if event == "checkin:status_data" then
			log('Found checkin daemon')
			return true
		elseif  event == "timer" then
			log('checkin daemon unavailable')
			return false
		end
	end
end

function dofile_safe(file, log_fn)
	log_fn('Running ' .. file)

	local file_fn, err = loadfile(file)
	if not file_fn then
		log_fn(('Unable to open %s. Error: %s'):format(file, err))
		error(err)
	end

	-- Pass the environment into it so that it can access the shell API
	local file_env = getfenv()
	file_env["log"] = log_fn

	file_fn = setfenv(file_fn, file_env)

	local status, err = pcall( file_fn )
	if not status then
		log_fn(
			('An error occurred whilst running %s. Error: %s')
			:format(file, err)
		)
		error(err)
	end
end


-- Actual Startup --

-- Make sure that the log file is available and clear it:
f = fs.open('/startup_log.txt', 'w')
f.close()

-- Start the OS.
log('Executing startup ...')

if checkin_ping()  then
	log('Received pong message from checkin daemon. Running /init.')

	-- Remove the CraftOS messages
	term.clear()
	term.setCursorPos(1, 1)

	local startup_dir = '/cfg/startup.d'
	local files = fs.list(startup_dir)
	table.sort(files)

	for _, start in ipairs(files) do
		dofile_safe(fs.combine(startup_dir, start), log)
	end

else
	log('Checkin daemon unavailable. Starting system ...')

	dofile_safe('/lib/require/require.lua', log)
	checkin = require "checkin.server"
	parallel.waitForAny(
		checkin.daemon,

		function()
			os.run({ }, "/rom/programs/shell")
		end
	)

	print("An Unknown Error occurred. Press any key to reboot.")
	read()
	os.reboot()
end