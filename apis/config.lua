-- small config api

config = {
	["config_dir"] = "/terrapin/config/"
}

function config.load(cfg_file)
	local cfg_path = config_dir .. cfg_file .. ".cfg"
	local opts = {}

	if fs.exists(cfg_path) and not fs.isDir(cfg_path) then 
		local default_opts_file = assert(fs.open(cfg_path, "r"))
		opts = unpickle(default_opts_file.readAll())
		default_opts_file.close()
	end

	return opts
end

function config.save(cfg_file, cfg_table)
	local cfg_path = config_dir .. cfg_file .. ".cfg"

	local opts_file = assert(fs.open(cfg_path, "w"))

	opts_file.write(pickle(cfg_table))
	opts_file.close()
end
