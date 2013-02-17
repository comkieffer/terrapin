
text = {}

-- generate a string of length len composed of char
-- @param len the length of the produdes string
-- @param char the character to repeat
-- @return a 'len' long string composed of 'char'
function text.padString(len, char)
	char = char or " "

	assert_int(1, len)
	assert_char(2, char)

	local res = ""
	for i = 1, len do res = res .. char end

	return res
end

function text.pad(str, len, char)
	char = char or " "

	assert_string(1, str)
	assert_int(2, len)
	assert_char(3, char)

	return str .. text.padString(len - str:len(), char)
end

function text.padFront(str, len, char)
	char = char or " "

	assert_string(1, str)
	assert_int(2, len)
	assert_char(3, char)

	return text.padString(len - str:len(), char) .. str
end

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
