
--[[--
Extended terminal API.

@module termx
]]

local termx = {}
local text = require 'pl.text'
local stringx = require 'pl.stringx'

--- Write str at coordinates (x,y)
-- @param x the x coordinate the text will be written at
-- @param y the y coordinate the text will be written at
-- @param str the string that will be written on the screen
function termx.write(x, y, str)
	assert_int(1, x)
	assert_int(2, y)
	assert_string(3, str)

	term.setCursorPos(x, y)
	term.write(str)
end

-- Print the string to the terminal 1 line at a time.
function termx.page(str)
	width, height = term.getSize()
	lines = stringx.split(text.wrap(str, width), '/n')

	term.clear()
	term.setCursorPos(0, 0)

	local current_line = 0
	while true do
		for i = 1, height - 1 do
			current_line = i + current_line
			print(lines[current_line])

			-- Check that we still have lines to print
			if current_line >= #lines then
				break
			end
		end

		print('Press any key to view next page')
		io.read()
	end
end

return termx

