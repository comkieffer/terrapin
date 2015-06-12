
--[[
Generate aliases for our programs.

Sinc we store out programs locally with their .lua extension we need aliases to
call them. This is the script that does this. It also adds lower case aliases
so that "digMine" can be called as "digmine"

@module Startup
]]--

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
