local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets

-- Build event containers with properties set BEFORE parenting (avoids the early-replication footgun).
local Jobs = Instance.new("Folder")
Jobs.Name = "Events"
Jobs.Parent = Assets

local Communication = Instance.new("Folder")
Communication.Name = "Communication"
Communication.Parent = Assets

local UpdateClient = Instance.new("RemoteFunction")
UpdateClient.Name = "UpdateClient"
UpdateClient.Parent = Communication

local SendToClient = Instance.new("RemoteEvent")
SendToClient.Name = "SendToClient"
SendToClient.Parent = Communication

local RemoteClass = require(script.RemoteClass)
local Network = {}

function Network:Invoke(...)
	return UpdateClient:InvokeClient(...)
end

function Network:PostAll(...)
	SendToClient:FireAllClients(...)
end

function Network:Post(...)
	SendToClient:FireClient(...)
end

function Network:Unbind(Job)
	local Existing = Jobs:FindFirstChild(Job)

	if not Existing then
		return
	end

	Existing:Destroy()
end

function Network:Bind(Job, ...)
	self:Unbind(Job)

	return RemoteClass.new(Job, ...)
end

return Network
