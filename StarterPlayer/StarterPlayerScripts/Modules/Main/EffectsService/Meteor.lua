local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local FX = Assets.FX

local SoundService = Services.get("SoundService")
local math = Services.get("MathUtility")
local EasyRender = Services.get("RenderUtil").Number

local Camera = workspace.CurrentCamera

local function CreateMarker(position: Vector3, size: number, decay: number)
	local decal = Instance.new("Decal")
	decal.Texture = "rbxassetid://429500449"

	local part = Instance.new("Part")
	part.Size = Vector3.new(size, .1, size)
	part.CFrame = CFrame.new(position)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = workspace.Terrain

	decal.Parent = part
	decal.Face = Enum.NormalId.Top
	decal.Color3 = Color3.fromRGB(255, 255, 255)
	decal.Transparency = 1

	TweenService:Create(
		decal,
		TweenInfo.new(.25),
		{ Transparency = 0 }
	):Play()

	task.delay(decay, function()
		TweenService:Create(
			decal,
			TweenInfo.new(.25),
			{ Transparency = 1 }
		):Play()

		Debris:AddItem(decal, .25)
		Debris:AddItem(part, .25)
	end)
end

return function(SpawnPosition, ImpactPosition, FormingTime, TravelTime, AttackSize)
	local VFX = FX.Meteor

	local Meteor = VFX.Meteor:Clone()
	Meteor.Parent = workspace.Terrain
	Meteor.PrimaryPart.CanCollide = false

	local LookAtCFrame = CFrame.lookAt(SpawnPosition, ImpactPosition)
	Meteor:PivotTo(LookAtCFrame)

	CreateMarker(ImpactPosition, AttackSize, TravelTime + FormingTime)

	SoundService:PlaySound("MeteorFall", 1, Meteor)

	EasyRender.new({
		UpdateSpeed = FormingTime
	}, function(x)
		local NewSize = math.Lerp(
			AttackSize / 4,
			AttackSize,
			x
		)

		Meteor.PrimaryPart.Size = Vector3.new(NewSize, NewSize, NewSize)
	end)

	task.wait(FormingTime)

	EasyRender.new({
		UpdateSpeed = TravelTime
	}, function(x)
		local EasedAlpha = TweenService:GetValue(x, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

		local NewPosition = SpawnPosition:Lerp(ImpactPosition, EasedAlpha)

		local baseCFrame = CFrame.lookAt(NewPosition, ImpactPosition)
		local RotationAngle = x * math.pi * 10

		local FinalCFrame = baseCFrame * CFrame.Angles(0, 0, RotationAngle)

		Meteor:PivotTo(FinalCFrame)

		if x >= 1 then
			local Explosion = VFX.FlameExplosion:Clone()
			Explosion.Parent = workspace.Terrain
			Explosion.Position = ImpactPosition

			for i, v in Explosion:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount") or 20)
				end
			end

			SoundService:PlaySound("MeteorExplosion", .6)

			Debris:AddItem(Meteor, 0.1)
			Debris:AddItem(Explosion, 3)
		end
	end)
end