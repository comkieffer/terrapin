
--[[--
A simple package manager for the terrapin APIs

This application will download packages from the internet. Each package contains
a manifest file that lists files and dependencies. The package manager will then
download the files that the package specifies.

The strength of this ackage manager is it's concept of channels. Instead of
being dependant on one hosting location users can add create their own self
hosted repos.

A repo is just a folder on a web-server.

USAGE :

	pm install package_name         [DONE]
	pm uninstall package_name       [TODO]

	pm list installed               [TODO]
	pm list available               [TODO]

	pm search package_name          [TODO]

	pm channel list                 [DONE]
	pm channel add channel_name     [DONE]
	pm channel remove channel_name  [TODO]

To host your channel you need to create a folder in your web host. This will be
the base directory of your channel. In this folder you should put a packagelist
file under packages.lua.

The packagelist file tells the package manager what packages are available in
your channel as well as what your channel should be called.

It should have the following structure :

	{
		["name"] = "my-channel-name",

		["packages"] = {
			"packaage_1", "package_2",
		},
	}

When you use the package manager to download a package it will search all of the
channels that have been added to it for a package with the same name. If it find
one it will download it from channel_url/package_name. If the package is at any
other location it will not be found.

A valid ackage folder should have a manifest.lua file in the root. This file
tells the package manager what dependencies the package has as well as what
files it contains.

The files sections is divided into 3 parts :

* API: for files that should be loaded with require.
* programs:  for executable files. At startup an alias will be made for each one
*  of these so that you can call them without typing in their full path.
* startup: these files will be run at startup after the system has initialised

An example manifest.lua fie is :

	{
		["dependencies"] = {
			"test2",
		},

		["API"] = {
			"test1api1.lua", "test1api2.lua"
		},

		["programs"] = {
			"test1.lua"
		},
	}

After rebooting the sytem we will be able to run test1.lua by simply typing
test1 in the prompt.

We will also be able to use the apis by adding:

	local api =  require 'test1api1'

to our programs.

@script pm
]]

local function usage()
	print "TODO"
end

local function joinKeys(table, sep)
	sep = sep or ' '
	local str = ''

	for k,_ in pairs(table) do
		str = str .. sep .. tostring(k)
	end

	return str
end

local function slice(src, start, stop)
	stop = stop or #src
	local ret = {}

	for k = 1, #src do
		if k >= start and k <= stop then
			table.insert(ret, src[k])
		end
	end

	return ret
end

local function assert_arg(num, arg, arg_type)
	if type(arg) ~= arg_type then
		error(
			("argument %d expected a '%s', got a '%s'")
			:format(num, arg_type, type(arg)), 3
		)
	end
end

-- Check to see if a folder exists.
-- 	strict mode produces an error if the folder already exists
--  otherwise an error is only produced if the path leads to a file.
--		eg: /packages/ (folder) -> OK
--		    /packages  (file)   -> Error
--
--
-- @param dir The directory to check
-- @param err The error message to display
-- @param strict wether to use strict mode or not
local function testDir(dir, err, strict)
	strict = strict or false

	if fs.exists(dir) then
		if strict or (not fs.isDir(dir)) then
			error(err, 2)
		end
	else
		fs.makeDir(dir)
	end
end

local function log(message, context)
	message  = ("day %d @ %s %s - %s\n"):format(
		os.day(), textutils.formatTime(os.time(), false),
		context or '????', message or ''
	)

	local logfile = fs.open('/pm.log', 'a')
	logfile.write(message)
	logfile.close()
end


local function Package(package_name, parent_channel)
	local self = {
		["name"] = package_name,
		["parent_channel"] = parent_channel,
	}

	function self.parseManifest(manifest)
		if not manifest then
			error(
				'Malformed manifest file: No data found. If the manifest.lua '..
				'file is not empty this might mean that it is not a valid '   ..
				'lua  table.'
			)
		end

		if not manifest["dependencies"] then
			error('Malformed manifest: "dependencies" not found')
		end

		if type(manifest["dependencies"]) ~= "table" then
			error(
				'Malformed manifest.lua file: "dependencies" must be a ' ..
				'table, was a: ' .. type(manifest["dependencies"])
			)
		end

		if not manifest["API"] then
			error('Malformed manifest: "API" not found')
		end

		if type(manifest["API"]) ~= "table" then
			error(
				'Malformed manifest.lua file: "API" must be a table, was a: ' ..
				type(manifest["API"])
			)
		end

		if not manifest["programs"] then
			error('Malformed manifest: "programs" not found')
		end

		if type(manifest["programs"]) ~= "table" then
			error(
				'Malformed manifest.lua file: "programs" must be a table, was a: ' ..
				type(manifest["programs"])
			)
		end

		if not manifest["autoruns"] then
			error('Malformed manifest: "autoruns" not found')
		end

		if type(manifest["autoruns"]) ~= "table" then
			error(
				'Malformed manifest.lua file: "autoruns" must be a table, was a: ' ..
				type(manifest["autoruns"])
			)
		end

		if manifest["other-files"] and type(manifest["other-files"]) ~= "table" then
			error(
				'Malformed manifest.lua file: "other-files" must be a table, was a: ' ..
				type(manifest["autoruns"])
			)
		end

		if manifest["other-files"] then
			for k = 1, #manifest["other-files"] do
				local el = manifest["other-files"][k]

				if #el ~= 2 or type(el[1]) ~= 'string' or type(el[2]) ~= 'string'
				then
					error(
						'Malformed manifest.lua file: element %s in '         ..
						'"other-files" should contain 2 strings: the src '    ..
						'path on the server and the destination path on the ' ..
						'computer'
					)
				end
			end
		end

		self["direct_dependencies"] = manifest["dependencies"]

		self["APIs"] = manifest["API"]
		self["programs"] = manifest["programs"]
		self["autoruns"] = manifest["autoruns"]
		self["other-files"] = manifest["other-files"] or {}

		log(
			('Found %d dependencies for package %s/%s')
			:format(#self["direct_dependencies"], self["parent_channel"]["name"],
				self["name"]), 'Package:parseManifest'
		)
	end

	function self.fetchManifest()
		local manifest_path =
			parent_channel["url"] .. "/" .. self["name"] .. "/manifest.lua"

		log("Downloading manifest from " .. manifest_path, 'Package:fetchManifest')

		local manifest_handle, err = http.get(manifest_path)
		if not manifest_handle then
			error(
				('Unable to download manifest file for %s from %s.\nError: %s')
				:format(self["name"], manifest_path, err)
			)
		end

		log("Success. Manifest available", 'Package:fetchManifest')

		local manifest_data = textutils.unserialise(manifest_handle.readAll())
		self.parseManifest(manifest_data)
	end

	--- Resolve the dependencies for a package.
	--
	-- This function calculates all the packages that this package depends on
	-- and returns them as a list excluding the packages that are in the
	-- whitelist.
	-- This list will contain all the dependencies of the dependencies.
	--
	-- The whitelist is a protection against circular references.
	-- @param whitelist A List of packages that have already been considered
	--		higher up in the dependency chain.
	-- @retun A List containing the dependendies of this package.
	function self.resolveDependencies(whitelist)
		whitelist = whitelist or {}

		-- Dependencies is a map with package names as keys and packages as values
		self["dependencies"] = {}

		local whitelist_str = ""
		log(
			("Recursively searching for dependencies for %s. Whitelist is: %s")
			:format(self["name"], whitelist_str),
			'Package:resolveDependencies'
		)

		-- When we parsed the manifest the dependencies for theis package were
		-- added to the direct_dependencies list.
		-- We need to recursively fetch the dependencies for each one to build a
		--  full dependency list.
		for k = 1, #self['direct_dependencies'] do
			package_name = self['direct_dependencies'][k]

			log(
				('%s depends on %s'):format(self['name'], package_name),
				'Package:resolveDependencies'
			)

			-- check to see if a package with the same name is in the whitelist
			-- If it is we can skip it.
			if whitelist[name] then
				log(
					package_name .. ' is already in the whitelist. Skipped',
					'Package:resolveDependencies'
				)

			-- Otherwise we need to build it's set of dependencies.
			else
				log(
					package_name .. " is not in the white list. Searching " ..
					"channel ...", 'Package:resolveDependencies'
				)

				-- If we can find the package in the channel everything is fine.
				-- Otherwise we will produce an error.
				package = self["parent_channel"].find(package_name)
				if package then
					log(
						("Found package %s in %s")
						:format(package_name,self["parent_channel"]["name"]),
						'Package:resolveDependencies'
					)

					package.fetchManifest()

					-- We add the ackage to the dependency list and get all of
					-- it's dependencies.
					self["dependencies"][package_name] = package

					log(
						"searching for dependencies added by " ..
						package_name .. " ...", 'Package:resolveDependencies'
					)
					local new_deps = package.resolveDependencies(self["dependencies"])

					for name, package in pairs(new_deps) do
						self["dependencies"][name] = package
					end

					log(("%s depends on the following packages: %s")
						:format(package_name, joinKeys(new_deps)),
						'Package:resolveDependencies'
					)
				else
					error(('Unmet dependency: unable to locate %s in %s')
						:format(depends, self["parent_channel"]["name"])
					)
				end
			end
		end

		-- We've made it through the list of packages.
		-- We have a comlete set of dependencies minus the packages present in
		-- the whitelist.

		log(
			("Finished comiling dependencies for %s: %s")
			:format(self["name"], joinKeys(self["dependencies"])), 'Package:resolveDependencies'
		)

		return self["dependencies"]
	end

	--
	function self.install()
		-- make sure that the /packages folder exists :
		testDir('/packages',
			'pm installs packages to /packages. Since /packages already '   ..
			'exists but is not a directory pm cannot continue. Delete or '  ..
			'move /pacakges to and try again.'
		)

		-- First we install the dependencies
		for name, package in pairs(self["dependencies"]) do
			log(('Installing package %s'):format(name), 'Package:install')
			print("Installing " .. name .. " ...")

			package_path = '/packages/' .. name

			testDir(package_path, (
				'Cannot install %s to %s since the directory already exists.' ..
				'This probably means that the package has already been '      ..
				'installed. You can update it with "pm update %s'
				):format(name, package_path, name), true
			)

			package.installAPIs(package_path)
			package.installPrograms(package_path)
			package.installAutoruns(package_path)
			package.installOtherFiles()
		end

		-- Then we install the package
		log(('Installing package %s'):format(self["name"]))
		print("Installing " .. self["name"] .. " ...")

		local package_path = '/packages/' .. self["name"]
		testDir(package_path, (
			'Cannot install %s to %s since the directory already exists.' ..
			'This probably means that the package has already been '      ..
			'installed. You can update it with "pm update %s'
			):format(self["name"], package_path, self["name"]), true
		)

		self.installAPIs(package_path)
		self.installPrograms(package_path)
		self.installAutoruns(package_path)
		self.installOtherFiles()

		log(self["name"] .. ' installed.', 'Package:Install')
	end

	function self.installAPIs(package_path)
		log('Installing APIs for ' .. self["name"], 'Package:installAPIs')

		local api_path = fs.combine(package_path, 'apis')
		fs.makeDir(api_path)

		if #self["APIs"] > 0 then
			local remote_base = ('%s/%s/apis/')
				:format(self["parent_channel"]["url"], self["name"])
			self.installFiles(remote_base, api_path, self["APIs"])
		else
			log(
				('No APIs to install for %s. Skipping'):format(self["name"]),
				'Package:installAPIs'
			)
		end
	end

	function self.installPrograms(package_path)
		log('Installing programs for ' .. self["name"], 'Package:installProrgrams')

		local bin_path = fs.combine(package_path, 'bin')
		fs.makeDir(bin_path)

		if #self["programs"] > 0 then
			local remote_base = ('%s/%s/bin/')
				:format(self["parent_channel"]["url"], self["name"])
			self.installFiles(remote_base, bin_path, self["programs"])
		else
			log(
				('No programs to install for %s. Skipping'):format(self["name"]),
				'Package:installPrograms'
			)
		end
	end

	function self.installAutoruns(package_path)
		log('Installing autoruns for ' .. self["name"], 'Package:installAutoruns')

		fs.makeDir('/autorun')

		if #self["autoruns"] > 0 then
			local remote_base = ('%s/%s/autorun/')
				:format(self["parent_channel"]["url"], self["name"])
			self.installFiles(remote_base, '/autorun', self["autoruns"])
		else
			log(
				('No autoruns to install for %s. Skipping'):format(self["name"]),
				'Package:installAutoruns'
			)
		end
	end

	function self.installOtherFiles()
		log('Installing other-files for ' .. self["name"], 'Package:installOtherFiles')

		if #self["other-files"] == 0 then
			log(
				('No other-files to install for %s. Skipping'):format(self["name"]),
				'Package:installAutoruns'
			)
			return
		end

		for k = 1, #self["other-files"] do
			local src_path = ('%s/%s/%s'):format(
				self["parent_channel"]["url"], self["name"],
				self["other-files"][k][1]
			)
			local dst_path = self["other-files"][k][2]

			print(
				('%s wants to install a file to "%s".')
				:format(self["name"], dst_path)
			)
			io.write('Accept (y/n) ? ')
			local res = io.read()

			if res == 'y' or res == 'Y' then
				-- Make sure that the destination directory exists
				fs.makeDir( fs.getDir('dst_path') )
				self.installFile(src_path, dst_path	)
			else
				print "Skipped file. The package may not wotk be fully functional."
			end
		end
	end

	-- Download the files in the aray files from remote_base and save them in
	-- local_base.
	function self.installFiles(remote_base, local_base, files)
		assert_arg(1, remote_base, 'string')
		assert_arg(2, local_base, 'string')
		assert_arg(3, files, 'table')

		if #files > 0 then
			for k = 1, #files do
				local filename = files[k]

				local remote_file_path = remote_base .. filename
				local local_file_path  = fs.combine(local_base, filename)

				self.installFile(remote_file_path, local_file_path)
			end
		end
	end

	function self.installFile(src, dst)
		local file_handle, err = http.get(src)
		if not file_handle then
			error(('Unable to download %s. Error: %s'):format(src, err))
		end

		log(('Downloaded %s'):format(src), 'Package:installFile')


		local file, err = fs.open(dst, 'w')
		if not file then
			error(
				('Unable to write %s to %s. \nError: %s')
				:format(filename, file_path, err)
			)
		end

		file.write(file_handle.readAll())
		file.close()

		log(('Wrote %s to %s'):format(src, dst), 'Package:installFile')
	end

	log(
		("Initiliasing package %s/%s")
		:format(parent_channel["name"], package_name),
		'Package:Init'
	)
	return self
end


local function Channel(channel_url)
	assert_arg(1, channel_url, 'string')

	local self = {
		["url"] = channel_url,
	}

	function self.parsePackageList(packagelist)
		if not packagelist then
			-- Generally this happens because the data is not contained in a
			-- table. Just wrap it in braces and be done !
			error(
				'Malformed package file: No data found. If the packages.lua ' ..
				'file is not empty this might mean that it is not a valid '   ..
				'lua  table.'
			)
		end

		if not packagelist["name"] then
			error('Malformed packages.lua file: missing "name"')
		end

		if type(packagelist["name"]) ~= "string" then
			error(
				'Malformed packages.lua file: "name" must be a string, was '  ..
				'a: ' .. type(packagelist["name"])
			)
		end

		if not packagelist["packages"] then
			error('Malformed packages.lua: No packages specified')
		end

		if type(packagelist["packages"]) ~= "table" then
			error(
				'Malformed packages.lua file: "packages" must be a table, '  ..
				'was a: ' .. type(packagelist["packages"])
			)
		end

		self["name"]          = packagelist["name"]
		self["package_names"] = {}

		local packages_str = ""
		for k = 1, #packagelist["packages"] do
			self["package_names"][ packagelist["packages"][k] ] = true
			packages_str = packages_str .. ' ' .. packagelist["packages"][k]
		end

		log(
			("channel %s contains the follwing packages: %s")
			:format(self["name"], packages_str), 'Channel:parsePackageList'
		)
	end

	function self.fetchPackageList()
		log("Testing " .. self["url"], 'Channel:fetchPackageList')
		local h = http.get(self["url"])
		if not h then
			error("Host Unavailable")
		end
		log( "Success. Host available", 'Channel:fetchPackageList')

		log("Testing " .. self["url"] .. '/packages.lua', 'Channel:fetchPackageList')
		local packagelist_file = self["url"] .. '/packages.lua'
		local packagelist_handle = http.get(packagelist_file)

		if not packagelist_handle then
			error('Package File Unavailable')
		end

		log("Success. Package file available.", 'Channel:fetchPackageList')

		local data_str = packagelist_handle.readAll()
		local packagelist = textutils.unserialise(data_str)

		self.parsePackageList(packagelist)
	end

	--- Look for the package in this channel and return the Package if it exists
	--  or nil it doesn't.
	function self.find(package_name)
		if self["package_names"][package_name] then
			log(
				('Found package %s in channel %s')
				:format(package_name, self["name"]), 'Channel:find'
			)

			return Package(package_name, self)
		else
			print(self["name"])
			print(package_name)
			log(
				('Unable to find package %s in channel %s')
				:format(package_name, self["name"]), 'Channel:find'
			)
			return nil
		end
	end

	log("Creating new channel: " .. self["url"], 'Channel:Init')
	return self
end


local function Config()
	local self = {
		["cfg_file"] = "/pm.cfg",
		["channels"] = {}
	}

	function self.load()
		log('Loading configuration ... ', 'Config:load')
		local cfg = {}

		if fs.exists(self["cfg_file"]) then
			local cfg_file, err = fs.open(self["cfg_file"], 'r')

			if not cfg_file then error(err) end

			local cfg = textutils.unserialise(cfg_file.readAll()) or {}
			cfg_file.close()

			-- Build the channels list
			if cfg["channels"] then
				for k = 1, #cfg["channels"] do
					local channel = Channel(cfg["channels"][k])
					channel.fetchPackageList()

					table.insert(self.channels, channel)
					print("  Loaded channel: " .. channel["name"])
				end
			end
		end

		log(
			('Configuration loaded. Loaded %s channels')
			:format(#self["channels"]), 'Config:load'
		)
		return self
	end

	-- TODO: Write this when you pick it up again
	function self.save()
		log("Saving configuration ... ", 'Config:save')
		local cfg, err = fs.open(self["cfg_file"], 'w')

		if not cfg then error(err) end

		local cfg_data = {
			["channels"] = {}
 		}

 		for k = 1, #self["channels"] do
 			table.insert(cfg_data["channels"],self["channels"][k]["url"])
 		end

 		cfg.write(textutils.serialise(cfg_data))
 		cfg.close()

 		log("Configuration saved.", 'Config:save')
		return self
	end

	log('Initialised configuration', 'Config:Init')
	return self
end


local actions = {
	["channel"] = function(args, cfg)
		local subactions = {
			["add"] = function(args, cfg)
				if #args < 1 then error('Parse Error') end
				local channel_url = args[1]

				-- Check to see if the channel already exists
				for k = 1, #cfg["channels"] do
					local channel = cfg["channels"][k]

					if channel["url"] == channel_url then
						error("A channel with the same url has already been registered.")
					end
				end

				-- Now we can actually add the channel
				local channel = Channel(channel_url)
				channel:fetchPackageList()
				print("  Found channel " .. channel["name"])

				table.insert(cfg["channels"], channel)
				cfg.save()

				print "Added channel to pm configuration"
			end,

			["list"] = function(cfg)
				-- Since the channel list is already displayed in the startup
				-- sequence this is redundant
				return

				-- if #cfg["channels"] > 0 then
				-- 	print "Installed Channels:"
				-- 	for k = 1, #cfg["channels"] do
				-- 		print('    ' .. cfg["channels"][k]["name"])
				-- 	end
				-- end
			end,
		}

		if subactions[args[1]] then
			subactions[args[1]](slice(args, 2), cfg)
		else
			error('Parse Error')
		end
	end,

	["install"] = function(args, cfg)
		if #args < 1 then error('Parse Error') end
		local package_name = args[1]

		-- First we look for packages with the same name
		local package
		for k = 1, #cfg["channels"] do
			local channel = cfg["channels"][k]
			log(
				('Querying channel %s for package %s')
				:format(channel["name"], package_name),
				'Action:Install'
			)

			package = channel.find(package_name)

			if package then
				print(("Found %s in channel %s"):format(package_name, channel["name"]))
				break
			end
		end

		if not package then
			local err = ('Unable to locate package %s in any channel')
				:format(package_name)

			log(err)
			error(err)
		end

		-- Then we install them. We assume at the moment that there will only
		-- ever be one match. If there are more we should display a menu and ask
		-- the user to chose which one he wants to install.
		package.fetchManifest()
		package.resolveDependencies()

		-- Before installing we show the user the list of dependencies and ask
		-- him to confirm that he wants to install them
		print(package_name .. " depends on the following packages: \n")
		print(joinKeys(package["dependencies"]))
		io.write("\nProceed ? (y/n) ")

		local res = io.read()
		if not (res == 'y' or res == 'Y') then
			print "\nStopping operation. No changes have been made."
			return
		end

		-- Finally we install the packages
		-- This will install the packages recursively.

		package.install()

	end,
}

-- Clear the log file:
local f = fs.open('/pm.log', 'w')
f.close()

log('Starting pm ... ', 'Main')

local args = { ... }

print "Loading channels ..."
local cfg = Config().load()
print(("\nLoaded %d channels."):format(#cfg["channels"]))

-- Check that the action is valid
if #args < 1 or not actions[args[1]] then
	usage()
	return -1
end

-- execute the action
actions[args[1]](slice(args, 2), cfg)

return 0
