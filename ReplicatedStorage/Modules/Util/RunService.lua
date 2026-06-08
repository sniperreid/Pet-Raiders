local RS = game:GetService("RunService")

local RunService = {}

function RunService:IsRunning()
	return RS:IsRunning()
end

function RunService:IsServer()
	return RS:IsServer()
end

function RunService:IsClient()
	return RS:IsClient()
end

RunService.RenderStepped = RS.RenderStepped
RunService.Heartbeat = RS.Heartbeat

function RunService:GetRunTime()
	if self:IsServer() then
		return "Server"
	end
	
	return "Client"
end

function RunService:CanRun(Runtime)
	Runtime = not Runtime and "Client" or Runtime
	
	if Runtime == "Server" then
		return self:IsServer()
	end
	
	if not self:IsRunning() then
		return
	end
	
	return self:IsClient()
end

function RunService:Disconnect(Render)
	if not Render then
		return
	end
	
	Render:Disconnect()
	Render = nil
end

function RunService:Render(UpdateTime, Callback)
	local Data = {
		UpdateTime = UpdateTime
	}
	
	local Render
	
	local RunTime = self:GetRunTime()
	local RunType = RunTime == "Server" and "Heartbeat" or "RenderStepped"
	
	local Start = tick()
	
	Render = self[RunType]:Connect(function()
		local Update = (tick() - Start) / Data.UpdateTime

		Update = math.clamp(Update, 0, 1)
		
		coroutine.wrap(
			Callback
		)(
			Update
		)
		
		if Update >= 1 then
			return self:Disconnect(Render)
		end
	end)
	
	return Render, Data
end

return RunService