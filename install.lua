--[[
		Welcome to com_kieffer's (un)installer.

		You may have noticed that it's big. Probably bigger than most programs 
		you'll want to distribut. It makes up for it by being very customisable.

		Usage :

		install.lua 
			Simply install all files listed in installer_cfg.lua

		install.lua uninstall
			Uninstall all files listed in installer_cfg.lua

		You may have noticed that uninstalling can cuase a problem. Say you 
		decide to add a file. If you update the installer configuration before
		uninstalling the old files then the installer will try to remove the
		new file and throw an error. To get around this we recomend using a 
		wrapper that will backup the old files, update the installer config
		and then perform the new install. This also allows you to rollback a
		botched install.
]]

--[[ 	########################################################################
		########              Functions Library                      ###########
		########################################################################
]]--

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

local function tbl_as_str(tbl)
	if tbl then
		local str = "{\n\t"
		for k,v in pairs(tbl) do 
			if type(v) == "table" then
				str = str .. "[" .. k .. "] = " .. tbl_as_str(v)
			elseif type(v) == "boolean" then
				if v then
					str = str .. (k .. " - true\n\t")
				else
					str = str .. (k .. " - false\n\t")
				end
			else
			 	str = str .. (k .. " - " .. v .. "\n\t") 
			end
		end
		return str .. "}"
	else 
		return "nil"
	end
end


local function parseCommandLineArgs( args )
	local options = {}
	for idx, arg in ipairs(args) do
		print("idx = " .. idx .. " - " ..  arg)
		options[arg] = true
	end

	return options
end


-- [TODO] - only delete the destination directory if it is empty
local function uninstallSection(section_name, section)
	print("Uninstalling " .. section_name)
	log("Uninstalling " .. section_name)
	log("section = " .. tbl_as_str(section))

	if section["destination directory"] == "/" then
		for _, file in ipairs(section["files"]) do
			fs.delete( fs.combine(section["destination directory"], file) )
		end
	else
		fs.delete(section["destination directory"])
	end
end

local function installSection(section_name, section, base_dir)
	log("Installing section : " .. section_name)
	log("section = " .. tbl_as_str(section))

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



--[[ 	########################################################################
		########                  Program Body                       ###########
		########################################################################
]]--

-- Clear out the log file
local file = fs.open("install_log.txt", "w")
file.close()

-- Parse command line arguments
local args = { ... }
local options = parseCommandLineArgs( args )

log("Started installer with options : " .. tbl_as_str(options))

-- clear screen
term.clear()
term.setCursorPos(1,1)
print("tInstaller starting.\n")

-- check that the configuration file exists. Without this file the installer is useless
if not( fs.exists("installer_cfg.lua") ) then
	error("The installer needs an installer_cfg.lua file to continue.")
end

-- load the configuration file 
local installer_cfg, errors = loadfile("installer_cfg.lua")()
if not installer_cfg then
	error("Could not open installer_cfg.lua. " .. errors)

-- Now we can start the real work. All the preconditions are met !
log('Installer startup succesfull\n')

if options["install"] then
	log("starting install process\n")
	-- we first create the base directory :
	log("creating base_directory\n");
	fs.makeDir(installer_cfg["base install directory"])

	-- now we install all the different sections
	log("Starting section installs\n")
	for section_name, section in pairs(installer_cfg["sections"]) do
		installSection(section_name, section)
	end

	log("finished install process\n")
else if options["uninstall"] then
	log("starting uninstall process\n")
	-- we remove the individual sections
	for section_name, section in installer_cfg["sections"] do
		uninstallSection(section_name, section)
	end

	-- now we try to remove the base_directory
	log("deleting base_directory")
	fs.delete(installer_cfg("base_directory"))
	log("finished uninstall process\n")
end
