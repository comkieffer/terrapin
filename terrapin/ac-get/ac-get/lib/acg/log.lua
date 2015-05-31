
logger = {
	["levels"] = {
		["DEBUG"]    = 10,
		["INFO"]     = 20,
		["WARNING"]  = 30,
		["ERROR"]    = 40,
		["CRITICAL"] = 50
	},

	["log_level"] = 20,

	["sinks"] = { },
}

function logger.do_log(self, level, context, message)
	if not self:isLevel(level) then
		error(('% is not a valid log level.'):format(level), 2)
	end

	if self.levels[level] < self.log_level then
		return
	end

	local line = ('day %d @ %s: [%s] %s -> %s\n')
		:format(
			os.day(), textutils.formatTime(os.time(), true),
			level, context, message
		)

	for _, sink in ipairs(self.sinks) do
		sink(line)
	end
end

function logger.isLevel(self, level)
	return self.levels[level]
end

function logger.setLevel(self, level)
	if not self:isLevel(level) then
		error(('% is not a valid log level.'):format(level), 2)
	end

	self.log_level = self.levels[level]
end

function logger.addSink(self, sink)
	table.insert(self.sinks, sink)
end

function logger.addFileSink(self, file_name, clear)
	if not fs.isDir('/log/') then
		fs.makeDir('/log/')
	end

	local log_file = fs.combine('/log/', file_name) .. '.log'

	-- Clear the log file:
	if clear then
		fs.open(log_file, 'w').close()
	end

	self:addSink(function(line)
		local f = fs.open(log_file, 'a')
		f.write(line)
		f.close()
	end)

	return log_file
end

function logger.debug(self, context, message)
	if not self then error('self is undefined. Did you call me with "." instead of ":" ?', 2) end
	self:do_log('DEBUG', context, message)
end

function logger.info(self, context, message)
	if not self then error('self is undefined. Did you call me with "." instead of ":" ?', 2) end
	self:do_log('INFO', context, message)
end

function logger.warning(self, context, message)
	if not self then error('self is undefined. Did you call me with "." instead of ":" ?', 2) end
	self:do_log('WARNING', context, message)
end

function logger.error(self, context, message)
	if not self then error('self is undefined. Did you call me with "." instead of ":" ?', 2) end
	self:do_log('ERROR', context, message)
end

function logger.critical(self, context, message)
	if not self then error('self is undefined. Did you call me with "." instead of ":" ?', 2) end
	self:do_log('CRITICAL', context, message)
end
