

-- Make aliases for all the files in the folder specified by path
-- The function looks for all the lua files in the folder and generates a
-- alias without the '.lua' at the end and a lower case version of the name
--
-- eg:
-- 	consider a directory /bin/ containing someExecutable.lua
--  This executable will be available as someExecutable and someexecutable
--


function _make_aliases(path)
	if fs.isDir(path) then
		local programs = fs.list(path)

		for _, program in ipairs(programs) do
			local full_name = fs.combine(path, program)
			if not fs.isDir(full_name) and string.find(program, ".lua$") then
				local alias = program:sub(1, -5)

				shell.setAlias(alias, full_name)
				shell.setAlias(alias:lower(), full_name)
				log("added alias: " .. alias .. " (" .. alias:lower() .. ") for: " .. full_name)
			end
		end
	end -- endif isDir
end

-- Make aliases for all the programs. We iterate through all the installed
-- packages to add their bin paths to the list of paths for which to generate
-- aliases
local bin_paths = {}

if fs.isDir('/packages') then
	local packages = fs.list('/packages')

	log('Found ' .. #packages .. ' program folders.')
	for k = 1, #packages do
		local bin_path = fs.combine(
			fs.combine('/packages', packages[k]), 'programs')
		table.insert(bin_paths, bin_path)
	end
end

local env = getfenv()
local file = fs.open('make_aliases_env.txt', 'w')

file.write('env = {\n')
for k,v in pairs(env) do
	file.write(('  ["%s"] = %s,\n'):format(k, tostring(v)))
end
file.write('}')
file.close()

for k = 1, #bin_paths do
	log('Processing aliases for "' .. bin_paths[k] .. '" ... ')
	_make_aliases(bin_paths[k])
end
