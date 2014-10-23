
--[[--
A small utility to test checkin messages.

@usage checkin 'A phrase to send'
@script checkin
]]

local checkin = require 'checkin'

local args = { ... }

if #args == 0 then
	print('Learn to read wanker !')
	return
end

local message = stringx.join(' ', args)
print('Sent : ' .. message)

checkin.startTask('Checkin', message)
checkin.endTask()
