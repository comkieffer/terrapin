
--[[--
A simple log utility.

Create a new logger with :
	local log = require 'log'
	local logger = log('logfile.txt')

	logger:log('This is a log message')

The file will be created automatically and closed after each call to log()

@classmod Log

]]

class = require 'sanelight.class'
utils = require 'sanelight.utils'

class.Logger()

function Logger:_init(file_name)
    utils.assert_string(1, file_name)

	self.file_name = file_name
	-- if the file already exists make sure to clear it. Otherwise create it.
	-- Simply clearing it is easier than rotating and since the computers have
	-- limited memory we keep as much of it free as possible.

	f = fs.open(self.file_name, 'w')
	f.close()
end

function Logger:log(message)
	local log_string = ('day %d @ %s - %s\n')
		:format(os.day(), textutils.formatTime(os.time(), true), message)

	f = fs.open(self.file_name, 'a')
	logfile.write(log_string)
	f.close()

	os.queueEvent('terrapin:log_item', log_string)
end

return Logger
