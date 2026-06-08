local Main = game:GetService("MessagingService")
local RunService = game:GetService("RunService")

local GlobalServices = { }

GlobalServices.Jobs = { }

function GlobalServices:Bind(Job, Callback)

	if self.Jobs[Job] then
		return
	end

	local Subcribe = Main:SubscribeAsync(Job, Callback)

	self.Jobs[Job] = Callback

	return self.Jobs[Job]
end

function GlobalServices:Call(Job)
	return self.Jobs[Job]
end

function GlobalServices:Fire(Job, ...)
	Main:PublishAsync(Job, ...)
end

function GlobalServices:Disconnect(Job)
	local MainAsync = self:Call(Job)

	if not MainAsync then
		return
	end

	self.Jobs[Job] = nil
end

return GlobalServices