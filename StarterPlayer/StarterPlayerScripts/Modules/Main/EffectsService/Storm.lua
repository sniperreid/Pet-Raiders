local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local FX = Assets.FX

Network:Bind("PlayEffectStormCharge", function(Pickup)
	if not Pickup or not Pickup.PrimaryPart then return end

	local Explosion = FX.Storm.PurpleExplosion:Clone()
	Explosion.Parent = workspace.Terrain
	Explosion.Position = Pickup.PrimaryPart.Position
	
	for _, Particle in Explosion:GetDescendants() do
		if Particle:IsA("ParticleEmitter") then
			if Particle.Parent.Name ~= "Charging" then continue end
			
			Particle:Emit(Particle:GetAttribute("EmitCount") or 1)
		end
	end
	
	local Highlight = Instance.new("Highlight")
	Highlight.Parent = Pickup
	Highlight.FillColor = Color3.fromRGB(250, 108, 255)
	
	TweenService:Create(Highlight, TweenInfo.new(1.5), {FillTransparency = 1}):Play()
	TweenService:Create(Highlight, TweenInfo.new(1.5), {OutlineTransparency = 1}):Play()

	Debris:AddItem(Highlight, 3)
end)

Network:Bind("PlayEffectStormExplode", function(Position)
	local Explosion = FX.Storm.PurpleExplosion:Clone()
	Explosion.Parent = workspace.Terrain
	Explosion.Position = Position

	for _, Particle in Explosion:GetDescendants() do
		if Particle:IsA("ParticleEmitter") then
			if Particle.Parent.Name == "Charging" then continue end
			
			Particle:Emit(Particle:GetAttribute("EmitCount") or 1)
		end
	end

	Debris:AddItem(Explosion, 3)
end)

return function()
	
end