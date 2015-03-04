
local autorun = {}

function autorun.run(log_fn)
	log_fn("Starting autoruns ...")

	if fs.isDir("/autorun") then
		local files = autorun.getSortedAutoruns()

		for k = 1, #files do
			local file = fs.combine('/autorun', files[k])

			log('Running ' .. file)

			local file_fn, err = loadfile(file)
			if not file_fn then
				log(('Unable to open %s. Error: %s'):format(file, err))
				error(err)
			end

			-- Pass the environment into it so that it can access the shell API
			init_fn = setfenv(file_fn, getfenv())

			local status, err = pcall( file_fn )
			if not status then
				log(
					('An error occurred whilst running %s. Error: %s')
					:format(file, err)
				)
				error(err)
			end
		end
	end

	log_fn('All autorun completed')
end

function autorun.getSortedAutoruns()
	local files = table.sort( fs.list('/autorun') )
	return files or {}
end

return autorun
