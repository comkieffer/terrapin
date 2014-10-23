
file = {
	'terrapin/apis',
	'terrapin/programs',

	exclude = {
		'terrapin/apis/pl', 'terrapin/installer_cfg.lua',
	},
}


sort = true
readme = 'readme.md'
format = 'markdown'
style = '!pale'

project = 'Terrapin'
title = 'Terrapin API Compilation'

description = 'An OS for computercraft turtles.'
full_description = [[
Terrapin is a set of utilities and APIs that provide better tools
than included in the standard turtle distribution for my uses of
turtles.

This includes mining (see the DigMine, DigTunnel and DigPit tools)
and farming (see the TreeFarm and Farm tools).

The main feature of Terrapin is the terrapin API, a set of higher
level primitives to operate your turtles. It includes safe digging
commnds. position tracking, inventory management and some automatic
mining tools. 

A more complete introduction to available tools and APIs can be found
@{readme.md|here}.
]]

