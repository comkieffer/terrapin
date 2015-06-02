
function makeAliases(folder)
	log('Making aliases for files in ' .. folder)
	local files = fs.list(folder)

	for _, file in ipairs(files) do
		local full_file = fs.combine(folder, file)

		if fs.isDir(full_file) then
			makeAliases(full_file)
		elseif file:find('.lua$') then
			local alias = file:sub(1, -5)

			shell.setAlias(alias, full_file)
			shell.setAlias(alias:lower(), full_file)
			log(('Added alias %s for %s'):format(alias:lower(), full_file))
		end
	end
end

makeAliases('/bin')
