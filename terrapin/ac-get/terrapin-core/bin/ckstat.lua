
--[[--

Display some information about the checkin system.

This is a useful tool to understand if the checkin system is running and how
healthy it is.

@script Ckstat
]]--

local checkin = require 'checkin.client'
local stringx = require 'sanelight.stringx'

local screen =[[
+------------------------------------+
|  Checkin Status:                   |
|                                    |
|    Configuration Status: %s  |
|    Connection Status:    %s  |
|    Sent Messages:        %s  |
|    Failed Messages:      %s  |
|                                    |
|    Current Task:         %s  |
|                                    |
|              Press Any Key to Exit |
+------------------------------------+]]



local function busy_wait()
	local event = os.pullEvent('key')
end


term.clear()
term.setCursorPos(1, 1)

local status = checkin.status()
for k,v in pairs(status) do status[k] = tostring(v) end

print(screen:format(
	stringx.rjust(status['is_configuration_ok'] and 'OK' or 'FAIL', 8),
	stringx.rjust(status['is_server_available'] and 'OK' or 'FAIL', 8),
	stringx.rjust(status['sent_messages'], 8),
	stringx.rjust(status['failed_messages'], 8),
	stringx.rjust(status['current_task'], 8)
))
busy_wait()
