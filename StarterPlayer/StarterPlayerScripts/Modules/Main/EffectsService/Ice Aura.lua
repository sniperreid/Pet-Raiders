local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local RunService = Services.get("RunService")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local FX = Assets.FX

return function(HumanoidRootPart: Part)
	local Slash = FX["Ice Aura"].IceSlash:Clone()
	Slash.Parent = workspace.Terrain
	
	local Connection = RunService.RenderStepped:Connect(function()
		Slash.CFrame = HumanoidRootPart.CFrame
	end)
	
	local EmitConnection = task.spawn(function()
		for i = 1, 4 do
			for _, Particle in Slash:GetDescendants() do
				if Particle:IsA("ParticleEmitter") then
					Particle:Emit(Particle:GetAttribute("EmitCount") or 1)
				end
			end
			
			task.wait(.5)
		end
	end)
	
	task.delay(3, function()
		Connection:Disconnect()
		Connection = nil
		
		task.cancel(EmitConnection)
		EmitConnection = nil
		
		Slash:Destroy()
		Slash = nil
	end)
end