
--[[--
Install the terrapin evironment from scratch.

This file is meant to be hosted on pastebin and run. It will download the
installer and configuration file and save them to the root of the
computer/turtle before running them.

@script Bootstrap
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

io.write("Downloading new version of installer ... ")
saveFile("http://www.comkieffer.com/terrapin_2.0/install.lua", "/install")
io.write("Done.\n")

io.write("Downloading new version of installer_cfg ... ")
saveFile("http://www.comkieffer.com/terrapin_2.0/installer_cfg.lua", "/installer_cfg.lua")
io.write("Done.\n")

shell.run("/install", "install", "--force")
