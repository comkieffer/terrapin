
--[[

When we uninstall terrapin-core we need to restore the startup file.

If we have a backed up startup file we use that one. Otherwise we recreate the
default startup file.
]]

local default_startup = [[
--DO NOT REMOVE -- ac-get
local s_dir = '/cfg/startup.d'
local files = fs.list(s_dir)
table.sort(files)
for _, start in ipairs(files) do
  local ok, err = pcall(function() dofile(s_dir .. '/' .. start) end)
  if not ok then
    printError("Error in startup: " .. err)
  end
end
--DO NOT REMOVE
]]

if fs.exists('/startup.bak') then
	fs.delete('/startup')
	fs.move('/startup.bak', '/startup')
else
	local startup_file = io.open('/startup', 'w')
	startup_file:write(default_startup)
	startup_file:close()
end
