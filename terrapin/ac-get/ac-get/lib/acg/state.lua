-- lint-mode: ac-get

State = {}

function State:init()
	self.repos = {}
	self.installed = {}

	self.hooks = {
		-- Tasks.
		task_begin = {},
		task_update = {},
		task_complete = {},
		task_error = {},
	}

	self.repo_hash = 0
end

function State:add_repo(url, desc)
	-- Duplicate checking
	for hash, r in pairs(self.repos) do
		if r.url == url then
			r:update()
			return r
		end
	end

	local repo = new(Repo, self, url, desc)
	repo.hash = self:new_repo_hash()

	self.repos[repo.hash] = repo

	repo:update()

	logger:debug("State::add_repo", "Added repo " .. url)

	return repo
end

-- Runs the manifest from the given URL
function State:run_manifest(url)
	local directives = {}

	directives["Add-Repo"] = function(val) self:add_repo(val) end
	directives["Install"] = function(val) self:install(val) end
	directives["Run-Manifest"] = function(val) self:run_manifest(val) end

	for _, plugin in PluginRegistry.state:iter() do
		plugin.manifest(self, directives)
	end

	parse_manifest(url, directives)
end

function State:new_repo_hash()
	self.repo_hash = self.repo_hash + 1

	return self.repo_hash
end

function State:install(pkg_name)
	for _, repo in ipairs(self.repos) do
		logger:debug('State:install',
			('Looking for package <%s> in repos ...'):format(pkg_name))
		local pkg_obj = repo:get_package(pkg_name)

		if pkg_obj ~= nil then
			logger:debug('State::install', 'Success! Found package ' .. pkg_name)
			return self:do_install_package(pkg_obj)
		end
	end

	return false, 'No repo provides package "' .. pkg_name .. '"'
end

function State:remove(pkg_name)
	for _, pkg in ipairs(self.installed) do
		if pkg.name == pkg_name then
			return self:do_remove_package(pkg.repo:get_package(pkg_name))
		end
	end

	return false, 'Package "' .. pkg_name .. '" is not installed.'
end

function State:do_install_package(pkg)
	logger:debug('State::do_install_package', 'Installing package ...')
	pkg:update()

	local inst_pkg = self:get_installed(pkg.name)

	if inst_pkg and inst_pkg.version >= pkg.version and not pkg.repo.dev_mode then
		logger:debug("State::do_install_package",
			("Package <%s> is already installed."):format(pkg.name))

		return true, "Package already installed."
	end

	logger:debug('State::do_install_package',
		('Installing dependencies for package <%s>'):format(pkg.name))
	for _, dep in ipairs(pkg.dependencies) do
		logger:debug('State::do_install_package',
			('Package <%s> depends on <%s>'):format(pkg.name, tostring(dep)))
		local ok, err = self:install(dep)

		if not ok then
			return false, "Error in dependency '" .. dep .. "': " .. err
		end
	end

	if inst_pkg then
		pkg:run_step(self, "pre_upgrade", inst_pkg.version, pkg.version)
	else
		pkg:run_step(self, "pre_install")
	end

	local ok, err = pkg:install(self)

	if not ok then
		pkg:remove(self)

		return false, "Error installing " .. pkg.name .. ": " .. err
	end

	if inst_pkg then
		pkg:run_step(self, "post_upgrade", inst_pkg.version, pkg.version)
	else
		pkg:run_step(self, "post_install")
	end

	self:mark_installed(pkg)

	return true, "Package Installed."
end


function State:do_remove_package(pkg)
	pkg:run_step(self, "pre_remove")
	pkg:remove(self)
	pkg:run_step(self, "post_remove")

	self:mark_removed(pkg)

	return true, "Package Removed"
end

function State:mark_installed(pkg)
	for _, i_pkg in ipairs(self.installed) do
		if i_pkg.name == pkg.name then
			i_pkg.version = pkg.version

			return
		else
			sleep(0)
		end
	end

	table.insert(self.installed, pkg)
	self:get_package(pkg.name).state = "installed"
end

function State:mark_removed(pkg)
	self:get_package(pkg.name).state = "removed"

	for i, i_pkg in ipairs(self.installed) do
		if i_pkg.name == pkg.name then
			table.remove(self.installed, i)

			return
		end
	end
end

function State:is_installed(pkg_name)
	return self:get_installed(pkg_name) ~= nil
end

function State:get_installed(pkg_name)
	for _, pkg in ipairs(self.installed) do
		if pkg.name == pkg_name then
			return pkg
		end
	end

	return nil
end

function State:save()
	logger:debug("State::save", "Saving state...")

	local f = fs.open(dirs["repo-state"] .. "/index", "w")

	f.write(VERSION .. "\n")

	f.write(self.repo_hash .. "\n")

	for hash, repo in pairs(self.repos) do
		f.write(hash .. '::' .. repo.url .. '\n')
		repo:save()
	end

	f.close()

	f = fs.open(dirs['state'] .. '/installed', 'w')

	f.write(VERSION .. '\n')

	for _, pkg in ipairs(self.installed) do
		f.write(pkg.repo.hash .. '::' .. pkg.name .. '::' .. pkg.version .. '\n')
	end

	f.close()

	logger:debug("State::save", "Saving from plugins.")

	for _, plugin in PluginRegistry.state:iter() do
		plugin.save(self)
	end

	logger:debug("State::save", "Done.")
end

-- State Manupulation Functions
function State:make_dir(pkg, dtype, name)
	if fs.isDir(dirs[dtype] .. '/' .. name) then
		return
	end

	fs.makeDir(dirs[dtype] .. '/' .. name)
end

function State:pull_file(pkg, ftype, name, url)
	name = dirs[ftype] .. '/' .. name

	local remote = get_url(url)

	local loc, err = fs.open(name, 'w')
	if not loc then
		error('Unable to open file ' .. name .. ': ' ..err)
	end

	local buff = remote.readAll() .. ""

	sleep(0)

	buff = buff:gsub("__" .. "LIB" .. "__", dirs["libraries"])
	buff = buff:gsub("__" .. "CFG" .. "__", dirs["config"])
	buff = buff:gsub("__" .. "BIN" .. "__", dirs["binaries"])

	for _, plugin in PluginRegistry.state:iter() do
		local new_buff = plugin.process(buff)

		if new_buff ~= "" then
			buff = new_buff
		end
	end

	loc.write(buff)
	loc.close()

	remote.close()
end


function State:remove_dir(type, name)
	name = dirs[type] .. '/' .. name

	if not fs.exists(name) then
		return
	end

	if not fs.isDir(name) then
		return
	end

	fs.delete(name)
end

function State:remove_file(type, name)
	name = dirs[type] .. '/' .. name

	if not fs.exists(name) then
		return
	end

	fs.delete(name)
end

-- Package state tracking.

function State:get_package(pkg_name)
	return self:get_packages()[pkg_name]
end

function State:get_packages()
	if self._packages then
		return self._packages
	end

	local pkgs = {}

	for _, repo in pairs(self.repos) do
		for _, pkg in ipairs(repo.packages) do
			if pkgs[pkg.name] and pkgs[pkg.name].version < pkg.version then
				pkgs[pkg.name] = pkg
			elseif not pkgs[pkg.name] then
				pkgs[pkg.name] = pkg
			end
		end
	end

	for name, pkg in pairs(pkgs) do
		self:_load_state(name, pkg)
	end

	for _, pkg in ipairs(self.installed) do
		if not pkgs[pkg.name] then
			pkg.state = 'orphaned'

			pkgs[pkg.name] = pkg
		end
	end

	self._packages = pkgs

	return pkgs
end


function State:_load_state(pkg_name, pkg)
	local ipkg = self:get_installed(pkg_name)

	if not ipkg then
		pkg.state = 'available'
	else
		if ipkg.version < pkg.version then
			pkg.state = 'update'
		else
			pkg.state = 'installed'
		end

		pkg.iversion = ipkg.version
	end
end

-- Client Hooks

function State:hook(evt, func)
	if not self.hooks[evt] then
		error("Invalid state hook", 2)
	end

	table.insert(self.hooks[evt], func)
end

function State:call_hook(evt, ...)
	if not self.hooks[evt] then
		error("Invalid state hook", 2)
	end

	for _, func in ipairs(self.hooks[evt]) do
		pcall(func, ...)
	end
end

-- Task Handling

function State:begin_task(id, steps)
	return new(Task, self, id, steps)
end

-- Loading Function

function load_state()
	logger:debug("State::load", "Loading State...")

	local state = new(State)

	local f = fs.open(dirs['repo-state'] .. '/index', 'r')

	if tonumber(f.readLine()) > VERSION then
		logger:critical("State::load", 'State files too new?')
	end

	state.repo_hash = tonumber(f.readLine())

	local repos = {}

	logger:debug("State::load", "Loading Repos ...")

	for line in read_lines(f) do
		local id = line:match('([0-9]+)::')

		local repo = new(Repo, state, line:sub(#id + 3), 'Loading ...')
		repo.hash = tonumber(id)

		sleep(0)
		repo:load()
		sleep(0)

		state.repos[repo.hash] = repo
	end

	f.close()

	logger:debug("State::load", "Loading Installed Packages ...")

	f = fs.open(dirs['state'] .. '/installed', 'r')

	if tonumber(f.readLine()) > VERSION then
		error('State files too new?')
	end

	for line in read_lines(f) do
		local idx = line:find("::")
		local repo_hash = tonumber(line:sub(1, idx-1))
		local idx2 = line:find("::", idx+2)
		local pkg_name = line:sub(idx + 2, idx2 - 1)
		local pkg_version = line:sub(idx2+2)

		local pkg = new(Package, state.repos[repo_hash], pkg_name)
		pkg.version = tonumber(pkg_version)

		table.insert(state.installed, pkg)
	end

	logger:debug("State::plugins::load", "Loading from plugins.")

	for _, plug in PluginRegistry.state:iter() do
		plug.load(state)
	end

	logger:debug("State::load", "Done.")

	return state
end
