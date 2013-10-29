
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

local function uninstallSection(section_name, section, base_dir)
	io.write("Uninstalling " .. section_name)
	log("Uninstalling " .. section_name)
	local dir = fs.combine(base_dir, section["destination directory"])
	deleteDirectory(dir)

	print()
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

local function installSection(section_name, section, base_dir)
	log("Installing section : " .. section_name)
	--log("section = " .. tbl_as_str(section))

	local files = section["files"]
	--log("files to install : " .. tbl_as_str(files))
	local _, term_y = term.getCursorPos()
	local term_width, _ = term.getSize()

	io.write("Installing " .. section_name)
	log(term_width .. " -- wdith")

	local destination_dir = fs.combine(base_dir, section["destination directory"])

	-- check if the base directory exists :
	fs.makeDir(fs.combine(base_dir, section["destination directory"]))

	for idx, file in ipairs(files) do
		local source_file = section["source directory"] .. file .. ".lua"
		local dest_file   = fs.combine(destination_dir, file) .. ".lua"

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

local function deleteDirectory(dir)
	log("deleting directory : " .. dir)
	if fs.exists(dir) then
		fs.delete(dir)
	end
end	

local function parseCommandLineArgs( args )
	local options = {}
	for idx, arg in ipairs(args) do
		print("idx = " .. idx .. " - " ..  arg)
		options["arg"] = true
	end

	return options
end

-- Start main Program

local args = { ... }
local options = parseCommandLineArgs( args )
local uninstall_successful = true

-- clear screen
term.clear()
term.setCursorPos(1,1)
print("tInstaller starting.\n")

-- clear the logfile
local file = fs.open("install_log.txt", "w")
file.close()


-- check that the configuration file exists. Without this file the installer is useless
if not( fs.exists("installer_cfg.lua") ) then
	error("The installer needs an installer_cfg.lua file to continue.")
end

-- load the configuration file 
local installer_cfg, errors = loadfile("installer_cfg.lua")()
if not installer_cfg then
	error("Could not open installer_cfg.lua. " .. errors)
end

-- check the mode for the installer. At least one option from 
-- install, update-all or update must be present
if not(options["install"]) and not(options["update"]) and not(options["update-all"]) then
	options["install"] = true
end

log("Startup succesful")
 
-- check for traces of previous installations :
if fs.exists(installer_cfg["base install directory"]) then
	-- If we are in install mode then delete all the files.
	-- we will overrite them anyway
	if options["install"] or options["update all"] then
		-- Warn the use that we are about to uninstall the apis. 
		if not(options["yes"]) then
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

		-- If we are still here the user is Ok with /terrapin disappearing
		deleteDirectory(installer_cfg["base install directory"])
	elseif options["update"] then
		for section_name, section in pairs(installer_cfg["sections"]) do
			if section["update always"] then
				uninstallSection(section_name, section, installer_cfg["base install directory"])
			end
		end
	else
		error("No installer mode option present")
	end
end

log("Previous installation detection succesful. Starting installation")

-- Now we can proceed witht the installation. 
fs.makeDir(installer_cfg["base install directory"])

if options["install"] or options["update-all"] then
	for section_name, section in pairs(installer_cfg["sections"]) do
		log("Preparing to install section : " .. section_name)
		log("section = " .. tbl_as_str(section))
		installSection(section_name, section, installer_cfg["base install directory"])
	end
elseif options["update"] then 
	for section_name, section in pairs(installer_cfg["sections"]) do
		if section["update always"] then
			installSection(section_name, section, installer_cfg["base install directory"])
		end
	end
else
	error("no installer option mode present")
end

log("Install succesful")

if not uninstall_successful then
	print("The installer detected that some files were added to the terraopin directories. " ..
		  "These files have been left in place.")
end

print "\n\nInstall Succesful"
