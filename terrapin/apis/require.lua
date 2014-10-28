
--[[--
An implementation of require for ComputerCraft.

Once the file has been loaded you will be able to require modules.

The current search path only considers terrapin libraries. Future versions
will acknowledge that some people might want to write their own libraries
and provide a sane set of loaders.

The current search path is :
	/terrapin/apis

@module require
@usage dofile('require.lua')
]]

local function str_split(str, delimiter)
	if not str then error("Missing paramter 1", 2) end
	if not delimiter then error("Missing paramter 2", 2) end

	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( str, delimiter, from  )

	while delim_from do
		table.insert( result, string.sub( str, from , delim_to-1 ) )

		from  = delim_to + 1
		delim_from, delim_to = string.find( str, delimiter, from  )
	end

	table.insert( result, string.sub( str, from  ) )
	return result
end


local loaded_modules = {}
local module_finders = {
	["Default API Finder"] = function(module_name)
		local file_tokens = str_split(module_name, "%.")
		local module_path = "/terrapin/apis"

		for _, file_token in ipairs(file_tokens) do
			-- print ("file token : " .. file_token)
			module_path = fs.combine(module_path, file_token)
		end
		module_path = module_path .. ".lua"


		if fs.exists(module_path) then
			return module_path
		else
			error("Could not locate module : " .. module_path .. ". ABORTING")
		end
	end,
}

function require(module_name)
	if loaded_modules[module_name] then
		return loaded_modules[module_name]
	else
		for _, module_finder in pairs(module_finders) do
			local file = module_finder(module_name)
			if file then
				local loaded_module_fn, errors = loadfile(file)
				if not loaded_module_fn then
					error(errors)
				end

				local loaded_module = setfenv(loaded_module_fn, getfenv())()

				loaded_modules[module_name] = loaded_module
				return loaded_module
			end
		end
		error("module not found : " .. module_name)
	end
end
