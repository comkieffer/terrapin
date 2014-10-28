
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
	-- assert_int(1, x)
	-- assert_int(2, y)
	-- assert_string(3, str)

	term.setCursorPos(x, y)
	term.write(str)
end

--- TODO
function termx.write_colored(str, fg_color, bg_color)
	bg_color = bg_color or colors.black

	term.setBackgroundColor(bg_color)
	term.setTextColor(fg_color)
	term.write(str .. '\n')
end

--- TODO
function termx.reset_color()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
end

--- Wrap a block of text
--
-- @param str     The string to wrap
-- @param limit   The maximum length of inidividual lines
-- @param indent  How far should the lines be indented
-- @param indent1 How much should the first line be indented
--
-- @return a wrapped string
--
-- @note The indent and indent1 parameters are string. To indent a string 4
--       spaces you would call it with indent = "    "
--
-- shamelessly lifted from the lua users wiki at :
-- 	http://lua-users.org/wiki/StringRecipes
-- See section : Text Wrapping
function termx.wrap( str, limit, indent, indent1 )
	local width, _ =  term.getSize()
	local limit = limit or width
	local indent = indent or ""
	local indent1 = indent1 or indent

	local function wrap_block(block)
		local here = 1 - #indent1
		-- quick pattern ref :
		--	() is an empty capture it returns the current string position.
		--	(%s+)() capture aone or more whitespace characters, return them and
		--	        return the current string position.
		--	(%S+)() capture one or more non-space characters and return them and
		--	        return the current string position
	   return indent1..block:gsub( "(%s+)()(%S+)()",
		  function( space, start, word, word_end )
			 if word_end-here > limit then
				here = start - #indent
				return "\n" .. indent .. word
			 end
		  end )
	end

	return str:gsub('([^\n]+)', wrap_block)
end


-- Print the string to the terminal 1 line at a time.
function termx.page(str)
	local function draw_toolbar()
		local prev_cursor_x, prev_cursor_y = term.getCursorPos()
		local width, height = term.getSize()

		term.setCursorPos(1, height)
		termx.write_colored(' Pager - <q> to exit, UP/DOWN browse ', colors.gray, colors.white)

		-- some debug info :

		-- reset terminal settings
		termx.reset_color()
		term.setCursorPos(prev_cursor_x, prev_cursor_y)
	end

	local wrapped_str = termx.wrap(str)
	local lines = stringx.split(wrapped_str, '\n')
	local _, term_height = term.getSize()

	term.clear()
	term.setCursorPos(0, 0)

	local current_line = 0
	while true do
		term.clear()
		term.setCursorPos(0, 0)

		for i = 1, term_height do
			print(lines[current_line + i])

			-- Check that we still have lines to print
			if current_line >= #lines then
				break
			end
		end

		draw_toolbar()

		-- process keyboard events :
		local event, key = os.pullEvent('key')

		-- KeyUp move text up
		if key == 200 then
			current_line = math.max(0, current_line - 1)

		-- keyDown, Move down but make sure to keep som of the text on screen.
		elseif key == 208 then
			current_line = math.min(#lines - 5, current_line + 1)

 		-- ESC -- abort
		elseif keys.getName(key) == 'q' then
			break
		end
	end

	-- put the cursor on a new line before exiting
	print()
end

return termx

