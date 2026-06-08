local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Communication = Assets:WaitForChild("Communication")
local Events = Assets:WaitForChild("Events")

local Network = {}

Network.Jobs = {}

Network.NetworkingEvent = Communication:WaitForChild("SendToClient")
Network.NetworkFunction = Communication:WaitForChild("UpdateClient")

function Network:Post(Job, ...)
	local Event = Events:FindFirstChild(Job)

	if not Event then
		task.wait(1)

		return self:Post(Job, ...)
	end

	local RemoteEvent = Event:WaitForChild("RemoteEvent")

	return RemoteEvent:FireServer(...)
end

function Network:Invoke(Job, ...)
	local Event = Events:FindFirstChild(Job)
	
	if not Event then
		task.wait(1)
		
		return self:Post(Job, ...)
	end
	
	local RemoteFunction = Event:WaitForChild("RemoteFunction")

	return RemoteFunction:InvokeServer(...)
end

function Network:Bind(Job, Callback)
	self.Jobs[Job] = Callback
end

function Network:Fetch(Job, ...)
	if not self.Jobs[Job] then return end

	return self.Jobs[Job](...)
end

Network.NetworkingEvent.OnClientEvent:Connect(function(Job, ...)
	Network:Fetch(Job, ...)
end)

Network.NetworkFunction.OnClientInvoke = function(Job, ...)
	return Network:Fetch(Job, ...)
end

return Network