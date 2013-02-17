

--[[
	Network operation :

	when a computer wants to connect to the network it sends a discovery packet
	to identify repeaters in range (atm we will have at most 1 repeater)
		packet : {"tnet_repeater_find"} (broadcast)
	After sending the packet the computer will wait for an answer :
		packet : {"ack"}
	Once a repeater is found the computer will register with the repeater :
		packet : {"tnet_repeater_register computer_label computer id"}
	Registration allows other computers to communicate with that computer using it's 
	label and not its id fr readability.

	From that point on all communication will be done via rednet.send and not braodcast.
		packet : {["dest"] = "label", ["msg"] = " ... "}
	Packets will be acknowledged by the router. All non acknowledged packets are to be 
	considered lost.
]] 

tnet = {
	["repeater_id"] = -1,

	-- functions are simply passed through
	["receive"] = rednet.receive,
} 

-- Opens a connection with the modem,
-- Finds a repeater
-- registers with the repeater before handing back controle to the caller
function tnet.init(silent)
	-- check that the computer has an id 
	if not os.getComputerId() then
		error("[tnet] The computer must have an id in order to take part in tnet")
	end

	-- find a modem 
	local sides, modem_side = rs.getSides(), ""
	for _, side in ipairs(sides) do
		if peripheral.getType(side) == "modem" then
			modem_side = side
			break
		end
	end

	if modem_side == "" then
		error("[tnet] Unable to find modem on computer")
	end

	-- open the modem 
	rednet.open(modem_side)

	if not rednet.isOpen(modem_side) then
		error("[tnet] Unable to open modem on side : " .. modem_side)
	end

	-- find a repeater
	rednet.broadcast(unpickle({["body"] = "tnet_repeater_find"}))

	--wait for confirmation
	local acked, repeater_id = tnet.waitAck()
	if acked then
		tnet.repeater_id = repeater_id
	else
		error("[tnet] Failed to contact repeater")
	end

	-- register with the repeater
	rednet.send(tnet.repeater_id, pickle({
		["body"] = "tnet_repeater_register " .. os.getComputerLabel() .. " " .. os.getComputerId() 
	}))
	if not tnet.waitAck() then
		error("[tnet] Repeater Failed to confirm registration")
	end

	-- registration complete
	return true
end

function tnet.waitAck(timeout)
	timeout = timeout or 30
	local repeater_id, msg = rednet.receive(30)

	local msg_u, res = unpickle(msg), false
	if msg_u.body and msg_u.body == "ack" then
		res = true
	end

	return res, repeater_id
end

function tnet.send(receiver, msg_body)
	if tnet.repeater_id ~= -1 then
		rednet.send(tnet.repeater_id, pickle({
			["dest"] = receiver,
			["body"] = msg_body
		}))

		if not tnet.waitAck() then
			return false
		else 
			return true
		end
	else
		error("[tnet] Tnet must be initialised. Use tnet.init()")
	end
end
