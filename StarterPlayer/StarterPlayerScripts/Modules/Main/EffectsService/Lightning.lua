local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local FX = Assets.FX

local SoundService = Services.get("SoundService")

local Camera = workspace.CurrentCamera

return function(Pickup: Model)
	if not Pickup then
		return
	end
	
	if not Pickup.PrimaryPart then
		return
	end
	
	local VFX = FX.Lightning
	
	local Impact = VFX.Impact:FindFirstChildOfClass("Attachment"):Clone()
	local Strike = VFX.Strike:FindFirstChildOfClass("Attachment"):Clone()
	local Burn = VFX.Burn:Clone()
	
	local Temp = Instance.new("Part")
	Temp.Parent = workspace.Terrain
	Temp.Size = Pickup:GetExtentsSize() + Vector3.new(2, 2, 2)
	Temp.Anchored = true
	Temp.CanCollide = false
	Temp.Transparency = 1
	Temp.Position = Pickup.PrimaryPart.Position
	
	SoundService:PlaySound("Zap", .25)
	SoundService:PlaySound("Lightning", .45)
	
	Strike.Parent = Temp
	
	for i, v in Strike:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	task.wait(0.1)
	
	Impact.Parent = Temp

	for i, v in Impact:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
	
	Burn.Parent = Temp
	
	Debris:AddItem(Temp, 3)
end