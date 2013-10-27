
local args = { ... }

local remote_api_dir     = "http://www.comkieffer.com/terrapin/apis/"
local remote_program_dir = "http://www.comkieffer.com/terrapin/programs/"

local common_apis = {
	-- Penlight Apis
	"pl/app", "pl/array2d", "pl/class", "pl/compat", "pl/comprehension"      ,
	"pl/config", "pl/data", "pl/Date", "pl/dir", "pl/func", "pl/import_into" ,
	"pl/init", "pl/input", "pl/lapp", "pl/lexer", "pl/List", "pl/luabalanced",
	"pl/Map", "pl/MultiMap", "pl/operator", "pl/OrderedMap", "pl/permute"    ,
	"pl/pretty", "pl/seq", "pl/Set", "pl/sip", "pl/strict", "pl/stringio"    ,
	"pl/stringx", "pl/tablex", "pl/template", "pl/test", "pl/text"           ,
	"pl/types", "pl/utils", "pl/xml"                                         ,

	-- My Apis
	"config", "pickle", "require", "rsx", "termx", "ui", "utils", "vector",
}

local common_programs = { "pulse", "update", "timer" }

local turtle_apis = { "terrapin" }
local turtle_programs = {
	"clearMountain", "cut",
	"digMine",  "digNext", "digPit", "digPit", "digStair", "digTunnel", 
	"refuel", "replace", "rc",
}

local computer_programs = { "factoryController", "rednet_relay" }

-- todo test return codes
function saveFile( path_on_server, path_on_client )
	local server_file = assert(
		http.get(path_on_server), 
		"failed to download file " .. path_on_server, 2
	)
	local client_file = assert(
		fs.open(path_on_client, "w"), 
		"failed to open file " .. path_on_client, 2
	)

	client_file.write( server_file.readAll() )
	client_file.close()

	local logfile = assert(fs.open("install_log.txt", "w"))
	logfile.write("Saving " .. path_on_server .. " to " .. path_on_client)
	logfile.close()
end

-- check for previous installation 

if fs.exists("/terrapin/") and not (args[1] == "-y") then
	io.write("Install script detected a previous installation of the terrapin apis.\n")
	io.write("All content in /terrapin will be deleted. Continue anyway ? (y/n) ")

	local res = io.read()

	if not (res == "y" or res == "Y") then
		io.write("\n\n Exiting installer ...\n")
		return
	else
		fs.delete("/terrapin")
	end
end

term.clear()

--setup startup files
saveFile("http://www.comkieffer.com/terrapin/startup", "/startup")

-- install all common stuff
fs.makeDir("/terrapin/apis")
fs.makeDir("/terrapin/apis/pl")
fs.makeDir("/terrapin/programs")

io.write("Installing common APIs ... ")
for i = 1, #common_apis do
	saveFile( remote_api_dir .. common_apis[i] .. ".lua", 
		"/terrapin/apis/" .. common_apis[i] .. ".lua" )
end

io.write("Done\n")
io.write("Installing common programs ... ")

for i = 1, #common_programs do
	saveFile( remote_program_dir .. common_programs[i] .. ".lua", 
		"/terrapin/programs/" .. common_programs[i] .. ".lua" )
end

io.write("Done\n")

-- install turtle specific scripts
if turtle then
	io.write("Installing turtle specific APIs ... ")
	
	for i = 1, #turtle_apis do
		saveFile( remote_api_dir .. "turtle/" .. turtle_apis[i] .. ".lua" , 
			"/terrapin/apis/" .. turtle_apis[i] .. ".lua")
	end

	io.write("Done\n")
	io.write("Installing turtle spcific programs ... "
		)
	for i = 1, #turtle_programs do 
		saveFile( remote_program_dir .. "turtle/" .. turtle_programs[i] .. ".lua", 
			"/terrapin/programs/" .. turtle_programs[i] .. ".lua")
	end

	io.write("Done\n")
end

io.write("\ncompleted installation. Rebooting ... \n\n")

shell.run("reboot")
