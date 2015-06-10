
--[[--
A simple configuration module.

The configuration is simple lua file :

	return {
		["Some Key"] = "Some value",

		...
	}

Configurations should be stored in the /terrapin/config folder.

TODO

@module config
]]

local utils = require 'sanelight.utils'

local config = {}

local function docfg(path)
	utils.assert_string(1, path)

	local full_path = fs.combine('/cfg', path) .. '.cfg'
	local cfg, err = fs.open(full_path, 'r')
	if not cfg then
		error(('Config: Unable to open %s. Error: %s'):format(full_path))
	end

	local config = textutils.unserialize(cfg.readAll())
	if not config then error('Config is malformed.') end

	return config
end

function config.read(path)
	return docfg(path)
end

return config
