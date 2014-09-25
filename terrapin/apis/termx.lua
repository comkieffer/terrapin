--- Extended terminal API
--
-- @module termx
termx = {}

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