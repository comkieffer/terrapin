
local function saveFile(path_on_server, path_on_client)
	local server_file = assert(
		http.get(path_on_server), 
		"failed to download file " .. path_on_server, 2
	)
	local client_file = assert(
		fs.open(path_on_client, "w"), 
		"failed to open file " .. path_on_client, 2
	)

	client_file.write( server_file.readAll() )
	client_file.close()
end

local function parseCommandLine(args)
	local options = {}
	for idx, arg in ipairs(args) do
		options[arg] = true
	end

	return options
end


io.write("Downloading new version of insaller ... ")
saveFile("http://www.comkieffer.com/terrapin/install.lua", "/install")
io.write("Done.\n")

if options["--all"] then
	shell.run("/install", "install", "--force")
else
	shell.run("/install", "update")
end


