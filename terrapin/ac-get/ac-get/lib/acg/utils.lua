function get_url(url)
	logger:debug('utils::get_url', 'Downloading ' .. url)
	local remote = http.get(url)

	if remote == nil then
		logger:error('utils::get_url', 'Error downloading ' .. url)
	end

	return remote
end

function read_lines(fhandle, task, title)
	local i = 1

	local function read_line()
		-- Make the task status be updated
		if task then
			task:update(title, i)
			i = i + 1
		end

		return fhandle.readLine()
	end

	return read_line, fhandle, 0
end

-- Serialisation

local function serializeImpl( t, tTracking )
	local sType = type(t)
	if sType == "table" then
		if tTracking[t] ~= nil then
			error( "Cannot serialize table with recursive entries" )
		end
		tTracking[t] = true

		local result = "{"
		for k,v in pairs(t) do
			result = result..("["..serializeImpl(k, tTracking).."]="..serializeImpl(v, tTracking)..",")
		end
		result = result.."}"
		return result

	elseif sType == "string" then
		return string.format( "%q", t )

	elseif sType == "number" or sType == "boolean" or sType == "nil" then
		return tostring(t)

	else
		error( "Cannot serialize type "..sType )

	end
end

function serialise_table( t )
	local tTracking = {}
	return serializeImpl( t, tTracking )
end


-- Manifest parsing.

function parse_manifest(url, directives)
	local mani = get_url(url)

	assert(mani, "Manifest does not exist")

	for line in read_lines(mani) do
		local idx = line:find(': ')

		if idx then
			local name = line:sub(1, idx - 1)
			local value = line:sub(idx + 2)

			if directives[name] then
				directives[name](value)
			elseif directives.__default then
				directives.__default(name, value)
			end
		end
	end

	mani.close()
end
