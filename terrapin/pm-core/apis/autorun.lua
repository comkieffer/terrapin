
local autorun = {
	["global-autorun-dir"] = '/autorun',
}

function autorun.run(log_fn)
	log_fn("Starting autoruns ...")


	local files = autorun.getSortedAutoruns()
	log_fn('Found ' .. #files .. ' autoruns')

	for k = 1, #files do
		local file = files[k]

		log_fn('Running ' .. file[2])

		local file_fn, err = loadfile(file[2])
		if not file_fn then
			log_fn(('Unable to open %s. Error: %s'):format(file[2], err))
			error(err)
		end

		-- Pass the environment into it so that it can access the shell API
		init_fn = setfenv(file_fn, getfenv())

		local status, err = pcall( file_fn )
		if not status then
			log_fn(
				('An error occurred whilst running %s. Error: %s')
				:format(file[2], err)
			)
			error(err)
		end
	end

	log_fn('All autoruns completed')
end

--- Fetch all the autorun files from the package directories and the global
-- autorun directory.
--
-- The autoruns for each package are found in $package_path/autorun
--
-- @return An array of tables. Each table contains the filename as the first
-- 	value and the full path the second. This allows us to easily sort the array
--  by priority.
function autorun.getSortedAutoruns()
	local files = {}

	if fs.isDir(autorun["global-autorun-dir"]) then
		local autoruns = fs.list(autorun["global-autorun-dir"])

		for k = 1, #autoruns do
			table.insert(files, {
				autoruns[k],
				fs.combine(autorun["global-autorun-dir"], autoruns[k])
			})
		end
	end

	-- Add all the package specific autoruns to the list
	if fs.isDir('/packages') then
		local packages = fs.list('/packages')

		for k = 1, #packages do
			local package_dir = fs.combine('/packages', packages[k])
			local autorun_dir = fs.combine(package_dir, 'autoruns')

			if fs.isDir(autorun_dir) then
				local autoruns = fs.list(autorun_dir)

				for k = 1, #autoruns do
					table.insert(files,
						{ autoruns[k], fs.combine(autorun_dir, autoruns[k]) }
					)
				end
			end
		end -- endfor packages
	end

	table.sort(files, function(first, second)
		return first[1] < second[1]
	end)

	return files or {}
end

return autorun
