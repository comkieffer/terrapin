
--[[

The checkin system allows us to send messages to a remote server. It only seems
logical to automatically forward error messages as well.

This script replaces the standard error function with a function that sends the
error message to the server before calling the old error function.

@module Startup
]]--


local checkin = require 'checkin.client'

-- override 'error' for better reporting
_safe_error = error
function error (message, level)
	local level = level or 1

	-- If the checkin module is loaded and active
	-- Note we directly push an event instead of using a builtin client method
	-- so as not to expose an interface to users.
	os.queueEvent('checkin:error', message or '')

	_safe_error(message, level + 1)
end
