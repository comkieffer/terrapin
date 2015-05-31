
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

local config = {}

local function docfg(path)
	local full_path = fs.combine('/cfg', path) .. '.cfg'
	local cfg, err = fs.open(full_path, 'r')
	if not cfg then
		error(('Config: Unable to open %s. Error: %s'):format(full_path, err))
	end

	return textutils.unserialize(cfg.readAll())
end

function config.read(path)
	return docfg(path)
end

return config
