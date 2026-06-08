-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Player = Players.LocalPlayer

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local Images = Services.get("ImageModule")
local math = Services.get("MathUtility")
local GuiService = Services.get("GuiService")
local SoundService = Services.get("SoundService")
local Network = Services.get("Network")

---------------------- Services ----------------------

local RNG = Random.new()
local Range = 40

local function GetPivot(Character)
	local Origin = CFrame.new()
	local Character = Character or Player.Character

	if not Character then
		return Origin
	end

	if not Character.PrimaryPart then
		return Origin
	end

	return Character:GetPivot()
end

local function GetPoints(Character, Origin)
	local Range = Range * ((GetPivot(Character).Position - Origin).Magnitude / 50)
	local Offset = {
		RNG:NextNumber(
			-Range/2,
			Range/2
		),
		RNG:NextNumber(
			0,
			Range/2
		),
		RNG:NextNumber(
			-Range/2,
			Range/2
		)
	}

	local Offset1 = Vector3.new(unpack(Offset))

	local P1 = Origin
	local P2 = Origin + Offset1

	return {P1, P2}
end

local function PlayEffect(Origin, ProjectileSettings)
	Range = ProjectileSettings.Range or Range

	local StartDelay = ProjectileSettings.StartDelay or 0
	local Currency = ProjectileSettings.Currency or "Clicks"
	local Amount = ProjectileSettings.Amount or 0
	local PlayCurrencyEffect = ProjectileSettings.PlayCurrencyEffect or true
	local Character = ProjectileSettings.Character or Players.LocalPlayer.Character
	local VFXLighting = ProjectileSettings.HasLighting
	local UpdateSpeed = ProjectileSettings.AnimationSpeed or 1.5
	
	local Rotation = RNG:NextNumber(0, 5)

	local Connection
	local Start = tick()

	local Points = GetPoints(Character, Origin)
	local FXPart = script.FX:Clone()
	local BillboardGui = FXPart.BillboardGui
	local ImageLabel = BillboardGui.ImageLabel
	FXPart.PointLight.Enabled = VFXLighting

	FXPart.Parent = workspace
	BillboardGui.Enabled = true
	ImageLabel.Image = Images(Currency)
	
	local Origin = Points[1]

	Connection = RunService.RenderStepped:Connect(function()
		ImageLabel.Rotation = tick() * Rotation
		local Update = ((tick() - Start) / UpdateSpeed) - StartDelay
		local i = math.clamp(Update, 0, 1)
		
		if Update < 0 then
			Origin = Vector3.new(
				Points[1].X + (math.cos(tick() * 4) * 1),
				Points[1].Y + (StartDelay*(1/60))+.1, -- + math.abs(math.sin(tick() * 4) * 1),
				Points[1].Z + (math.sin(tick() * 4) * .5)
			)
			
			FXPart.Position = Origin
		else
			FXPart.Position = math.QuadBezier(
				i,
				Origin,
				Points[2],
				GetPivot(Character).Position
			)
		end

		if i >= 1 then
			Connection:Disconnect()
			Connection = nil

			FXPart:Destroy()

			if not PlayCurrencyEffect then
				return
			end
			
			if Players.LocalPlayer.Character ~= Character then
				return
			end
			
			SoundService:PlaySound("Pop_1", {
				Volume = .25
			})
			
			Network:Fetch("PlayEffectDisplayCurrency", Currency, math.round(Amount))
		end
	end)
end

return function(Origin, ProjectileSettings)
	coroutine.wrap(function()
		local EmitCount = ProjectileSettings.EmitCount or 1
		local EmitTime = ProjectileSettings.EmitTime
		
		for i = 1, EmitCount do
			PlayEffect(Origin, ProjectileSettings)
			
			if not EmitTime then
				continue
			end
			
			task.wait(EmitTime)
		end
	end)()
end