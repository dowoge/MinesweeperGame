--	// FileName: MessageSender.lua
--	// Written by: Xsitsu
--	// Description: Module to centralize sending message functionality.

local module = {}
--////////////////////////////// Include
--//////////////////////////////////////
local modulesFolder = script.Parent

local Network = require(game:GetService('ReplicatedStorage'):WaitForChild('Network'))

local prefix = '/'

--////////////////////////////// Methods
--//////////////////////////////////////
local methods = {}
methods.__index = methods

function findPlayer(str)
	for _, player in next,game.Players:GetPlayers() do
		if player.Name:lower():find(str:lower()) then
			return player
		end
	end
end

function methods:SendMessage(message, toChannel)
	
	if message:sub(1,1)==prefix then
		-- command
		local args = message:split(' ')
		local command = args[1]:sub(2,#args[1]):lower()
		table.remove(args,1)
		if command == 'setsize' then
			local x,y
			if args[1]:find(',') then
				x,y = args[1]:match('(%d+),(%d+)')
			end
			if type(tonumber(x))=='number' and type(tonumber(y))=='number' then
				return Network.Send('command','setting',{x=tonumber(x),y=tonumber(y)})
			end
		elseif command == 'setmines' or command == 'setbombs' then
			local n = args[1]
			if type(tonumber(n))=='number' then
				return Network.Send('command','setting',{minecount=tonumber(n)})
			end
		elseif command == 'goto' then
			local pstring = args[1]
			if pstring == 'me' then
				return Network.Send('command','goto',{Player=game.Players.LocalPlayer})
			end
			if pstring then
				local player = findPlayer(pstring)
				if player then
					return Network.Send('command','goto',{Player=player})
				end
			end
		elseif command == 'add' then
			local pstring = args[1]
			if pstring then
				local player = findPlayer(pstring)
				if player then
					return Network.Send('command','add',{Player=player})
				end
			end
		elseif command == 'remove' then
			local pstring = args[1]
			if pstring then
				local player = findPlayer(pstring)
				if player then
					return Network.Send('command','remove',{Player=player})
				end
			end
		elseif command == 'walkspeed' or command == 'ws' or command == 'speed' then
			local speed = args[1]
			if speed and type(tonumber(speed))=='number' then
				return Network.Send('command','walkspeed',{Speed=speed})
			end
		elseif command == 'solve' then
			return Network.Send('command','solve')
		elseif command == 'restart' or command == 'r' and #args==0 then
			return Network.Send('command','restart')
		end
	end
	
	self.SayMessageRequest:FireServer(message, toChannel)
end

function methods:RegisterSayMessageFunction(func)
	self.SayMessageRequest = func
end

--///////////////////////// Constructors
--//////////////////////////////////////

function module.new()
	local obj: any = setmetatable({}, methods)
	obj.SayMessageRequest = nil

	return obj
end

return module.new()
