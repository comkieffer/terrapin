
local checkin_cfg = {}

print 'Checkin configuration generator'
print ''

print 'Enter the url to use for checkins :'
checkin_cfg['server_url'] = read()

print ''
print  'Enter World name : '
checkin_cfg['world_name'] = read()


print ''
print '======== RECAP   ========'
print ''
print('server_url: ' ..checkin_cfg['server_url'])
print('world_name: ' .. checkin_cfg['world_name'])
print ''
print 'saving checkin cfg ...'

-- Make sure that the file does not already exist
local file = io.open('/cfg/checkin.cfg', 'r')
if file then
	file:close()

	print('Checkin configuration file already exists. Do you want to overwrite it ? (y/n)')
	res = read()

	if not(res == 'y' or res == 'Y') then
		print('Aborting. No changes saved.')
		return
	end
end

-- reopen the file in write mode. This wilòl overwrite any previous contents
local cfg_file = io.open('/cfg/terrapin-checkin.cfg', 'w')
cfg_file:write( textutils.serialize(checkin_cfg) )
cfg_file:close()

print ''
print 'Configuration file saved. Restart the computer to test it.'
