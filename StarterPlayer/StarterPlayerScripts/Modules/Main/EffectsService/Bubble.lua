local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local FX = Assets.FX

return function(Character, Duration)
	if not Character then return end

	local Bubble = FX.Bubble.Bubble.Attachment:Clone()
	Bubble.Parent = Character:FindFirstChild("HumanoidRootPart")
	
	local Particle = Bubble.ParticleEmitter
	
	Particle.Enabled = false
	Particle.Enabled = true

	Debris:AddItem(Bubble, Duration)
end