
--- Text formatting APIs
--
-- @module text

text = {}

--- generate a string of length len composed of char
-- @param len the length of the produdes string
-- @param char the character to repeat
-- @return a 'len' long string composed of 'char'
-- @return an adequately padded copy of the input string
function text.padString(len, char)
	char = char or " "

	assert_int(1, len)
	assert_char(2, char)

	local res = ""
	for i = 1, len do res = res .. char[1] end

	return res
end

--- Add char to the front of the input string until it's length is len
-- @param str the string onto which we append the pad
-- @param len  the target length
-- @param char the character we are using to pad. If char is more than 1 letter long only the first will be used.
-- @return an adequately padded copy of the input string
function text.pad(str, len, char)
	char = char or " "

	assert_string(1, str)
	assert_int(2, len)
	assert_char(3, char)

	return str .. text.padString(len - str:len(), char[1])
end

--- Add char to the back of the input string until it's length is len
-- @param str the string onto which we append the pad
-- @param len the target length
-- @param char the character we are using to pad. If char is more than 1 letter long only the first will be used.
-- @return an adequately padded copy of the input string
function text.padFront(str, len, char)
	char = char or " "

	assert_string(1, str)
	assert_int(2, len)
	assert_char(3, char)

	return text.padString(len - str:len(), char) .. str
end

--- Given a target length cut the input string into lines such that no line is longer than the length
-- @param str the input string
-- @param line_width the maximum length of a line
-- @return an array of lines
function text.wrap(str, line_width)
	local words, line = stringx.split(str), ""
	local lines = {}
	
	for i = 1, #words do
		-- print (string.format("loking at word: %s, (len: %d)", words[i], words[i]:len()))
		if words[i]:len() > line_width then
			error("I should really get down to this")
		elseif string.len(line .. words[i]) >= line_width then
			table.insert(lines, line)
			--print("\t save line :", line)
			line = words[i]
		else
			if line:len() > 0 then
				line = line .. " " .. words[i]
			else 
				line = words[i]
			end
			--print("\t concat:", line)			
		end
	end

	table.insert(lines, line)

	return lines
end
