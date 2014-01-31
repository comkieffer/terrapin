return {
	-- base directory allows us to create the directory in which we are 
	-- installing all our files.
	-- we need this otherwise we would not be able to create /terrapin/api since
	-- /terrapin doesn't exist.
	-- we also remove this directory as a last step of the unistall process if 
	-- it is empty.
	["base_directory"] = "/terrapin",

	["sections"] = {
		["penlight"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/pl/",
			["destination directory"] = "/terrapin/apis/pl",
			["update always"] = false,

			["files"] = {
				"app.lua", "array2d.lua", "class.lua", "compat.lua", "comprehension.lua"       ,
				"config.lua", "data.lua", "Date.lua", "dir.lua", "func.lua", "import_into.lua" ,
				"init.lua", "input.lua", "lapp.lua", "lexer.lua", "List.lua", "luabalanced.lua",
				"Map.lua", "MultiMap.lua", "operator.lua", "OrderedMap.lua", "permute.lua"     ,
				"pretty.lua", "seq.lua", "Set.lua", "sip.lua", "strict.lua", "stringio.lua"    ,
				"stringx.lua", "tablex.lua", "template.lua", "test.lua", "text.lua"            ,
				"types.lua", "utils.lua", "xml.lua",
			}
		},
		["common apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/",
			["destination directory"] = "/terrapin/apis/",
			["update always"] = true,	

			["files"] = {
				"config.lua", "pickle.lua", "require.lua", "rsx.lua", "termx.lua", "ui.lua"   ,
				"utils.lua", "vector.lua",
			}
		},
		["turtle apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/turtle/",
			["destination directory"] = "/terrapin/apis/",
			["update always"] = true,	

			["files"] = {
				"terrapin.lua",
			}
		},
		["common programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,	

			["files"] = {
				"pulse.lua", "update.lua", "timer.lua",
			}
		},
		["turtle programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/turtle/",
			["destination directory"] = "/terrapin/programs/",
			["update always"] = true,	

			["files"] = {
				"clearMountain.lua", "cut.lua",
				"digMine.lua",  "digNext.lua", "digPit.lua", "digStair.lua", "digTunnel.lua", 
				"refuel.lua", "rc.lua",
			}
		},
		["startup"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/",
			["destination directory"] = "/",
			["update always"] = true,

			["files"] = {"startup"}
		},
	}, -- End Sections
} -- end config
