--- Python-style list class.
--
-- **Please Note**: methods that change the list will return the list.
-- This is to allow for method chaining, but please note that `ls = ls:sort()`
-- does not mean that a new copy of the list is made. In-place (mutable) methods
-- are marked as returning 'the list' in this documentation.
--
-- See the penlight API guide for further
-- @{http://stevedonovan.github.com/Penlight/api/topics/02-arrays.md.html|discussion}
--
-- See <a href="http://www.python.org/doc/current/tut/tut.html">http://www.python.org/doc/current/tut/tut.html</a>, section 5.1
--
-- **Note**: The comments before some of the functions are from the Python docs
-- and contain Python code.
--
-- Written for Lua version Nick Trout 4.0; Redone for Lua 5.1, Steve Donovan.
--
-- Dependencies: `utils`, `tablex`
-- @author Steve Donovan
-- @module List
-- @pragma nostrip

local tinsert,tremove,concat,tsort = table.insert,table.remove,table.concat,table.sort
local setmetatable, getmetatable,type,tostring,assert,string,next = setmetatable,getmetatable,type,tostring,assert,string,next

local tfind = tablex.find
local write = io.write
local filter,imap,imap2,transform,tremovevalues = tablex.filter,tablex.imap,tablex.imap2,tablex.transform,tablex.removevalues
local tsub = tablex.sub
local function_arg = utils.function_arg
local is_type = utils.is_type
local split = utils.split
local assert_arg = utils.assert_arg
local normalize_slice = tablex._normalize_slice

--[[
module ('pl.List',utils._module)
]]

-- metatable for our list objects
List = {_name='List'}
List.__index = List
List._class = List

--- Create an iterator over a seqence.
-- This captures the Python concept of 'sequence'.
-- For tables, iterates over all values with integer indices.
-- @param seq a sequence; a string (over characters), a table, a file object (over lines) or an iterator function
-- @usage for x in iterate {1,10,22,55} do io.write(x,',') end ==> 1,10,22,55
-- @usage for ch in iterate 'help' do do io.write(ch,' ') end ==> h e l p
function List.iterate(seq)
    if type(seq) == 'string' then
        local idx = 0
        local n = #seq
        local sub = string.sub
        return function ()
            idx = idx + 1
            if idx > n then return nil
            else
                return sub(seq,idx,idx)
            end
        end
    elseif type(seq) == 'table' then
        local idx = 0
        local n = #seq
        return function()
            idx = idx + 1
            if idx > n then return nil
            else
                return seq[idx]
            end
        end
    elseif type(seq) == 'function' then
        return seq
    elseif type(seq) == 'userdata' and io.type(seq) == 'file' then
        return seq:lines()
    end
end
local iter = List.iterate

-- we give the metatable its own metatable so that we can call it like a function!
setmetatable(List,{
    __call = function (tbl,arg)
        return List.new(arg)
    end,
})

local function makelist (t,obj)
    local klass = List
    if obj then
        klass = getmetatable(obj)
    end
    return setmetatable(t,klass)
end

local function is_list(t)
    return getmetatable(t) == List
end

local function simple_table(t)
  return type(t) == 'table' and not is_list(t) and #t > 0
end

function List:_init (src)
    if src then
        for v in iter(src) do
            tinsert(self,v)
        end
    end
end

--- Create a new list. Can optionally pass a table;
-- passing another instance of List will cause a copy to be created
-- we pass anything which isn't a simple table to iterate() to work out
-- an appropriate iterator  @see List.iterate
-- @param t An optional list-like table
-- @return a new List
-- @usage ls = List();  ls = List {1,2,3,4}
function List.new(t)
    local ls
    if not simple_table(t) then
        ls = {}
        List._init(ls,t)
    else
        ls = t
    end

    makelist(ls)
    return ls
end

function List:clone()
    local ls = makelist({},self)
    List._init(ls,self)
    return ls
end

function List.default_map_with(T)
    return function(self,name)
       local f = T[name]
       if f then
          return function(self,...)
             return self:map(f,...)
          end
       else
          error("method not found: "..name,2)
       end
    end
end


---Add an item to the end of the list.
-- @param i An item
-- @return the list
function List:append(i)
  assert(i, "called List:append without specifiing an element to append")
  tinsert(self,i)
  return self
end

List.push = tinsert

--- Extend the list by appending all the items in the given list.
-- equivalent to 'a[len(a):] = L'.
-- @param L Another List
-- @return the list
function List:extend(L)
  assert_arg(1,L,'table')
  for i = 1,#L do tinsert(self,L[i]) end
  return self
end

--- Insert an item at a given position. i is the index of the
-- element before which to insert.
-- @param i index of element before whichh to insert
-- @param x A data item
-- @return the list
function List:insert(i, x)
  assert_arg(1,i,'number')
  tinsert(self,i,x)
  return self
end

--- Insert an item at the begining of the list.
-- @param x a data item
-- @return the list
function List:put (x)
    return self:insert(1,x)
end

--- Remove an element given its index.
-- (equivalent of Python's del s[i])
-- @param i the index
-- @return the list
function List:remove (i)
    assert_arg(1,i,'number')
    tremove(self,i)
    return self
end

--- Remove the first item from the list whose value is given.
-- (This is called 'remove' in Python; renamed to avoid confusion
-- with table.remove)
-- Return nil if there is no such item.
-- @param x A data value
-- @return the list
function List:remove_value(x)
    for i=1,#self do
        if self[i]==x then tremove(self,i) return self end
    end
    return self
 end

--- Remove the item at the given position in the list, and return it.
-- If no index is specified, a:pop() returns the last item in the list.
-- The item is also removed from the list.
-- @param i An index
-- @return the item
function List:pop(i)
    if not i then i = #self end
    assert_arg(1,i,'number')
    return tremove(self,i)
end

List.get = List.pop

--- Return the index in the list of the first item whose value is given.
-- Return nil if there is no such item.
-- @class function
-- @name List:index
-- @param x A data value
-- @param idx where to start search (default 1)
-- @return the index, or nil if not found.


List.index = tfind

--- does this list contain the value?.
-- if the value is a table and any value of the table is in the lsit we 
-- return true.
-- @param x A data value
-- @return true or false
function List:contains(x)
    return tfind(self,x) and true or false
end

function List:containsAny(x)
    for i = 1, #x do
        if tfind(self, x[i]) then
            return true
        end
    end

    return false
end

function List:containsAll(x)
    for i = 1, #x do
        if not tfind(self, x[i]) then
            return false
        end
    end

    return true
end

--- Return the number of times value appears in the list.
-- @param x A data value
-- @return number of times x appears
function List:count(x)
    local cnt=0
    for i=1,#self do
        if self[i]==x then cnt=cnt+1 end
    end
    return cnt
end

--- Sort the items of the list, in place.
-- @param cmp an optional comparison function, default '<'
-- @return the list
function List:sort(cmp)
    if cmp then cmp = function_arg(1,cmp) end
    tsort(self,cmp)
    return self
end

--- return a sorted copy of this list.
-- @param cmp an optional comparison function, default '<'
-- @return a new list
function List:sorted(cmp)
    return List(self):sort(cmp)
end

--- Reverse the elements of the list, in place.
-- @return the list
function List:reverse()
    local t = self
    local n = #t
    local n2 = n/2
    for i = 1,n2 do
        local k = n-i+1
        t[i],t[k] = t[k],t[i]
    end
    return self
end

--- return the minimum and the maximum value of the list.
-- @return minimum value
-- @return maximum value
function List:minmax()
    local vmin,vmax = 1e70,-1e70
    for i = 1,#self do
        local v = self[i]
        if v < vmin then vmin = v end
        if v > vmax then vmax = v end
    end
    return vmin,vmax
end

--- Emulate list slicing.  like  'list[first:last]' in Python.
-- If first or last are negative then they are relative to the end of the list
-- eg. slice(-2) gives last 2 entries in a list, and
-- slice(-4,-2) gives from -4th to -2nd
-- @param first An index
-- @param last An index
-- @return a new List
function List:slice(first,last)
    return tsub(self,first,last)
end

--- empty the list.
-- @return the list
function List:clear()
    for i=1,#self do tremove(self) end
    return self
end

local eps = 1.0e-10

--- Emulate Python's range(x) function.
-- Include it in List table for tidiness
-- @param start A number
-- @param finish A number greater than start; if absent,
-- then start is 1 and finish is start
-- @param incr an optional increment (may be less than 1)
-- @return a List from start .. finish
-- @usage List.range(0,3) == List{0,1,2,3}
-- @usage List.range(4) = List{1,2,3,4}
-- @usage List.range(5,1,-1) == List{5,4,3,2,1}
function List.range(start,finish,incr)
  if not finish then
    finish = start
    start = 1
  end
  if incr then
    assert_arg(3,incr,'number')
    if not utils.is_integer(incr) then finish = finish + eps end
  else
    incr = 1
  end
  assert_arg(1,start,'number')
  assert_arg(2,finish,'number')
  local t = List.new()
  for i=start,finish,incr do tinsert(t,i) end
  return t
end

--- list:len() is the same as #list.
function List:len()
  return #self
end

-- Extended operations --

--- Remove a subrange of elements.
-- equivalent to 'del s[i1:i2]' in Python.
-- @param i1 start of range
-- @param i2 end of range
-- @return the list
function List:chop(i1,i2)
    return tremovevalues(self,i1,i2)
end

--- Insert a sublist into a list
-- equivalent to 's[idx:idx] = list' in Python
-- @param idx index
-- @param list list to insert
-- @return the list
-- @usage  l = List{10,20}; l:splice(2,{21,22});  assert(l == List{10,21,22,20})
function List:splice(idx,list)
    assert_arg(1,idx,'number')
    idx = idx - 1
    local i = 1
    for v in iter(list) do
        tinsert(self,i+idx,v)
        i = i + 1
    end
    return self
end

--- general slice assignment s[i1:i2] = seq.
-- @param i1  start index
-- @param i2  end index
-- @param seq a list
-- @return the list
function List:slice_assign(i1,i2,seq)
    assert_arg(1,i1,'number')
    assert_arg(1,i2,'number')
    i1,i2 = normalize_slice(self,i1,i2)
    if i2 >= i1 then self:chop(i1,i2) end
    self:splice(i1,seq)
    return self
end

--- concatenation operator.
-- @param L another List
-- @return a new list consisting of the list with the elements of the new list appended
function List:__concat(L)
    assert_arg(1,L,'table')
    local ls = self:clone()
    ls:extend(L)
    return ls
end

--- equality operator ==.  True iff all elements of two lists are equal.
-- @param L another List
-- @return true or false
function List:__eq(L)
    if #self ~= #L then return false end
    for i = 1,#self do
        if self[i] ~= L[i] then return false end
    end
    return true
end

--- join the elements of a list using a delimiter. <br>
-- This method uses tostring on all elements.
-- @param delim a delimiter string, can be empty.
-- @return a string
function List:join (delim)
    delim = delim or ''
    assert_arg(1,delim,'string')

    local str = ""
    for i = 1, #self do
        str = str .. tostring(self[i]) .. delim
    end

    return str
end

--- join a list of strings. <br>
-- Uses table.concat directly.
-- @class function
-- @name List:concat
-- @param delim a delimiter
-- @return a string
List.concat = concat

local function tostring_q(val)
    local s = tostring(val)
    if type(val) == 'string' then
        s = '"'..s..'"'
    end
    return s
end

--- how our list should be rendered as a string. Uses join().
-- @see List:join
function List:__tostring()
    return '{'..self:join(',',tostring_q)..'}'
end

--[[
-- NOTE: this works, but is unreliable. If you leave the loop before finishing,
-- then the iterator is not reset.
--- can iterate over a list directly.
-- @usage for v in ls do print(v) end
function List:__call()
    if not self.key then self.key = 1 end
    local value = self[self.key]
    self.key = self.key + 1
    if not value then self.key = nil end
    return value
end
--]]

--[[
function List.__call(t,v,i)
    i = (i or 0) + 1
    v = t[i]
    if v then return i, v end
end
--]]

local MethodIter = {}

function MethodIter:__index (name)
    return function(mm,...)
        return self.list:foreachm(name,...)
    end
end

--- call the function for each element of the list.
-- @param fun a function or callable object
-- @param ... optional values to pass to function
function List:foreach (fun,...)
    if fun==nil then
        return setmetatable({list=self},MethodIter)
    end
    fun = function_arg(1,fun)
    for i = 1,#self do
        fun(self[i],...)
    end
end

function List:foreachm (name,...)
    for i = 1,#self do
        local obj = self[i]
        local f = assert(obj[name],"method not found on object")
        f(obj,...)
    end
end

--- create a list of all elements which match a function.
-- @param fun a boolean function
-- @param arg optional argument to be passed as second argument of the predicate
-- @return a new filtered list.
function List:filter (fun,arg)
    return makelist(filter(self,fun,arg),self)
end

--- split a string using a delimiter.
-- @param s the string
-- @param delim the delimiter (default spaces)
-- @return a List of strings
-- @see utils.split
function List.split (s,delim)
    assert_arg(1,s,'string')
    return makelist(split(s,delim))
end

--- apply a named method to all elements.
-- Any extra arguments will be passed to the method.
-- @param name name of method
-- @param ... extra arguments
-- @return a new list of the results
-- @see pl.seq.mapmethod
function List:mapm (name,...)
    local res = {}
    local t = self
    for i = 1,#t do
      local val = t[i]
      local fn = val[name]
      if not fn then error(type(val).." does not have method "..name,2) end
      res[i] = fn(val,...)
    end
    return makelist(res,self)
end

--- 'reduce' a list using a binary function.
-- @param fun a function of two arguments
-- @return result of the function
-- @see pl.tablex.reduce
function List:reduce (fun)
    return tablex.reduce(fun,self)
end

--- return an iterator over all values.
function List:iter ()
    return iter(self)
end



return List

