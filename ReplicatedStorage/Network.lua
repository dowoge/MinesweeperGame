--!strict
local Share = game:GetService('ReplicatedStorage'):WaitForChild('Share')
local FireServer = Share.FireServer
type callback = (...any) -> (...any)
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

function Send(channel: string, ...)
	FireServer(Share,{channel,...})
end

Share.OnClientEvent:Connect(function(data)
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
				f(unpack(data,2))
			end)()
		end
	end
	if once[channel] then
		for index,f in next,once[channel] do
			coroutine.wrap(function()
				f(unpack(data,2))
			end)()
			once[channel][index]=nil
		end
	end
end)

return {Listen=Listen,Once=Once,Send=Send}