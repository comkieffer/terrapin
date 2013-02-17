
mathx = {}

function mathx.wrap(value, lower_bound, upper_bound)
	local lower = math.min(lower_bound, upper_bound)
	local upper = math.max(lower_bound, upper_bound)
	local range = lower - upper + 1

	local remainder = (value - lower) % range

	if remainder < lower then
		return upper + 1 + remainder
	else
		return lower + remainder
	end
end 