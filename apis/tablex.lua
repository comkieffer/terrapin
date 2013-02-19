
--- Extensions to the standard lua table datatype.
--
-- Provides functional style functions (map, reduce, ...) and more pythonic interfaces
--
-- @module tablex
--

tablex = {}

function tablex.compare(t1, t2)
	if #t1 == #t2 then
		for i = 1, #t1 do
			if t1[i] ~= t2 [i] then return false end
		end

		return true
	else
		return false
	end
end


function tablex.copy(src)
	assert_table(1, src)
	
	local dst = {}

	for k,v in pairs(src) do
		dst[k] = v
	end

	return dst
end

function tablex.filter(tbl, pred)
	local res = {}

	for k,v in pairs(tbl) do 
		if pred(v) then res[k] = v end
	end

	return res
end

function tablex.reduce(fn, tbl, init)
  init = init or 0
  local n = #tbl

  local res = init
  for i = 1, n do
    res = fn(res, tbl[i])
  end
end


-- When given a pair of relative indices return the absolute indices
-- @param self the table to which the indices refer
-- @param first the start of the range
-- @param last the end of the range
-- @return a pair of positive indices
function tablex._normalize_slice(self,first,last)
  local sz = #self
  if not first then first=1 end
  if first<0 then first=sz+first+1 end
  -- make the range _inclusive_!
  if not last then last=sz end
  if last < 0 then last=sz+1+last end
  return first,last
end

--- return the index of a value in a list.
-- Like string.find, there is an optional index to start searching,
-- which can be negative.
-- @param t A list-like table (i.e. with numerical indices)
-- @param val A value
-- @param idx index to start; -1 means last element,etc (default 1)
-- @return index of value or nil if not found
-- @usage find({10,20,30},20) == 2
-- @usage find({'a','b','a','c'},'a',2) == 3
function tablex.find(t,val,idx)
    --assert_arg_indexable(1,t)
    idx = idx or 1
    if idx < 0 then idx = #t + idx + 1 end
    for i = idx,#t do
        if t[i] == val then return i end
    end
    return nil
end

--- compare two values.
-- if they are tables, then compare their keys and fields recursively.
-- @param t1 A value
-- @param t2 A value
-- @param ignore_mt if true, ignore __eq metamethod (default false)
-- @param eps if defined, then used for any number comparisons
-- @return true or false
function tablex.deepcompare(t1, t2, ignore_mt, eps)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' then
        if ty1 == 'number' and eps then return abs(t1-t2) < eps end
        return t1 == t2
    end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not deepcompare(v1,v2,ignore_mt,eps) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not deepcompare(v1,v2,ignore_mt,eps) then return false end
    end
    return true
end

return tablex