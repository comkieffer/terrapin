
file = {
	'bin/digMine.lua',
	'bin/digTunnel.lua',
	'bin/digPit.lua',
	'bin/clear.lua',
	'bin/fill.lua',
	'bin/rc.lua',
	'bin/refuel.lua',

	'lib/libdig.lua',
	'lib/smartslot.lua',
	'lib/terrapin.lua',
}

sort = true
readme = 'readme.md'
format = 'markdown'
style = '!pale'
dir = 'turtle-doc'

project = 'Terrapin'
title = 'Terrapin API Compilation'

description = 'Turtle tools and apis'
full_description = [[
The terrapin API collection is composed of 2 parts: the generic computer set
of APIs and tools and the turtle set of APIs and tools.

This documentation only covers the APIs and tools installed with:

	ac-get install terrapin-turtle

To find out more about the capacties of the core parts of Terrapin
refer to the [documenation](http://www.comkieffer.com/terrapin/ac-get/terrapin-core/turtle-core/).

This part of `terrapin` is almost entirely geared towards digging. You will find
tools to dig pits ([digpit]()) or dig tunnels ([digtunnel]()) as well as flatten
areas ([fill]() and [clear]()).

The most useful API included is the `terrapin` API. It originally started as a
set of better movement functions. Over time it has expanded into inventory
management and inertial movement.

The `libdig` API is a useful helper for digging programs. The `digPit` and
`digTunnel` programs make extensive use of it to enable them to be as efficient
as possible.

Finally, the `smartslot` API allows you to create a virtual slot that abstracts
away the underyling slots. It allows you to create a vrtual slot that has as
many items as you need in it.
]]

