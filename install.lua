
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

	local logfile = assert(fs.open("install_log.txt", "w"))
	logfile.write("Saving " .. path_on_server .. " to " .. path_on_client)
	logfile.close()
end

local function uninstallSection(section_name, section)
	io.write("Uninstalling " .. section_name)
	local dir = section["destination directory"]
	deleteDirectory(dir)

	print()
end

local function installSection(section_name, section)
	local files = section["files"]
	local _, term_y = term.getCursorPos()
	local _, term_width = term.getSize()

	io.write("Installing " .. section_name)

	for idx, file in ipairs(file) do
		local source_file = fs.combine(section["source directory"], file)
		local dest_file   = fs.combine(section["destination directory"], file)

		saveFile(source_file, dest_file)
		term.setCursorPos(term_y, width - 5)
		io.write("     ")
		term.setCursorPos(term_y, width - 5)
		io.write(idx .. "/" .. #files)
	end
end

local function deleteDirectory(dir)
	if fs.exists(dir) then
		fs.delete(dir)
	end
end	

local function parseCommandLineArgs( args )
	local options
	for idx, arg in ipairs(args) do
		options[arg] = true
	end

	return options
end

-- Start main Program

local options = parseCommandLineArgs( ... )
local uninstall_successful = true

-- check that the configuration file exists. Without this file the installer is useless
if not( fs.exists("installer_cfg.lua") ) then
	error("The installer needs an installer_cfg.lua file to continue.")
end

-- load the configuration file 
local configFn, errors = loadfile("installer_cfg.lua")
if not configFn then
	error("Could not open installer_cfg.lua. " .. errors)
end
local installer_cfg = setfenv(configFn, getfenv())()

-- check the mode for the installer. At least one option from 
-- install, update-all or update must be present
if not(options["install"]) and not(options["update"]) and not(options["update-all"]) then
	options["install"] = true
end
 
-- check for traces of previous installations :
if fs.exists(installer_cfg["base install directory"]) then
	-- If we are in install mode then delete all the files.
	-- we will overrite them anyway
	if options["install"] or options["update all"] then
		-- Warn the use that we are about to uninstall the apis. 
		if not(options["yes"]) then
			io.write("A previous installation of terrapin was detected. All " ..
				"content in the " .. installer_cfg["base install directory"]   ..
				"will be removed. Continue ? (y/n)"
			)

			local res = io.read()

			if not (res == "y" or res == "Y") then
				io.write("\n\n Exiting installer ...\n")
				return
			end
		end

		-- If we are still here the user is Ok with /terrapin disappearing
		deleteDirectory(installer_cfg["base install directory"])
	else if options["update"] then
		for section_name, section in pairs(installer_cfg["sections"]) do
			if section["update always"] then
				uninstallSection(section_name, section)
			end
		end
	else
		error("No installer mode option present")
	end
end

-- Now we can proceed witht the installation. 
if options["install"] or options["update-all"] then
	for section_name, section in pairs(installer_cfg["sections"]) do
		installSection(section_name)
	end
else if options["update"] then 
	for section_name, section in pairs(installer_cfg["sections"]) do
		if section["update always"] then
			installSection(section_name, section)
		end
	end
else
	error("no installer option mode present")
end

if not uninstall_successful then
	print("The installer detected that some files were added to the terraopin directories. " ..
		  "These files have been left in place.")
end

print "\n\nInstall Succesful"
