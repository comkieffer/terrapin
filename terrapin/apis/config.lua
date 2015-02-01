
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

function config.read(name)
	file_path = fs.combine('/terrapin/config', name .. '.cfg')

	if fs.exists(file_path) and not fs.isDir(file_path) then
		local status, cfg = pcall(dofile, file_path)

		-- If the dofile call fails the error message will be contained in cfg
		if not status then
			error(cfg)
		end

		return cfg
	end

	error('Unable to locate the configuration file: "' .. name ..'" in ' .. file_path)
end

return config
