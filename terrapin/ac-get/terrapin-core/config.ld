
file = {
	'bin/ckstat.lua',
	'bin/fetch-cfg.lua',
	'bin/page.lua',
	'bin/rs.lua',
	'bin/timer.lua',

	'lib/config.lua',
	'lib/log.lua',
	'lib/persist.lua',
	'lib/ui.lua',
	'lib/checkin/server.lua',
	'lib/checkin/client.lua',
}

sort = true
readme = 'readme.md'
format = 'markdown'
style = '!fixed'
dir = 'core-doc'

project = 'Terrapin'
title = 'Terrapin API Compilation'

description = 'Computer tools and apis'
full_description = [[
The terrapin API collection is composed of 2 parts: the generic computer set
of APIs and tools and the turtle set of APIs and tools.

This documentation only covers the APIs and tools installed with:

	ac-get install terrapin-core

To find out more about the capacties of the turtle specific parts of Terrapin
refer to the [documenation](http://www.comkieffer.com/terrapin/ac-get/terrapin-turtle/turtle-doc/).

The core feature of the `terrapin-core` is the `checkin` subsystem. It allows
your programs to send status updates to the server regularly. This means that
you can track the progress of your tasks, locate lost turtles and more !

Check out the [documentation]() for more information on how to get started.

`terrapin-core` bundles very little functionality. It is mostly a base from
which to expand your own tools. Among the useful modules note `persist`, a
system to preserve variables so that they can survive reboots.

]]

