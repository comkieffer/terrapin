
-- Clear the existsing log
local f = assert( fs.open('/startup_log.txt', 'w') )
f.close()

local function log(string)
	local logfile = fs.open('/startup_log.txt', 'a')
	logfile.write(
		('day %d @ %s - %s\n')
		:format(os.day(), textutils.formatTime(os.time(), true), string)
	)
	logfile.close()
end

-- load require API to allow ondemand loading of APIs
-- This should be the ony time that an exlicit path to an API fil is needed.
-- require should find your APIs automgically afterwards.
dofile("/packages/pm-core/apis/require.lua")
log("Loaded require API")

local autorun = require "autorun"
autorun.run(log)

log("Startup completed")
