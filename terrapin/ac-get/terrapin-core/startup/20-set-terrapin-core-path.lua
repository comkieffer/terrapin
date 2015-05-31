
if fs.exists('/bin/terrapin-core') then
	shell.setPath(shell.path() .. ':/bin/terrapin-core')
else
	log('Unable to locate executables for terrapin-core in: /bin/terrapin-core')
end
