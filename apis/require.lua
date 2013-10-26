function str_split(str, delimiter)
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

function require(module_name)
	local loaded_modules = {}
	local module_finders = {
		["Default API Finder"] = function()
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

	local VERBOSE = true
	
	return (function()
		if loaded_modules[module_name] then
			return loaded_modules[module_name]
		else
			for _, finder in pairs(module_finders) do
				local file = finder(module_name) -- Raises an error if the file isn't found

				if VERBOSE then print("Found require path - " .. file) end

				local moduleFn = loadFile(file)
				return moduleFn()
			end
		end
	end)()
end