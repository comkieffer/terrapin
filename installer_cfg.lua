local config = {
	["base install directory"] = "/terrapin",

	["sections"] = {
		["penlight"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/pl",
			["destination directory"] = "apis/pl",
			["update always"] = false,

			["files"] = {
				"pl/app", "pl/array2d", "pl/class", "pl/compat", "pl/comprehension"      ,
				"pl/config", "pl/data", "pl/Date", "pl/dir", "pl/func", "pl/import_into" ,
				"pl/init", "pl/input", "pl/lapp", "pl/lexer", "pl/List", "pl/luabalanced",
				"pl/Map", "pl/MultiMap", "pl/operator", "pl/OrderedMap", "pl/permute"    ,
				"pl/pretty", "pl/seq", "pl/Set", "pl/sip", "pl/strict", "pl/stringio"    ,
				"pl/stringx", "pl/tablex", "pl/template", "pl/test", "pl/text"           ,
				"pl/types", "pl/utils", "pl/xml"                                         ,
			}
		},
		["common apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/",
			["destination directory"] = "apis/",
			["update always"] = true,	

			["files"] = {
				"config", "pickle", "require", "rsx", "termx", "ui", "utils", "vector"   ,
			}
		},
		["turtle apis"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/apis/turtle",
			["destination directory"] = "apis/",
			["update always"] = true,	

			["files"] = {
				"terrapin",
			}
		},
		["common programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/",
			["destination directory"] = "programs/",
			["update always"] = true,	

			["files"] = {
				"pulse", "update", "timer",
			}
		},
		["turtle programs"] = {
			["source directory"] = "http://www.comkieffer.com/terrapin/programs/",
			["destination directory"] = "programs/",
			["update always"] = true,	

			["files"] = {
				"clearMountain", "cut",
				"digMine",  "digNext", "digPit", "digStair", "digTunnel", 
				"refuel", "replace", "rc",
			}
		},
	}, -- End Sections
} -- end config

return config
