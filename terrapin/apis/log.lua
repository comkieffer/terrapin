
class = require 'pl.class'
utils = require 'pl.utils'

class.Logger()

function Logger:_init(file_name)
    utils.assert_string(1, file_name)

	self.file_name = file_name
	-- if the file already exists make sure to clear it. Otherwise create it.
	-- Simply clearing it is easier than rotating and since the computers have
	-- limited memory we keep as much of it free as possible.

	f = fs.open(self.file_name, 'w')
	f.close()
end

function Logger:log(message)
	f = fs.open(self.file_name, 'a')
	f.write(message .. '\n')
	f.close()
end

return Logger
