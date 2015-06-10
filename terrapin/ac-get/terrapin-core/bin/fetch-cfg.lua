
local CONFIG_BASE_PATH = 'http://localhost:8100/config/'
local args = { ... }

if #args ~= 1 then
	print("USAGE:")
	print("	fetch-cfg <config-code>")
	print("")
	print("You can find out the config-code for the current world by " ..
	      " going to the world page in the web ui.")

	return
end

io.write('Connecting to ' .. CONFIG_BASE_PATH .. '...')

local h = http.get(CONFIG_BASE_PATH .. args[1])
if not h then
	io.write('FAIL\n')
	error('Unable to access ' .. CONFIG_BASE_PATH .. args[1])
end

local f = fs.open('/cfg/checkin.cfg', 'w')
if not f then
	io.write('FAIL\n')
	error('Unable to open /cfg/checkin.cfg')
end

f.write(h.readAll())
f.close()

print()
print('Saved configuration to /cfg/checkin.cfg')
print('Restart the computer to start using the checkin system.')
