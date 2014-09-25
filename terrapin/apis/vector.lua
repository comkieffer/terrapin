--[[
	Small vector classes
]]

vec2 = {}
vec2.__index = vec2

function vec2.new(x, y)
	local vector = {}
	setmetatable(vector, vec2)

	if x and y then
		assert_number(1, x)
		assert_number(2, y)

		vector.x = x
		vector.y = y
	else
		vector.x = 0
		vector.y = 0
	end

	return vector
end


vec3 = {}
vec3.__index = vec3

function vec3.new(x, y, z)
	local vector = {}
	setmetatable(vector, vec3)

	if x and y and z then
		assert_number(1, x)
		assert_number(2, y)
		assert_number(3, z)

		vector.x = x
		vector.y = y
		vector.z = z
	else
		vector.x = 0
		vector.y = 0
		vector.z = 0
	end

	return vector
end