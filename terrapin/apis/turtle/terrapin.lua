
--[[-- A powerful set of extensions to the default turtle API.

This is the meat of the Terrapin API compilation. It enables smart digging (will
dig through gravel and sand fine), inertial navigation, block detection and
smart mining. It also provieds a full abstraction of the turtle API.

To enable terrapin just replace all instances of turtle.* with terrapin.*

Terrapin does not define all the turtle methods but when a user queries a key
that is not in terrapiin the API will look for it in the turtle API.

This means that even if terrapin does not define a method you cans till use  it.
For example  does not have wrappers around the turtle.attack family of
functions but terrapin.attack() will work fine.

@usage
local terrapin = require 'terrapin'
terrapin.dig(3)
terrapin.turnLeft()

@module terrapin
]]

local tablex = require "sanelight.tablex"

local terrapin = (require "config").read "terrapin"

local movement     = require "terrapin.movement"
local inventory    = require "terrapin.inventory"
local exploration  = require "terrapin.exploration"
local inertial_nav = require "terrapin.inertial_nav"

tablex.merge(terrapin, movement)
tablex.merge(terrapin, inventory)
tablex.merge(terrapin, exploration)
tablex.merge(terrapin, inertial_nav)

-- Set the __index function to look for keys that aren't present in the terrapin
-- API in the turtle API. This means that we don't have to play catchup at every
-- release of CC. Any new methods will be found automatically.
setmetatable(terrapin, { ['__index'] = function(self, key)
		if turtle[key] then
			return turtle[key]
		else
			error(key .. " is not a valid method for terrapin")
		end
	end})

return terrapin
