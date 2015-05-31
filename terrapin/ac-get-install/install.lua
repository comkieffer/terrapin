local BASE_URL       = 'http://comkieffer.com/terrapin'
local FILE_LIST      = BASE_URL .. '/ac-get-install/file_list.txt'
local MANIFEST       = BASE_URL .. "/ac-get-install/install.manifest"
local INSTALL_SOURCE = BASE_URL .. "/ac-get/ac-get/lib/acg"

local args = {...}

if args[1] then
	MANIFEST = args[1]
end

function get_url(url)
	if http == nil then
		error('Need HTTP library enabled.', 2)
	end

	local remote = http.get(url)

	if remote == nil then
		error('Error: Unable to fetch ' .. url, 2)
	end

	return remote
end

-----------------------------------------------------------

local x, y = term.getCursorPos()
local w, h = term.getSize()

-- Save the cursor position so that task updates know what line to modify
-- @param id - unused - A unique identifier for the task
local function task_begin(id)
	x, y = term.getCursorPos()
end

-- Update the progress on the current task
--
-- @param id - unused - A unique identifier for the task
-- @param detail - A short description of the current operation
-- @param cur - The current progress of the operation
-- @param max - The total number of steps to complete before the operation will finish
local function task_update(id, detail, cur, max)
  local txt = cur .. "/" .. max

  if max == 0 then
    txt = cur .. ""
  end

  term.setCursorPos(x, y)
  term.clearLine()


  if #detail > w - #txt - 1 then
    detail = detail:sub(1, w - #txt - 4) .. "..."
  end


  term.write(detail)

  term.setCursorPos(w - #txt + 1, y)
  term.write(txt)
end

-- Clears the progress for the current task and writes "Complete" at the end of
-- the line
--
-- @param id - unused - A unique identifier for the task
-- @param detail - A short description of the current operation
local function task_complete(id, detail)
	  local txt = "Complete"

	  if detail ~= "" then
	    term.setCursorPos(x, y)
	    term.clearLine()


	    if #detail > w - #txt - 1 then
	      detail = detail:sub(1, w - #txt - 4) .. "..."
	    end

	    term.write(detail)
	  end

	  term.setCursorPos(w - #txt + 1, y)
	  term.write(txt)

	  print()
end

-- flush the log file
local log_f = io.open("/acg-install.log", "w")
log_f:close()

local function print_log(lvl, msg)
	local log_f = io.open("/acg-install.log", "w")
	log_f:write(lvl .. " - " .. msg .. "\n")
	log_f:close()
end


local tmp_dir = '/tmp-' .. math.random(65535)
print('Initilizing first run installer in ' .. tmp_dir)

fs.makeDir(tmp_dir)

local _, e = pcall(function()
	-- Download the manifest.
	-- This file contains the list of files required to run ac-get
	local acg_base = get_url(FILE_LIST)

	local line = acg_base.readLine();
	local i = 1

	task_begin('get-files')
	repeat
		task_update('get-files', "Getting " .. line, i, 0)

		local loc_file = fs.open(tmp_dir .. '/' .. line, 'w')
		local acg_file = get_url(INSTALL_SOURCE .. '/' .. line)

		loc_file.write(acg_file.readAll())

		acg_file.close()
		loc_file.close()

		-- run the downloaded files (equivalent to os.loadAPI)
		dofile(tmp_dir .. '/' .. line, line)

		line = acg_base.readLine()
		i = i + 1
	until line == nil

	task_complete('get-files', 'Get ac-get installer files.')

	i = 1
	local tot = #dirs

	-- At this point we have downloaded enough to bootstrap ac-get. The dirs
	-- table, loaded frm metadata.lua describes the locations where the
	-- different types of files should be stored.
	-- We need to create these directories for ac-get to work

	task_begin('make-dirs', 'Making directories')

	for k, v in pairs(dirs) do
		task_update('make-dirs', 'Making ' .. v, i, tot)
		fs.makeDir(v)

		i = i + 1
	end

	task_complete('make-dirs', 'Creating directories.')

	-- The state object is a representation of the system. It allows us to query
	-- installed packages, create and remove files and directories and install
	-- or remove packages.
	local state = new(State)

	state:hook("task_begin", task_begin)
	state:hook("task_update", task_update)
	state:hook("task_complete", task_complete)

	log.add_target(print_log)

	-- Finally, Install ac-get. Everything we have done so far was just
	-- preparation for this.
	state:run_manifest(MANIFEST)

	--local repo = state:add_repo(BASE_REPO, 'Base ac-get repo')
	--repo:install_package('ac-get')

	state:save()
end)

if e then
	print("Error executing: " .. e)
end

-- clean up our mess
-- fs.delete(tmp_dir)
