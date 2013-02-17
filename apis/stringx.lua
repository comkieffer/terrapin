
stringx = {}


--- does s only contain alphabetic characters?.
-- @param s a string
function stringx.isalpha(s)
    assert_string(1,s)
    return find(s,'^%a+$') == 1
end

--- does s only contain digits?.
-- @param s a string
function stringx.isdigit(s)
    assert_string(1,s)
    return find(s,'^%d+$') == 1
end

--- does s only contain alphanumeric characters?.
-- @param s a string
function stringx.isalnum(s)
    assert_string(1,s)
    return find(s,'^%w+$') == 1
end

--- does s only contain spaces?.
-- @param s a string
function stringx.isspace(s)
    assert_string(1,s)
    return find(s,'^%s+$') == 1
end

--- does s only contain lower case characters?.
-- @param s a string
function stringx.islower(s)
    assert_string(1,s)
    return find(s,'^[%l%s]+$') == 1
end

--- does s only contain upper case characters?.
-- @param s a string
function stringx.isupper(s)
    assert_string(1,s)
    return find(s,'^[%u%s]+$') == 1
end

function stringx.split(input)
	local words, index = List(), 1

	for word in input:gmatch("(%w+)")  do
		words:append(word)
		index = index + 1
	end

	return words
end

--- does string start with the substring?.
-- @param self the string
-- @param s2 a string
function stringx.startsWith(self, s2)
    assert_string(1, self)
    assert_string(2, s2)

    return string.find(self, s2, 1, true) == 1
end

--- does string end with the given substring?.
-- @param s a string
-- @param send a substring 
function stringx.endsWith(self, send)
    assert_string(1, self)
    assert_string(2, send)
    
    return #self >= #send and self:find(send, #self - #send + 1, true) and true or false
end

--- return the 'character' at the index.
-- @param self the string
-- @param idx an index (can be negative)
-- @return a substring of length 1 if successful, empty string otherwise.
function stringx.at(self,idx)
    assert_string(1,self)
    assert_arg(2,idx,'number')
    return self:sub(self,idx,idx)
end

function stringx.import(dont_overload)
    utils.import(stringx,string)
end

function stringx.words(str)
    local words = stringx.split(str)
    local idx = 0

    return function()
        idx = idx + 1
        if idx <= #words then
            return words[idx]
        end

        return nil
    end
end

return stringx