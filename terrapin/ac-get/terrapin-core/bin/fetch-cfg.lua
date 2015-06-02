
local args = { ... }

if #args ~= 1 then
	print("USAGE:")
	print("	fetch-cfg <pastebin-code>")
	print("")
	print("You can find out the pastebin-code for the current world by " ..
	      " going to the world page in the web ui.")

	return
end

shell.run("pastebin", "get", args[1], "/cfg/terrapin-checkin.cfg")
