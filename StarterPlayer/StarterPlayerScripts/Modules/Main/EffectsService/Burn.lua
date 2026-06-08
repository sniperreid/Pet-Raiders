local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local FX = Assets.FX

local Camera = workspace.CurrentCamera

return function(Target: Model, Time: number)
	if not Target then
		return
	end
	
	if not Target.PrimaryPart then
		return
	end
	
	local VFX = FX.Lightning

	local Burn = VFX.Burn:Clone()

	local Temp = Instance.new("Part")
	Temp.Parent = workspace.Terrain
	Temp.Size = Target:GetExtentsSize() + Vector3.new(2, 2, 2)
	Temp.Anchored = true
	Temp.CanCollide = false
	Temp.Transparency = 1
	Temp.Position = Target.PrimaryPart.Position

	Burn.Parent = Temp

	Debris:AddItem(Temp, Time or 0)
end