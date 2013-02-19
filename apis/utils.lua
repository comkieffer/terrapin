--- A set of utility function (But you guessed that already.)
--
-- @module utils

utils = {}

--- is the object of the specified type?.
-- If the type is a string, then use type, otherwise compare with metatable
-- @param obj An object to check
-- @param tp String of what type it should be
function utils.is_type (obj,tp)
    if type(tp) == 'string' then return type(obj) == tp end
    local mt = getmetatable(obj)
    return tp == mt
end
--- is the object a number ?
-- @param val the object to check
function utils.isNum(val)
	return utils.is_type(val, "number")
end

--- is the object a string ?
-- @param val the object to check
function utils.isString(val)
	return utils.is_type(val, "string")
end

--- is the object a table ?
-- @param val the object to check
function utils.isTable(val)
	return utils.is_type(val, "table")
end

--- is the object a function ?
-- @param val the object to check
function utils.isFunction(val)
	return utils.is_type(val, "function")
end

--- assert that the given argument is in fact of the correct type.
-- @param n argument index
-- @param val the value
-- @param tp the type
-- @param verify an optional verfication function
-- @param msg an optional custom message
-- @param lev optional stack position for trace, default 2
-- @raise if the argument n is not the correct type
-- @usage assert_arg(1,t,'table')
-- @usage assert_arg(n,val,'string',path.isdir,'not a directory')
function utils.assert_arg (n,val,tp,verify,msg,lev)
    if type(val) ~= tp then
        error(("argument %d expected a '%s', got a '%s'"):format(n,tp,type(val)),lev or 2)
    end
    if verify and not verify(val) then
        error(("argument %d: '%s' %s"):format(n,val,msg),lev or 2)
    end
end

--- assert the common case that the argument is a number.
-- @param n argument index
-- @param val a value that must be a number
-- @param lev optional stack position for trace, default 3
-- @raise val must be a number
function assert_number (n, val, lev)
    lev = lev or 3
    utils.assert_arg(n, val, 'number', nil, nil, 3)
end

--- assert the common case that the argument is an integer.
-- @param n argument index
-- @param val a value that must be a integer
-- @raise val must be a integer
function assert_int (n, val)
    lev = lev or 3
    if (type(val) ~= "number") or (math.ceil(val) ~= val) then
        utils.assert_arg(n, nil, 'integer', nil, nil, 3)
    end
end

--- assert the common case that the argument is a string.
-- @param n argument index
-- @param val a value that must be a string
-- @raise val must be a string
function assert_string (n, val)
    lev = lev or 3
    utils.assert_arg(n, val, 'string', nil, nil, 3)
end

--- assert the common case that the argument is a char.
-- @param n argument index
-- @param val a value that must be a char
-- @raise val must be a char
function assert_char (n, val, lev)
    lev = lev or 3
    if (type(val) ~= 'string') 
        or (val:len() ~= 1) then
        utils.assert_arg(n, val, 'char', nil, nil, 3)
    end
end
--- assert the common case that the argument is a table.
-- @param n argument index
-- @param val a value that must be a table
-- @raise val must be a table
function assert_table (n, val, lev)
    lev = lev or 3
    utils.assert_arg(n, val, 'table', nil, nil, 3)
end
--- assert the common case that the argument is a function. 
-- @param n argument index
-- @param val a value that must be a function
-- @raise val must be a function
function assert_function (n, val, lev)
    lev = lev or 3
    utils.assert_arg(n, val, 'function', nil, nil, 3)
end

-- restricts value to range min -> max by wrapping around the bounds
-- @param value input value
-- @param min minimum value for 'value'
-- @param max value for 'value'
-- @return a number between min and max
function utils.wrap(value, min, max)
    assert_number(1, value)
    assert_number(2, value)
    assert_number(3, value)

    if value > max then
        local overflow = value - max 
        value = min + overflow
    elseif value < min then
        local underflow = min - value
        value = max - underflow
    end

    return value
end

local function import_symbol(T,k,v,libname)
    local key = rawget(T,k)
    -- warn about collisions!
    if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
        utils.printf("warning: '%s.%s' overrides existing symbol\n",libname,k)
    end
    rawset(T,k,v)
end

local function lookup_lib(T,t)
    for k,v in pairs(T) do
        if v == t then return k end
    end
    return '?'
end

local already_imported = {}

--- take a table and 'inject' it into the local namespace.
-- @param t The Table
-- @param T An optional destination table (defaults to callers environment)
function utils.import(t,T)
    T = T or _G
    t = t or utils
    if type(t) == 'string' then
        t = require (t)
    end
    local libname = lookup_lib(T,t)
    if already_imported[t] then return end
    already_imported[t] = libname
    for k,v in pairs(t) do
        import_symbol(T,k,v,libname)
    end
end

--- Dump the contents of a table to stdout.
-- Warning : this function will choke on any non-textual datatypes (eg: functio, table, ...). 
-- It will choke even more horribly on recursive tables.
-- @param tbl The table to dump
function utils.dump(tbl)
    for k,v in pairs(tbl) do
        print (k, " : ", v)
    end
end
