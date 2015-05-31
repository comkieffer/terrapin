
local BASE_URL       = 'http://comkieffer.com/terrapin'
local MANIFEST       = BASE_URL .. "/ac-get-install/install.manifest"
local INSTALL_SOURCE = BASE_URL .. "/ac-get/ac-get/lib/acg/"

local file_list = {
	"log.lua",
	"metadata.lua",
	"classes.lua",
	"utils.lua",
	"package.lua",
	"repo.lua",
	"state.lua",
	"task.lua",
	"plugin-registry.lua",
}

local function log(lvl, msg)
	local logfile = fs.open('/acg-install.log', 'a')
	logfile.write(
		('day %d @ %s - [%s] %s\n')
		:format(os.day(), textutils.formatTime(os.time(), true), lvl, msg)
	)
	logfile.close()
end

local function download(src, dst)
	local h = http.get(src)

	if not h then error(h) end

	local f = fs.open(dst, 'w')
	if not f then error(f) end

	f.write(h.readAll())
	f.close()
end

function dofile_safe(file)
	log('INFO', 'dofile_safe running ' .. file)

	local file_fn, err = loadfile(file)
	if not file_fn then
		local err_msg = ('Unable to open %s. Error: %s'):format(file, err)
		log('ERROR', err_msg)
		error(err_msg)
	end

	-- Pass the environment into it so that it can access the shell API
	file_fn = setfenv(file_fn, getfenv())

	local status, err = pcall( file_fn )
	if not status then
		log('ERROR',
			('An error occurred whilst running %s. Error: %s')
			:format(file, err)
		)
		error(err)
	end
end


--[[

             Start Installation

]]

-- flush the log file
local log_f = io.open("/acg-install.log", "w")
log_f:close()

local tmp_dir = '/tmp-' .. math.random(65535)
fs.makeDir(tmp_dir)
print('Initilizing first run installer in ' .. tmp_dir)

-- Before we can do anything we need to download all the files

print "Downloading files ...\n"
for k, file in ipairs(file_list) do
	local src  = INSTALL_SOURCE .. file
	local dest = fs.combine(tmp_dir, file)

	log('INFO', 'Downloading ' .. src)

	download(src, dest)
	print('Downloaded ' .. file)

	dofile_safe(dest)
	print('  Ran '.. dest)
end

-- At this point we have downloaded enough to bootstrap ac-get. The dirs
-- table, loaded frm metadata.lua describes the locations where the
-- different types of files should be stored.
-- We need to create these directories for ac-get to work

print "\nCreating directories ..."

for k, v in pairs(dirs) do
	fs.makeDir(v)
	print("Created " .. v)
end

-- Finally, Install ac-get. Everything we have done so far was just
-- preparation for this.

-- The state object is a representation of the system. It allows us to query
-- installed packages, create and remove files and directories and install
-- or remove packages.

logger:addFileSink('acg-install')
local state = new(State)
state:run_manifest(MANIFEST)
state:save()


-- clean up our mess
fs.delete(tmp_dir)
