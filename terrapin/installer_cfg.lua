
return {
	["base install directory"] = "/terrapin",

	["sections"] = {
		["sanelight apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/apis/sanelight/",
			["destination directory"] = "/terrapin/apis/sanelight",
			["update always"] = false,

			["files"] = {
				"array2d.lua", "class.lua", "compat.lua", "comprehension.lua", "date.lua",
				"lapp.lua", "list.lua", "luabalanced.lua", "map.lua", "multimap.lua",
				"operator.lua", "orderedmap.lua", "permute.lua", "pretty.lua", "seq.lua", "sip.lua",
				"strict.lua", "stringx.lua", "tablex.lua", "text.lua", "types.lua", "utils.lua",
			}
		},

		["common apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/apis/",
			["destination directory"] = "/terrapin/apis/",
			["update always"] = true,

			["files"] = {
				"require.lua", "log.lua", "ui.lua", "checkin/client.lua",
				"checkin/server.lua", "config.lua",
			}
		},

		["turtle apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/apis/turtle/",
			["destination directory"] = "/terrapin/apis/",
			["update always"] = true,

			["files"] = {
				"terrapin.lua", "smartslot.lua", 'libdig.lua',
				"terrapin/exploration.lua", "terrapin/inertial_nav.lua",
				"terrapin/inventory.lua", "terrapin/movement.lua"
			}
		},

		["common programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/programs/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,

			["files"] = {
				"pulse.lua", "update.lua", "timer.lua", "bootstrap.lua",
			}
		},

		["turtle programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/programs/turtle/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,

			["files"] = {
				"clear.lua", "cut.lua",	"digMine.lua",  "digNext.lua",
				"digPit.lua", "digStair.lua", "digTunnel.lua", "refuel.lua",
				"rc.lua", "bridge.lua", "inspect.lua", "replace.lua",
				"fill.lua", "treeFarm.lua"
			}
		},

		["turtle configurations"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/config/",
			["destination directory"] = "/terrapin/config/",
			["update always"] = true,

			["files"] = {
				"terrapin.cfg",
			}
		},


		["startup"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin_2.0/",
			["destination directory"] = "/",
			["update always"] = true,

			["files"] = {"startup", "init"}
		},
	}, -- End Sections
} -- end config
