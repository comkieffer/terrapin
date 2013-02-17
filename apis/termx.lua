
termx = {}

function termx.write(x, y, str)
	assert_int(1, x)
	assert_int(2, y)
	assert_string(3, str)

	term.setCursorPos(x, y)
	term.write(str)
end