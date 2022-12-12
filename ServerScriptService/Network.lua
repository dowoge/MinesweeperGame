--!strict
local Share = game:GetService('ReplicatedStorage'):WaitForChild('Share')
local ShareToClient = Share.FireClient
local ShareToAllClients = Share.FireAllClients
type callback = (player: Player, ...any) -> (...any)
local listening = {}
local once = {}

function Listen(channel: string, func: callback)
	if not listening[channel] then
		listening[channel]={}
	end
	listening[channel][#listening[channel]+1]=func
end
function Once(channel: string, func: callback)
	if not once[channel] then
		once[channel]={}
	end
	once[channel][#once[channel]+1]=func
end
function Send(channel: string, plr: Player, ...: any)
	ShareToClient(Share,plr,{channel,...})
end
function SendAll(channel: string, ...: any)
	ShareToAllClients(Share,{channel,...})
end

Share.OnServerEvent:Connect(function(plr: Player, data)
	if type(data)~='table' then
		return
	end
	local channel = data[1]
	if type(channel)~='string' then
		return
	end
	if listening[channel] then
		for _,f in next,listening[channel] do
			coroutine.wrap(function()
				f(plr,unpack(data,2))
			end)()
		end
	end
	if once[channel] then
		for index,f in next,once[channel] do
			coroutine.wrap(function()
				f(plr,unpack(data,2))
			end)()
			once[channel][index]=nil
		end
	end
end)
return {Listen=Listen,Once=Once,Send=Send,SendAll=SendAll}