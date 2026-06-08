local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local FX = Assets.FX

return function(Position, Duration)
	local Dome = FX.Heal.Dome:Clone()
	Dome.Parent = workspace.Terrain
	Dome:PivotTo(CFrame.new(Position))
	
	Network:Fetch("PlaySound", "SpawnHeal", {Volume = .45, Parent = Dome})
	
	local AscendTrack = Network:Fetch("PlaySound", "Ascended", {Volume = .6, Parent = Dome.main, Looped = true})
	
	AscendTrack.RollOffMaxDistance = 200

	for i, v in Dome:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
			v.Enabled = true
		end
		
		if v:IsA("Decal") or v:IsA("BasePart") then
			v.Transparency = 1
			TweenService:Create(v, TweenInfo.new(.5), {Transparency = 0}):Play()
		end
		
		if v:IsA("Beam") then
			v.Enabled = false
			v.Enabled = true
		end
		
		if v:IsA("PointLight") then
			v.Enabled = false
			v.Enabled = true
		end
	end
	
	task.delay(Duration, function()
		if AscendTrack then
			TweenService:Create(
				AscendTrack,
				TweenInfo.new(.5),
				{
					Volume = 0
				}
			):Play()
			
			Debris:AddItem(AscendTrack, .6)
		end
		
		if not Dome.Parent then return end
		
		for i, v in Dome:GetDescendants() do
			if v:IsA("ParticleEmitter") then
				v.Enabled = false
			end

			if v:IsA("Decal") or v:IsA("BasePart") then
				TweenService:Create(v, TweenInfo.new(.5), {Transparency = 1}):Play()
			end

			if v:IsA("Beam") then
				v.Enabled = false
			end

			if v:IsA("PointLight") then
				v.Enabled = false
			end
		end
		
		Network:Fetch("PlaySound", "DespawnHeal", {Volume = .45, Parent = Dome})
		
		Debris:AddItem(Dome, 2)
	end)
end