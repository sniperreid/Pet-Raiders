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

return function(Origin, Destination, FormingSpeed, FlyingSpeed, AttackSize)
	local VFX = FX.Fireball
	
	local Fireball = VFX.Fireball:Clone()
	Fireball.Parent = workspace.Terrain
	Fireball.CanCollide = false
	
	local Attachment = Fireball.Attachment
	
	local NewOrigin = CFrame.new(Origin.Position + Vector3.new(0, 20, 0))
	
	Fireball.CFrame = NewOrigin
	
	SoundService:PlaySound("Fireball", .45)
	
	CreateMarker(Destination, AttackSize, 1)
	
	EasyRender.new({
		UpdateSpeed = FormingSpeed
	}, function(x)
		local NewSize = math.Lerp(
			AttackSize / 3,
			AttackSize,
			x
		)
		
		Fireball.Size = Vector3.new(
			NewSize,
			NewSize,
			NewSize
		)
		
		Attachment.Fire.Transparency = NumberSequence.new {
			NumberSequenceKeypoint.new(0, 1 - x),
			NumberSequenceKeypoint.new(1, 1)
		}
		
		Fireball.Flames.Transparency = NumberSequence.new (1 - x)
		Fireball.Specs.Transparency = NumberSequence.new (1 - x)
	end)
	
	task.wait(FormingSpeed)
	
	--[[
	EasyRender.new({
		UpdateSpeed = FlyingSpeed
	}, function(x)
		local NewPivot = NewOrigin:Lerp(
			CFrame.new(Destination),
			x
		)
		
		Fireball.CFrame = NewPivot
	end)
	]]
	
	local p0 = Origin.Position + Vector3.new(0, 20, 0)
	local p2 = Destination
	local mid = (p0 + p2) / 2
	local p1 = mid + Vector3.new(0, 50, 0)
	
	local arc = (p0 - p1).Magnitude + (p1 - p2).Magnitude
	local travel = arc / 120
	
	EasyRender.new({
		UpdateSpeed = travel
	}, function(x)
		local pos = math.QuadBezier(x, p0, p1, p2)
		local dir = (math.QuadBezier(math.min(x + 0.01, 1), p0, p1, p2) - pos).Unit

		Fireball.CFrame = CFrame.lookAt(pos, pos + dir)

		if x >= 1 then
			local DestructionSpeed = (FormingSpeed * 10) / math.pi

			EasyRender.new({
				UpdateSpeed = DestructionSpeed
			}, function(d)
				local FinalSize = d * AttackSize * math.pi * 2

				Fireball.Size = Vector3.new(FinalSize, FinalSize, FinalSize)

				Attachment.Fire.Transparency = NumberSequence.new {
					NumberSequenceKeypoint.new(0, d),
					NumberSequenceKeypoint.new(1, 1)
				}

				Fireball.Flames.Transparency = NumberSequence.new(d)
				Fireball.Specs.Transparency = NumberSequence.new(d)
			end)
			
			Debris:AddItem(Fireball, DestructionSpeed + .1)
			
			local Explosion = VFX.Explosion:Clone()
			Explosion.Parent = workspace.Terrain
			Explosion.Position = pos
			
			for i, v in Explosion:GetDescendants() do
				if v:IsA("ParticleEmitter") then
					v:Emit(v:GetAttribute("EmitCount"))
				end
			end
			
			SoundService:PlaySound("Puff", .45)
			
			Debris:AddItem(Fireball, DestructionSpeed + .1)
			Debris:AddItem(Explosion, DestructionSpeed + 1)
		end
	end)
end