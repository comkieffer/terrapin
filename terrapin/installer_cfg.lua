return {
	["base install directory"] = "/terrapin",

	["sections"] = {
		["penlight"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/pl/",
			["destination directory"] = "/terrapin/apis/pl",
			["update always"] = false,

            ["files"] = {
            	"app.lua", "array2d.lua", "class.lua", "compat.lua",
            	"comprehension.lua", "config.lua", "data.lua", "Date.lua",
            	"dir.lua", "func.lua", "import_into.lua", "init.lua",
            	"input.lua", "lapp.lua", "lexer.lua", "List.lua",
            	"luabalanced.lua", "Map.lua", "MultiMap.lua", "operator.lua",
            	"OrderedMap.lua", "permute.lua", "pretty.lua", "seq.lua",
            	"Set.lua", "sip.lua", "strict.lua", "stringio.lua",
            	"stringx.lua", "tablex.lua", "template.lua", "test.lua",
            	"text.lua", "types.lua", "utils.lua", "xml.lua",
            }
        },
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
				"fill.lua"
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
