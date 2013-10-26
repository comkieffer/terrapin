
local function str_split(str)
	local res = {}
	for substr in string.gmatch(str, "(%.)")
		table.insert(res, substr)
	end

	return substr
end

function require(module_name)
	loaded_modules = {}
	module_finders = {
		["Default API Finder"] = function()
			local file_tokens = str_split(module_name)
			local module_path = ""

			for file_token, _ in ipairs(file_tokens) do
				module_path = module_path .. "/" .. file_token
			end

			if fs.exists(module_path) then
				return module_path
			else
				error("Could not locate module : " .. module_name .. ". ABORTING")
			end
		end,
	}
	
	return (function()
		if loaded_modules[module_name] then
			return loaded_modules[module_name]
		else
			for _, finder in pairs(module_finders) do
				local file = finder(module_name) -- Raises an error if the file isn't found
				dofile(file)
			end
		end
	end)()
end