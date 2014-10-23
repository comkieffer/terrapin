
--[[--
This program is a generic installer for ComputerCraft. It needs an
installer_cfg.lua configuration file to work properly. This file tells the
installer from where to download the files and where to store them on the
computer.

Command line options are :
	uninstall  The default behaviour is install. Uninstall reverses the
	           actions taken in the install phase.
	           The deault behaviour is install.

	install    Install all the files specified in the installer_cfg.
	           Directories will be created as needed

	update     Reinstall only the sections where ["update always"] is False.
	           Some parts of the package may be stable and not require
	           frequent updates. To make updates faster this allows us to
	           ignore them

	update-all Re-Install all the files. This is equivalent to just using
	           "install".

	--force    Supresses warning messages when updating.


a valid installer_cfg.lua file consists of :

	return {  the table with all the configurations  }

the table should contain a key called ["sections"] that contains a table of sections.
each section must have the following keys :
	["source directory"]       Where to download the files from.
	["destination directory"]  Where to save the files
	["update always"]
	["files"]                  An array of filenames

to download a file the installer concatenates ["source directory"] and
the filenames from ["files"]. There is no way to rename files yet. You
can't download a file from pastebin and store it under a  different
name.

["update always"] is useful if your api contains files that rarely
change. For example the terrapin API collection pulls in the Penlight
libraries. These libraries are stable now. We don't need to download a
new copy each time we run the updater so we set ["update always"] to
false. To force the installer to update them we use --all option.

]]


local function log(string)
	local logfile = assert(fs.open("install_log.txt", "a"))
	logfile.write(string .. "\n")
	logfile.close()
end

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

	log("Saving " .. path_on_server .. " to " .. path_on_client)
end

local function uninstallSection(section_name, section)
	print("Uninstalling " .. section_name)
	log("Uninstalling " .. section_name)

	if section["destination directory"] == "/" then
		for _, file in ipairs(section["files"]) do
			fs.delete( fs.combine(section["destination directory"], file) )
		end
		return
	end

	-- TODO : Check that the directory is empty before deleting the entire directory
	fs.delete(section["destination directory"])
end

local function installSection(section_name, section, base_dir)
	log("Installing section : " .. section_name)

	local files = section["files"]
	local _, term_y     = term.getCursorPos()
	local term_width, _ = term.getSize()

	io.write("Installing " .. section_name)

	-- check if the base directory exists :
	fs.makeDir(section["destination directory"])

	for idx, file in ipairs(files) do
		local source_file = section["source directory"] .. file
		local dest_file   = fs.combine(section["destination directory"], file)

		saveFile(source_file, dest_file)
		log("Saved " .. source_file .. " to " .. dest_file)

		term.setCursorPos(term_width - 5, term_y)
		io.write("     ")
		term.setCursorPos(term_width - 5, term_y)
		io.write(idx .. "/" .. #files)
	end

	-- move cursor down to next line
	print()
end

local function parseCommandLineArgs( args )
	local options = {}
	for idx, arg in ipairs(args) do
		print("idx = " .. idx .. " - " ..  arg)
		options[arg] = true
	end

	return options
end

-- Start main Program

-- clear the logfile
local file = fs.open("install_log.txt", "w")
file.close()

local args = { ... }
local options = parseCommandLineArgs( args )
local uninstall_successful = true

-- clear screen
term.clear()
term.setCursorPos(1,1)
print("Installer starting.\n")

-- check that the configuration file exists. Without this file the installer is useless
if not( fs.exists("installer_cfg.lua") ) then
	error("The installer needs an installer_cfg.lua file to continue.")
end

-- load the configuration file
local installer_cfg
local cfg_file, errors = loadfile("installer_cfg.lua")
if errors then
	error("Could not open installer_cfg.lua. " .. errors)
else
	installer_cfg = cfg_file()
end

log("Installer startup succesful")

-- If the uninstall option is set then we uninstall everything and return.

if options["uninstall"] then
	for section, section_name in pairs(installer_cfg) do
		uninstallSection(section, section_name)
	end

	return 0
end

-- Detect previous installations :
-- We are either installing or updating. If we are updating then Cool, if we
-- are installing there might be an error
if fs.exists(installer_cfg["base install directory"]) then
	if options["install"] and not(options["--force"]) then
		io.write("A previous installation of terrapin was detected. All " ..
			"content in the " .. installer_cfg["base install directory"]  ..
			" will be removed. Continue ? (y/n)"
		)

		local res = io.read()
		if not (res == "y" or res == "Y") then
			io.write("\n\n Exiting installer ...\n")
			return
		end
	end
elseif options["update"] or options["update-all"] then
	io.write(
		"Unable to locate an existing installation of Terrapin API " ..
		"Collection. ABORTING."
	)
end

log("Previous installation detection succesful. Starting installation")

-- Now we can proceed witht the installation.
fs.makeDir(installer_cfg["base install directory"])
if options["install"] or options["update-all"] then
	for section_name, section in pairs(installer_cfg["sections"]) do
		installSection(section_name, section)
	end
elseif options["update"] then
	for section_name, section in pairs(installer_cfg["sections"]) do
		if section["update always"] then
			installSection(section_name, section)
		end
	end
else
	error("no installer option mode present")
end


log("Install succesful")

if not uninstall_successful then
	print(
		"The installer detected that some files were added to the terrapin "..
		"directories. These files have been left in place."
	)
end

print "\n\nInstall Succesful"

os.reboot()
