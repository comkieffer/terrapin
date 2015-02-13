
--[[--
Update the current installation.

First we download the new installer and configuration then we run them
(So Smart !!)

accepts an --all option if you want to do a full update (you want to run
update-all instead of update)

@script Update
]]

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


io.write("Downloading new version of installer ... ")
saveFile("http://www.comkieffer.com/terrapin_2.0/install.lua", "/install")
io.write("Done.\n")

io.write("Downloading new version of installer_cfg ... ")
saveFile("http://www.comkieffer.com/terrapin_2.0/installer_cfg.lua", "/installer_cfg.lua")
io.write("Done.\n")

local args = { ... }
local options = parseCommandLine(args)

if options["--all"] then
	shell.run("/install", "install", "--force")
else
	shell.run("/install", "update")
end
