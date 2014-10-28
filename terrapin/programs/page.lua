
--[[--

@script Page
]]

local lapp  = require 'pl.lapp'
local termx = require 'termx'

-- @usage
local usage = [[
	<file> (string)
]]
local args = { ... }

local cmdLine = lapp(usage, args)

if not (fs.exists(cmdLine.file) and not fs.isDir(cmdLine.file)) then
	error(string.format('"%s" is not a file.', cmdLine.file))
end

local file, err = fs.open(cmdLine.file, 'r')
if not file then
	error(err)
end

termx.page(file.readAll())
file.close()
