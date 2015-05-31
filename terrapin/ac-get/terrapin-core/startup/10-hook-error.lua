

local checkin = require 'checkin.client'

-- override 'error' for better reporting
_safe_error = error
function error (message, level)
	local level = level or 1

	-- If the checkin module is loaded and active
	if checkin and #checkin.task_stack > 1 then
		checkin.error('ERROR : ' .. message)
	end

	_safe_error(message, level + 1)
end
