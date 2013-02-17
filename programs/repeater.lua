
--[[
	Remeber to make the turtle check that it has enough fuel for at least a 2 way 
	journey to it's holding altitude
]]

local args = { ... }
local usage = [[

]]

local cmdLine = lapp(usage, args)

-- what happens if the file doesn't exist ?
local id_table = config.load("tnet_repeater")


function ack(id)
	rednet.send(sender_id, "ack")
end

local special_messages {
	["tnet_repeater_find"] = function(sender_id)
		ack()
	end
	["tnet_repeater_register"] = function(sender_id, msg_words)
		if #msg_words >= 2 then
			id_table[msg_words[2]] = id
			config.save("tnet_repeater", id_table)
			ack(sender_id)
		else
			print("Err: " .. sender_id .. " attempted to register with insuficient number of arguments")
		end
	end
	["tnet_return"] = function() 
		while not terrapin.detectDown() do
			terrapin.down()
		end
	end
	["get_table"] = function(sender_id)
		rednet.send(sender_id, pickle({id_table}))
	end
}

if not turtle
	error("Needs to be a turtle.")
end

while true do
	local sender_id, msg_packed = os.pullEvent("rednet")
	print ("New Message : ")
	print (msg_packed)
	print ("==========================================")

	local msg_u = unpickle(msg_packed)

	-- extract the first word of the message and check wether it's a command :
	local msg_words = msg_u.body:split()
	if special_messages[msg_words[1]] then
		special_messages[msg_words[1]](sender_id, msg_words)
	else
		-- not a special message, forward it
		if msg_u.dest and id_table[msg_u.dest] then
			rednet.send(id_table[msg_u.dest], msg_u.body)
		else
			print "Err: Invalid Message"
		end
	end
end
