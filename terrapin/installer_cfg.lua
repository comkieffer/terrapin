return {
	["base install directory"] = "/terrapin",

	["sections"] = {
        ["common apis"] = {
        	["source directory"] = "http://www.comkieffer.com/terrapin/apis/",
        	["destination directory"] = "/terrapin/apis/",
        	["update always"] = true,

			["files"] = {
				"config.lua", "pickle.lua", "require.lua", "rsx.lua", "log.lua",
				"termx.lua", "ui.lua", "utils.lua", "vector.lua", "checkin.lua",
			}
		},
		["turtle apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/turtle/",
			["destination directory"] = "/terrapin/apis/",
			["update always"] = true,

			["files"] = {
				"terrapin.lua", "smartslot.lua", 'libdig.lua'
			}
		},
		["common programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,

			["files"] = {
				"pulse.lua", "update.lua", "timer.lua", "bootstrap.lua",
			}
		},
		["turtle programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/turtle/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,

			["files"] = {
				"clear.lua", "cut.lua",	"digMine.lua",  "digNext.lua",
				"digPit.lua", "digStair.lua", "digTunnel.lua", "refuel.lua",
				"rc.lua", "bridge.lua", "inspect.lua", "replace.lua",
				"fill.lua", "treeFarm.lua"
			}
		},
		["startup"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/",
			["destination directory"] = "/",
			["update always"] = true,

			["files"] = {"startup", "init"}
		},
	}, -- End Sections
} -- end config
