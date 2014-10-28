
--[[--
Wait for a redstone signal on the specified side to run the specified
actions.

The action can be simple lua statement or a file to execute if the -f
argument is passed.

@script Rs
]]

local lapp = require 'pl.lapp'
local rsx = require 'rsx'

local args = { ... }
local usage = [[
	-f, --file (string) Execute a file instead of a command

	<side>    (string) The side on which to listen
	<command> (default "") The command to execute if --file is not present
]]

local cmdLine = lapp(usage, args)

if (not cmdLine.file) and (not cmdLine.command) then
	error('Please specify a command or a file to execute.')
end

if not rsx.sides[cmdLine.side] then
	error(cmdLine.side .. ' is not a valid side.')
end

-- Argument parsing ok. We can run the program
while true do
	rsx.listen(cmdLine.side)

	if cmdLine.file then
		error('Running files is not yet implemented.')
	end

	dostring(cmdLine.command)
end

print('Goodbye.')
