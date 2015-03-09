{
	["dependencies"] = {
		"pm-core", "sanelight",
	},

	["API"] = {
		"checkin/client.lua", "checkin/server.lua",

		"config.lua", "log.lua", "persist.lua", "rsx.lua", "termx.lua",
		"ui.lua", "utils.lua",
	},

	["programs"] = {
		"page.lua", "rs.lua", "timer.lua",
	},

	["autoruns"] = {
		"00_hook_error.lua", "99_print_welcome.lua",
	},

	["other-files"] = {
		{ "startup.lua", "/startup" },
	},
}
