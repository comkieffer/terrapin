
--[[--
An implementation of require for ComputerCraft.

Once the file has been loaded you will be able to require modules.

The current search path only considers terrapin libraries. Future versions
will acknowledge that some people might want to write their own libraries
and provide a sane set of loaders.

The current search path is :
	/terrapin/apis/
	/apis/

Files not in these directories will not eb picked up.

TODO:  Make sure that it works :
	- Can load apis from /terrapin/apis/
	- Can load apis from /apis/
	- Graciously fails when it can't find an api

@module require
@usage dofile('require.lua')
]]

--- Split the module string into sections
--
-- usage :
-- 	> str_split('test.path')
--		{ 'test', 'path' }
--
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

	--- Load modules from the default search path.
	--
	-- The default search path loads system apis from the '/terrapin/apis/'
	-- directory and user apis from '/apis/'
	--
	-- An API finder can be used to load APIs from anywhere ! It is simply a
	-- function that can translate from the module_name passed into require to
	-- the path of an API file on the local machine.
	--
	-- @param module_name 	The name of the module to locate
	-- @return 2 values : I the module was located then the first return value
	--		is the path to the API file and the second is nil. Otherwise the
	--		first value is nil and the second is the list of paths that where
	--		searched.
	--
	-- example :
	--	> load_api('test.api')
	--
	-- 	If the API file exists :
	-- 	'/terrapin/apis/test/api.lua', nil
	--
	--	If the API file doesn't exist :
	-- 	nil, { '/terrapin/apis/test/api.lua', '/apis/test/apis.lua' }
	--
	["Default API Finder"] = function(module_name)
		local file_tokens = str_split(module_name, "%.")

		local module_paths = {"/terrapin/apis", "/apis/"}
		local search_paths = {}

		for i = 1, #module_paths do
			local module_path = module_paths[i]

			-- build the file path from the file tokens
			for _, file_token in ipairs(file_tokens) do
				module_path = fs.combine(module_path, file_token)
			end
			module_path = module_path .. ".lua"

			if fs.exists(module_path) then
				return module_path, nil
			else
				table.insert(search_paths, module_path)
			end
		end

		-- If we get here then we haven't been able to locate the file
		return nil, search_paths
	end,
}

--- Require and load another module
--
function require(module_name)
	-- If the module is already loaded we don't have to go and look for it
	if loaded_modules[module_name] then
		return loaded_modules[module_name]
	end

	local searched_paths = {}
	for _, module_finder in pairs(module_finders) do
		local file, paths = module_finder(module_name)

		if file then
			local loaded_module_fn, errors = loadfile(file)
			if not loaded_module_fn then
				error(errors)
			end

			local loaded_module = setfenv(loaded_module_fn, getfenv())()
			loaded_modules[module_name] = loaded_module

			return loaded_module
		else
			for _, path in ipairs(paths) do
				table.insert(searched_paths, path)
			end
		end
	end

	-- If we get here then we were unable to find the module.
	local error_msg = [[Require:
		Unable to locate module "%s"
		The following paths were searched :
	]]

	for i = 1, #searched_paths do
		error_msg = error_msg .. '\n    - ' .. searched_paths[i]
	end

	error(error_msg:format(module_name), 2)
end
