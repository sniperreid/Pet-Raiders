local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage.Assets

local Jobs = Assets.Events

local RemoteClass = {}
RemoteClass.__index = RemoteClass

function RemoteClass:CompleteAction(...)
	local Callback = self.Callback

	if not Callback then
		return
	end

	-- Wrap exploit-facing input in pcall — see "Wrap untrusted callbacks in pcall so one bad payload
	-- can't kill the listener chain" in the coding rules.
	local Ok, ResultOrErr = pcall(Callback, ...)

	if not Ok then
		warn(("[Network:%s] handler errored: %s"):format(self.Job, tostring(ResultOrErr)))
		return
	end

	return ResultOrErr
end

function RemoteClass:CreateEvent()
	local Event = self.RemoteEvent
	local Function = self.RemoteFunction

	Event.OnServerEvent:Connect(function(...)
		self:CompleteAction(...)
	end)

	Function.OnServerInvoke = function(...)
		return self:CompleteAction(...)
	end

	return self
end

function RemoteClass.new(Job, Callback)
	local Folder = Instance.new("Folder")
	Folder.Name = Job
	Folder.Parent = Jobs

	local RemoteEvent = Instance.new("RemoteEvent")
	RemoteEvent.Parent = Folder

	local RemoteFunction = Instance.new("RemoteFunction")
	RemoteFunction.Parent = Folder

	local self = setmetatable({}, RemoteClass)

	self.Job = Job
	self.Folder = Folder
	self.RemoteEvent = RemoteEvent
	self.RemoteFunction = RemoteFunction
	self.Callback = Callback

	return self:CreateEvent()
end

return RemoteClass
