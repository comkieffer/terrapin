
local terrapin = {}

--- Inertial/Relative Movement stuff
-- @section inertial

local function _update_relative_pos(moveFn)
	local pos  = terrapin.inertial_nav.relative_pos
	local dirs = terrapin.inertial_nav.directions
	local dir  = terrapin.inertial_nav.current_facing_direction

	if moveFn == turtle.up then
		pos.y = pos.y + 1
	elseif moveFn == turtle.down then
		pos.y = pos.y - 1
	else
		if moveFn == turtle.forward then
			if dir == dirs["+x"] then
				pos.x = pos.x + 1
			elseif dir == dirs["-x"] then
				pos.x = pos.x - 1
			elseif dir == dirs["+z"] then
				pos.z = pos.z + 1
			elseif dir == dirs["-z"] then
				pos.z = pos.z - 1
			else
				error ("Unknown direction : " .. dir)
			end
		elseif moveFn == turtle.back then
			if dir == dirs["+x"] then
				pos.x = pos.x - 1
			elseif dir == dirs["-x"] then
				pos.x = pos.x + 1
			elseif dir == dirs["+z"] then
				pos.z = pos.z - 1
			elseif dir == dirs["-z"] then
				pos.z = pos.z + 1
			else
				error ("Unknown direction : " .. dir)
			end
		end
	end
end

--- Enable the inertial movement API
function terrapin.enableInertialNav()
	terrapin.inertial_nav.enabled = true
	terrapin.resetInertialNav()
	terrapin.inertial_nav.initial_pos = terrapin.getPos()
end

--- Disable the inertial movement API
function terrapin.disableInertialNav()
	terrapin.inertial_nav.enabled = false
end

--- Reset the inertial movement API.
-- position and ritation will be reset to their starting values.
function terrapin.resetInertialNav()
	terrapin.inertial_nav.relative_pos = {["x"] = 0, ["y"] = 0, ["z"] = 0}
	terrapin.inertial_nav.current_facing_direction = 0
end

--- Get the turtle's position relative to when the API was last enabled or reset.
function terrapin.getPos()
	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	pos = tablex.copy(terrapin.inertial_nav.relative_pos)
	pos['turn'] = terrapin.inertial_nav.current_facing_direction

	return pos
end

-- Get the direction the turtle is facing
function terrapin.getFacing()
	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	return terrapin.inertial_nav.current_facing_direction
end

--- Turn to face the specfied direction
--
-- Directions can be specified in 2 ways :
-- - As human readable strings : "+x", "-x", "+z", "-z"
-- - As a number indicating the amount of times the turtle should turn right to
-- face that direction.
--
-- @param direction The direction to turn to
function terrapin.turnTo(direction)
	assert(direction)

	if not terrapin.inertial_nav.enabled then
		error('ERROR: Inertial navigation is not enabled')
	end

	local target_dir, turns = 0, 0

	if type(direction) == 'string' then
		if not terrapin.inertial_nav.directions[direction] then
			error('ERROR: "' .. direction ..'" is not a valid direction.' )
		else
			target_dir = terrapin.inertial_nav.directions[direction]
		end
	elseif type(direction) == 'number' then
		target_dir = direction
	end

	-- print('DEBUG: Target dir  : ' ..target_dir)
	-- print('DEBUG: Current dir : ' .. terrapin.inertial_nav.current_facing_direction)

	while terrapin.inertial_nav.current_facing_direction ~= target_dir do
		terrapin.turn()
		-- print('DEBUG: Turning - facing : ' .. terrapin.inertial_nav.current_facing_direction)
	end

	return turns
end

--- Move to the specified postio in the world
--
-- The position shoudl be a table like :
--
-- 		{ ["x"] = 0, ["y"] = 10, ["z"] = 0, ["turn"] = 0 }
--
-- The table specifies the 3 coordinates relative to the turtle :
-- - the 'x' axis extends in front of the turtle
-- - the 'y' axis extends above and below the turtle
-- - the 'z' axis extends to the left and right of the turtle
--
-- The final component 'turn' identifies the direction the turtle should face.
--  @see terrapin.turtTo for more information on this.
--
-- @param position the position to move to
-- @param move_order (option) The order in which to execute the moves
function terrapin.goTo(position, move_order)
	move_order = move_order or {"x", "z", "y"}

	current_pos = terrapin.getPos()

	pos_diff = {
		["x"] = current_pos["x"] - position["x"],
		["y"] = current_pos["y"] - position["y"],
		["z"] = current_pos["z"] - position["z"],
		["turn"] = (position["turn"] - current_pos["turn"]) % 4
	}

	local function goto_y()
		if pos_diff['y'] ~= 0 then
			if pos_diff['y'] > 0 then
				terrapin.digDown(pos_diff['y'])
			else
				terrapin.digUp(-pos_diff['y'])
			end
		end
	end

	local function goto_x()
		if pos_diff['x'] ~= 0 then
			if pos_diff['x'] > 0 then
				terrapin.turnTo('-x')
				terrapin.dig(pos_diff['x'])
			else
				terrapin.turnTo('+x')
				terrapin.dig(-pos_diff['x'])
			end
		end
	end

	local function goto_z()
		if pos_diff['z'] ~= 0 then
			if pos_diff['z'] > 0 then
				terrapin.turnTo('-z')
				terrapin.dig(pos_diff['z'])
			else
				terrapin.turnTo('+z')
				terrapin.dig(-pos_diff['z'])
			end
		end
	end

	for i = 1, #move_order do
		if move_order[i] == 'x' then
			goto_x()
		elseif move_order[i] == 'z' then
			goto_z()
		elseif move_order[i] == 'y' then
			goto_y()
		else
			error('Found invalid move direction : ' .. move_order[i])
		end
	end

	-- turn to face the right direction
	terrapin.turnTo(position["turn"])
end

-- Returns to the position where the inertialNav was initiated and turns to face
-- the right direction
function terrapin.goToStart()
	terrapin.goTo(terrapin.inertial_nav.initial_pos)
end

return terrapin
