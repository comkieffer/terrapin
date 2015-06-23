
--[[--
A simple log utility.

Create a new logger with :
	local Log = require 'log'

	local logger = Log('logfile.txt')
	logger:log('This is a log message')

The file will be created automatically and closed after each call to log()

@classmod Log
]]

Map   = require 'sanelight.map'
class = require 'sanelight.class'
utils = require 'sanelight.utils'

class.Logger()


--- Create the Logger instance
--
-- If file name is specified then a file sink will be added to the logger.
-- Otherwise no sinks are added and logged messages wil be lost. To add a sink
-- just call:
--
--	local logger = Log()
--	logger:addSink(function(line) ... end)
--
-- @param file_name The name of the target file
function Logger:_init(file_name)
	self._sinks = {}
	self._levels = Map{
		["DEBUG"]    = 10,
		["INFO"]     = 20,
		["WARNING"]  = 30,
		["ERROR"]    = 40,
	}

	self.level = 'WARNING'

	if file_name then
    	utils.assert_string(1, file_name)
		self:addFileSink(file_name)
	end
end

--[[
			CONFIGURE SINKS
]]--

--- Add a sink to the logger.
--
-- Sinks are functions that the logger uses to write the log messages. Common
-- sinks are files and checkins. If no checkins have been added the log messages
-- will be lost.
--
-- @param sink_fn A sink function. It should accept 1 parameter: the log item.
function Logger:addSink(sink_fn)
	table.insert(self._sinks, sink_fn)
end

--- Helper function to add a file sink.
--
-- This function creates a sink function that writes log messages to the
-- specified file.
--
-- @param file_name The file that logged intems will be written to
function Logger:addFileSink(file_name)
	local file_name = file_name

	-- Make sure that the file is writable and flush it.
	local f = fs.open(file_name, 'w')
	if not f then error('Unable to open log file ' .. file_name) end
	f.close()

	-- Create the actual sink function
	function log_to_file(message)
		local f = fs.open(file_name, 'a')
		if not f then error('Unable to open log file ' .. file_name) end
		f.write(message .. '\n')
		f.close()
	end

	self:addSink(log_to_file)
end

function Logger:addCheckinSink()
	local checkin = required 'checkin.client'

	function log_to_checkin(message)
		-- Don't checkin debug message to reduce spam
		if self._levels[self.level] > self._level['DEBUG'] then
			checkin.log(message)
		end
	end

	self:addSink()
end

--[[
		ACTUAL LOGGING STUFF
]]--

--- Set the log level
--
-- @param level The log level. Must be one of: ['DEBUG', INFO', 'WARNING',
--  'ERROR'].
function Logger:setLevel(level)
	if not self._levels.get(level) then
		error(('<%s> is not a valid level'):format(level))
	end

	self.level = level
end

--- Get the current log level
--
-- @return The current log level
function Logger:getLevel()
	return self.level, self._levels[self.level]
end


function Logger:do_log(level, message, ...)
	-- Only do anything if the log level is suffcient
	if self._levels[self.level] >= self._levels[level] then
		local message = message:format( ... )
		local log_string = ('day %d @ %s [%s] %s')
			:format(os.day(), textutils.formatTime(os.time(), true), level, message)

		for _, sink in ipairs(self._sinks) do
			sink(log_string)
		end
	end -- endif level
end

function Logger:debug(message, ...)
	self:do_log('DEBUG', message, ...)
end

function Logger:info(message, ...)
	self:do_log('INFO', message, ...)
end

function Logger:warning(message, ...)
	self:do_log('WARNING', message, ...)
end

function Logger:error(message, ...)
	self:do_log('ERROR', message, ...)
end

-- Only present for backwards compatibility
function Logger:log(message, ...)
	self:do_log('INFO', message, ...)
end

return Logger
