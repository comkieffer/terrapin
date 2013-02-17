
io.write("Downloading new version of insaller ...\n")

local server_file = assert(http.get(
	"http://www.comkieffer.com/terrapin/install.lua"), 
	"Unable to download installer"
)
local client_file = assert(fs.open(
	"/install", "w"), 
	"Unable to create new local copy of installer"
)

client_file.write( server_file.readAll() )
client_file.close()

io.write("Downloaded new installer.\n")

shell.run("install")