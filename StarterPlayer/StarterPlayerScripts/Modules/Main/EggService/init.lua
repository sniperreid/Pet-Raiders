local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local MaidClass = Services.get("MaidClass")
local GuiService = Services.get("GuiService")
local TweenService = Services.get("TweenV2")
local EggModule = Services.get("EggModule")
local PetModule = Services.get("PetModule")
local TextAnimationService = Services.get("TextAnimationService")
local CameraShaker = Services.get("CameraShaker")
local SoundService = Services.get("SoundService")
local PetColorService = Services.get("PetColorService")
local FireworkService = Services.get("FireworkService")
local NumberRender = Services.get("RenderUtil").Number
local math = Services.get("MathUtility")

local EggsFolder = Assets.Eggs
local PetsFolder = Assets.Pets

local Camera = workspace.CurrentCamera
local Terrain = workspace.Terrain

local EggService = {}
local Hatching = false

function EggService:Lerp(a, b, t)
	return a + (b - a) * t
end

function EggService:ToVector2(Vector)
	return Vector2.new(Vector.X, Vector.Z)
end

function EggService:CalculateOffset(EggNumber)
	local HatchInfo = self.HatchInfo
	local Pets = HatchInfo.Pets or {}
	local EggCount = #Pets

	if (EggCount == 6) then
		local HalfCount = EggCount / 2
		local Row = math.floor((EggNumber - 1) / 3)
		local Number = -((HalfCount / 2 - (EggNumber - Row * 3)) / HalfCount + 0.5 / HalfCount)

		local yOffset = Row * 4 - 2
		local zOffset = 0 - (8 + math.abs(Number * 4))

		local BaseOffset = CFrame.new(Number * HalfCount * 3, yOffset, zOffset) * CFrame.Angles(0, math.rad(Number * 20), 0)

		local Z = (EggNumber ~= 2 and EggNumber ~= 5) and (-.5) or (.5)

		BaseOffset = BaseOffset * CFrame.new(0, 0, Z)

		return BaseOffset, Z
	end

	if (EggCount == 5) then
		local TopRow = 2
		local BottomRow = 3
		local Rows = 2

		local Row = (EggNumber <= TopRow) and 0 or 1
		local HalfCount = EggCount / 2

		local Number = (Row == 0) and -((TopRow / 2 - EggNumber) / HalfCount + 0.5 / HalfCount) or -((BottomRow / 2 - (EggNumber - TopRow)) / HalfCount + 0.5 / HalfCount)

		local yOffset = Row * 4 - 2
		local zOffset = 0 - (8 + math.abs(Number * 4))

		local BaseOffset = CFrame.new(Number * HalfCount * 3, yOffset, zOffset) * CFrame.Angles(0, math.rad(Number * 20), 0)

		return BaseOffset, 0
	end

	local Number = -((EggCount / 2 - EggNumber) / EggCount + 0.5 / EggCount)
	local BaseOffset = CFrame.new(Number * EggCount * 3, 0, 0 - (6 + math.abs(Number * 4))) * CFrame.Angles(0, math.rad(Number * 20), 0)

	if (EggCount == 3) then
		local Z = (EggNumber ~= 2) and (-.5) or (.5)

		BaseOffset = BaseOffset * CFrame.new(0, 0, Z)

		return BaseOffset, Z
	end

	return BaseOffset, 0
end

function EggService:GetTimerInfo()
	local HatchInfo = self.HatchInfo
	local Speed = HatchInfo.Speed

	return {
		DropTime = 1 / Speed,
		RotationCount = 20,
		RotateTime = .25 / Speed,
		SwitchTime = .75 / Speed,
		SpinTime = .25 / Speed,
		Millisecond = .1 / Speed
	}
end

function EggService:FinishHatchAnimation()
	local HatchInfo = self.HatchInfo

	if not HatchInfo then
		return self:CleanThread()
	end

	local Pets = HatchInfo.Pets or {}

	self.AnimationIndex += 1

	if self.AnimationIndex >= #Pets then
		Network:Fetch("ToggleInterface", true)

		if HatchInfo.ManualEggHatch then
			GuiService:OpenFrame("InventoryFrame")
		end

		self:CleanThread()
	end
end

function EggService:FixModel(Model)
	for _, base in Model:GetDescendants() do
		if not base:IsA("BasePart") then
			continue
		end

		base.Anchored = true
		base.CanCollide = false
	end
end

function EggService:ApplyParticles(Holder, ParticleTime)
	local HatchInfo = self.HatchInfo

	local Particles = script.Particles
	local ParticleHolder = Particles:FindFirstChild("Legendary")

	if not ParticleHolder then
		return
	end

	HatchInfo.ParticleActive = true

	for _, Object in ParticleHolder:GetChildren() do
		local Particle = Object:Clone()

		Particle.Parent = Holder

		Particle.Enabled = true

		task.delay(ParticleTime or Random.new():NextNumber() / 2, function()
			Particle.Enabled = false
			Debris:AddItem(Particle, 1)
		end)
	end
end

function EggService:PlayHatchAnimation(i)
	local HatchInfo = self.HatchInfo
	local Maid = self.Maid
	local Egg = HatchInfo.Egg
	local Pets = HatchInfo.Pets or {}
	local Speed = HatchInfo.Speed or 0
	local Pet = Pets[i]

	if not Pet then
		return self:FinishHatchAnimation()
	end

	local PetTier = Pet.Tier

	local PetModel = PetsFolder:FindFirstChild(Pet.Name)
	local EggModel = EggsFolder:FindFirstChild(Egg)

	if not PetModel or not EggModel then
		return self:FinishHatchAnimation()
	end

	local TimerInfo = self:GetTimerInfo()

	local DropTime = TimerInfo.DropTime
	local SwitchTime = TimerInfo.SwitchTime
	local RotateTime = TimerInfo.RotateTime
	local SpinTime = TimerInfo.SpinTime
	local Millisecond = TimerInfo.Millisecond

	local PetModel = Maid:GiveTask(PetModel:Clone())
	local EggModel = Maid:GiveTask(EggModel:Clone())

	local UpdatedModel = PetColorService:Update(PetModel, PetTier)

	if UpdatedModel then
		PetModel = UpdatedModel
	end

	PetModel.Name = Pet.Name

	self:FixModel(PetModel)
	self:FixModel(EggModel)

	PetModel.Parent = Terrain
	PetModel:PivotTo(CFrame.new(-1000, -1000, -1000))

	local HatchDisplay = Maid:GiveTask(script.UI.HatchDisplay:Clone())

	for _, Label in HatchDisplay:GetChildren() do
		if not Label:IsA("TextLabel") then
			continue
		end

		Label.TextTransparency = 1
		Label.UIStroke.Transparency = 1
	end

	local PlayerData = Network:Fetch("GetClientData")
	local AutoDelete = PlayerData.AutoDelete or {}

	HatchDisplay.Parent = GuiService.Interface

	local PetData = PetModule[Pet.Name]
	local PetRarity = PetData.Rarity

	local PetLabel = HatchDisplay.PetName
	local RarityLabel = HatchDisplay.PetRarity
	local DeletedLabel = HatchDisplay.Deleted
	local DiscoveredLabel = HatchDisplay.Discovered

	DiscoveredLabel.Visible = Pet.NewPet
	DeletedLabel.Visible = table.find(AutoDelete, Pet.Name) and HatchInfo.from_egg and true or false

	TextAnimationService:AnimateText(DiscoveredLabel, "Shiny")
	DeletedLabel.TextColor3 = Color3.fromRGB(255, 65, 10)

	PetLabel.Text = Pet.Name
	RarityLabel.Text = PetRarity

	TextAnimationService:AnimateText(
		RarityLabel,
		PetRarity
	)

	if PetTier ~= "Normal" then
		PetLabel.UIGradient:Destroy()

		TextAnimationService:AnimateText(
			PetLabel,
			PetTier
		)
	end

	local Start = tick()

	EggModel.Parent = Terrain

	local OffsetCFrame, ZOffset = self:CalculateOffset(i)

	local Positioner = TweenService.new()
	Positioner:changeValue(CFrame.new(0, 5, 0))

	local TargetModels = {
		EggModel
	}

	local PetOffset = CFrame.new(0, -1, 0)
	local AngularOffset = CFrame.Angles(0, math.rad(180), 0)

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		if self.ParticleHolder then
			self.ParticleHolder.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 1, -1)
		end

		for _, Target in TargetModels do
			Target:PivotTo(Camera.CFrame * OffsetCFrame * Positioner.Value * AngularOffset * ((Target == PetModel) and PetOffset or CFrame.new()))
		end

		if not PetModel.PrimaryPart then
			return
		end

		local ScreenPoint = Camera:WorldToViewportPoint(PetModel.PrimaryPart.Position)

		HatchDisplay.Size = UDim2.fromScale(
			0.6 - (ScreenPoint.Z / 10 - 0.6),
			0.6 - (ScreenPoint.Z / 10 - 0.6)
		)

		HatchDisplay.AnchorPoint = Vector2.new(.5, .5)

		if HatchDisplay.AbsoluteSize.Y == 0 then
			return
		end

		HatchDisplay.Position = UDim2.fromOffset(
			ScreenPoint.X,
			ScreenPoint.Y - (#Pets >= 5 and 75 or 100)
		)
	end))

	Positioner:tween(
		TweenInfo.new(
			DropTime,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out
		),
		{
			Value = CFrame.new()
		},
		1
	)

	local Origin = Positioner.Value

	local Start = tick()
	local EggGrowSpeed = 2

	local EggScale = EggModel:GetScale()

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Update = (tick() - Start) / EggGrowSpeed

		if PetRarity ~= "Secret" then
			return
		end

		if Update >= 1 then
			return
		end

		EggModel:ScaleTo(
			self:Lerp(
				EggScale,
				EggScale + .4,
				Update
			)
		)
	end))

	local ShakeInstance = (PetRarity == "Secret") and CameraShaker.new(Enum.RenderPriority.Camera.Value, function(ShakeCFrame)
		Camera.CFrame = Camera.CFrame * ShakeCFrame
	end)

	local Shake = nil

	local FadeTime = (RotateTime * (TimerInfo.RotationCount / 2)) / 2

	local FadeTime = (RotateTime * (TimerInfo.RotationCount / 2)) / 2

	for i = 1, TimerInfo.RotationCount do
		local RotateTime = RotateTime / (i / 2)

		SoundService:PlaySound("Pop_1", 0.2)

		Positioner:tween(
			TweenInfo.new(
				RotateTime,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.Out
			),
			{
				Value = Origin * CFrame.Angles(0, 0, math.rad(((i % 2) - 0.5) * 2 * 20))
			},
			1
		)
	end

	Positioner:tween(
		TweenInfo.new(
			Millisecond,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Value = CFrame.new(0, 0, -5)
		},
		1
	)

	Maid:GiveTask(coroutine.wrap(function()
		if PetRarity == "Secret" then
			task.wait(0.25)
		end

		for i, v in EggModel:GetDescendants() do
			if not v:IsA("BasePart") then
				continue
			end

			local v = TweenService.new(v)

			v:tween(
				TweenInfo.new(
					Millisecond / 2
				),
				{
					Transparency = 1
				}
			)
		end
	end)())

	Origin = CFrame.new(0, 0, 0)

	if PetRarity == "Secret" then
		local Transition = Instance.new("Frame")
		Transition.Parent = GuiService.Interface
		Transition.ZIndex = 9_999
		Transition.BackgroundColor3 = Color3.new(0, 0, 0)
		Transition.Size = UDim2.fromScale(10, 10)
		Transition.Position = UDim2.fromScale(0.5, 0.5)
		Transition.AnchorPoint = Vector2.new(0.5, 0.5)
		Transition.BackgroundTransparency = 1

		TweenService:Create(
			Transition,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine),
			{ BackgroundTransparency = 0 }
		):Play()

		task.wait(0.5)

		local Player = Players.LocalPlayer
		local Character = Player.Character
		local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
		local Head = Character and Character:FindFirstChild("Head")

		if not HumanoidRootPart or not Head then
			return
		end

		local RandomOffset = math.rad(math.random(0, 360))
		local Radius = 12
		local AnglePerEgg = (2 * math.pi) / 8

		local angle = (i - 1) * AnglePerEgg + RandomOffset
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local spawnPos = HumanoidRootPart.Position + direction * Radius + Vector3.new(0, 20, 0)

		local rayOrigin = Vector3.new(spawnPos.X, spawnPos.Y + 5, spawnPos.Z)
		local rayDirection = Vector3.new(0, -10, 0)
		local rayParams = RaycastParams.new()

		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = {workspace.Assets}

		local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

		local groundPos

		if rayResult then
			groundPos = Vector3.new(spawnPos.X, rayResult.Position.Y, spawnPos.Z)
		else
			groundPos = spawnPos - Vector3.new(0, 20, 0)
		end

		local TempEgg = EggsFolder[Egg]:Clone()
		TempEgg.Parent = workspace
		TempEgg:PivotTo(CFrame.new(spawnPos))
		TempEgg:ScaleTo(1.5)

		local Highlight = Instance.new("Highlight")
		Highlight.FillColor = Color3.new(1, 1, 1)
		Highlight.FillTransparency = 1
		Highlight.OutlineTransparency = 1
		Highlight.Parent = TempEgg

		local FallAmount = Instance.new("NumberValue")
		FallAmount.Value = (spawnPos - groundPos).Y
		local ScaleAmount = Instance.new("NumberValue")
		ScaleAmount.Value = 1.5
		local ShakeAmount = Instance.new("NumberValue")
		ShakeAmount.Value = 0

		local OriginalCamPos = Camera.CFrame

		Camera.CameraType = Enum.CameraType.Scriptable
		local camHeight = 2.5
		local camDistance = 15

		local Render = RunService.RenderStepped:Connect(function()
			local camTarget = TempEgg:GetPivot()
			local fromTarget = camTarget * CFrame.new(0, camHeight, camDistance)

			Camera.CFrame = CFrame.new(fromTarget.Position, camTarget.Position)
		end)

		task.wait(0.25)

		TweenService:Create(
			Transition,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine),
			{ BackgroundTransparency = 1 }
		):Play()

		local pos = Instance.new("CFrameValue")

		pos.Value = TempEgg:GetPivot()

		pos:GetPropertyChangedSignal("Value"):Connect(function()
			TempEgg:PivotTo(pos.Value)
		end)

		local DropTime = 1.25

		TweenService:Create(
			pos,
			TweenInfo.new(
				DropTime,
				Enum.EasingStyle.Bounce,
				Enum.EasingDirection.Out
			),
			{ Value = CFrame.new(groundPos) }
		):Play()

		task.delay(DropTime - 0.35, function()
			pos:Destroy()
			
			TweenService:Create(
				ShakeAmount,
				TweenInfo.new(0.25),
				{ Value = 1 }
			):Play()

			task.delay(0.5, function()
				TweenService:Create(
					ShakeAmount,
					TweenInfo.new(0.25),
					{ Value = 0 }
				):Play()
			end)

			for step = 1, 3 do
				local GrowTween = TweenInfo.new((step + 1) / 3, Enum.EasingStyle.Quart)

				TweenService:Create(
					ScaleAmount,
					GrowTween,
					{ Value = ScaleAmount.Value + step / 3 }
				):Play()

				TweenService:Create(
					Highlight,
					GrowTween,
					{ FillTransparency = (step == 3) and 0 or 0.65 }
				):Play()

				if step < 3 then
					task.delay(0.2, function()
						TweenService:Create(
							Highlight,
							GrowTween,
							{ FillTransparency = 1 }
						):Play()
					end)
				end

				task.wait(GrowTween.Time + 0.25)
			end
		end)

		local AnimationStart = tick()

		local Connection = RunService.Heartbeat:Connect(function()
			local dt = tick() - AnimationStart

			local offset = Vector3.new(
				math.noise(dt, 0, 0),
				math.noise(0, dt, 0),
				math.noise(0, 0, dt)
			) * ShakeAmount.Value

			local currentScale = ScaleAmount.Value
			local liftAmount = (currentScale - 1.5) * 3

			local newPos = groundPos + Vector3.new(0, liftAmount, 0) + offset

			TempEgg:PivotTo(CFrame.new(newPos))
			TempEgg:ScaleTo(currentScale)
		end)

		local Flash = Instance.new("Frame")
		Flash.Parent = GuiService.Interface
		Flash.ZIndex = 10_000
		Flash.Size = UDim2.fromScale(10, 10)
		Flash.Position = UDim2.fromScale(0.5, 0.5)
		Flash.AnchorPoint = Vector2.new(0.5, 0.5)
		Flash.BackgroundColor3 = Color3.new(1, 1, 1)
		Flash.BackgroundTransparency = 1

		task.wait(3.5)

		TweenService:Create(
			Flash,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine),
			{ BackgroundTransparency = 0 }
		):Play()

		task.wait(0.6)

		TweenService:Create(
			Flash,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine),
			{ BackgroundTransparency = 1 }
		):Play()

		Connection:Disconnect()
		Render:Disconnect()
		TempEgg:Destroy()
		Highlight:Destroy()
		Flash:Destroy()

		Camera.CameraType = Enum.CameraType.Custom
	end

	for _, Label in HatchDisplay:GetChildren() do
		if not Label:IsA("TextLabel") then
			continue
		end

		local UIStroke = Label:FindFirstChild("UIStroke")

		local Label = TweenService.new(Label)
		local UIStroke = UIStroke and TweenService.new(UIStroke)

		Label:tween(
			TweenInfo.new(
				SwitchTime,
				Enum.EasingStyle.Sine
			),
			{
				TextTransparency = 0
			}
		)

		if not UIStroke then
			continue
		end

		UIStroke:tween(
			TweenInfo.new(
				SwitchTime,
				Enum.EasingStyle.Sine
			),
			{
				Transparency = 0
			}
		)
	end

	Positioner:changeValue(Origin * CFrame.Angles(0, -(45 / 2) / math.pi, 0))

	table.insert(
		TargetModels,
		PetModel
	)

	EggModel.Parent = nil

	local ParticleHideTime = SwitchTime + (i * 0.03) + (SpinTime * 5)
	local ParticleTimer = ParticleHideTime - (ParticleHideTime / 5)

	local ParticleHolder = self.ParticleHolder or Maid:GiveTask(
		Instance.new("Part", workspace.Terrain)
	);

	if ParticleHolder then
		ParticleHolder.Name = "ParticleHolder"
		ParticleHolder.Transparency = 1
		ParticleHolder.Anchored = true
		ParticleHolder.CanCollide = false

		ParticleHolder.Size = Vector3.new(8.74 * 2, 1 * 2, 2 * 2)
	end

	if not HatchInfo.ParticleActive and ParticleHolder then
		if PetRarity == "Legendary" or PetRarity == "Secret" then
			self:ApplyParticles(
				ParticleHolder,
				ParticleTimer
			)

			local Firework = FireworkService.new()
			local Particles = Firework:Explode(
				math.random(3, 10)
			)

			for i, v in Particles do
				local Placeholder = v.Placeholder

				Placeholder.Parent = PetModel
				Placeholder.CFrame = Camera.CFrame * CFrame.new(
					math.random(-15, 15),
					math.random(-5, 5),
					-math.random(2, 7.5)
				)
			end
		end
	end

	self.ParticleHolder = ParticleHolder

	task.delay(ParticleHideTime - 0.5, function()
		Maid:GiveTask(coroutine.wrap(function()
			for i, v in ParticleHolder:GetDescendants() do
				if not v:IsA("ParticleEmitter") then
					continue
				end

				v.Enabled = false
			end
		end)())
	end)

	Positioner:tween(
		TweenInfo.new(
			SpinTime,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Value = Origin
		}
	)

	local RevealFX = Assets.FX.Reveal:Clone()
	RevealFX.CFrame = PetModel:GetPivot()
	RevealFX.CFrame = RevealFX.CFrame * CFrame.new(0, 1, 0)
	RevealFX.Parent = PetModel

	for i, v in RevealFX.Attachment:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

	if Pet.NewPet then
		SoundService:PlaySound("NewSpecies", 0.3)
	end

	SoundService:PlaySound("Sparkle", .5)
	SoundService:PlaySound("Reveal", .2)

	if PetRarity == "Secret" then
		SoundService:PlaySound("Secret", .3)
		SoundService:PlaySound("Magic", .3)
	end

	if PetRarity == "Legendary" or PetRarity == "Secret" then
		SoundService:PlaySound("Legendary", .3)
	end

	local PetScale = PetModel:GetScale()
	local AnimationStart = tick()
	local AnimationSpeed = 3.5

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Update = (tick() - AnimationStart) * AnimationSpeed

		if Update >= 1 then
			return
		end

		PetModel:ScaleTo(
			self:Lerp(
				PetScale,
				PetScale + .1,
				math.sin(Update * math.pi)
			)
		)
	end))

	task.wait(ParticleHideTime)

	task.wait((PetRarity == "Secret") and 2 or 0)

	if Shake then
		Shake:StartFadeOut(FadeTime)

		task.delay(FadeTime, function()
			if not ShakeInstance then
				return
			end

			ShakeInstance:Destroy()
		end)
	end

	task.wait(i / 50)

	Positioner:tween(
		TweenInfo.new(
			SwitchTime,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{
			Value = CFrame.new(0, -12, 0)  * CFrame.Angles(0, 45, 0)
		},
		1
	)

	PetModel:Destroy()

	self:FinishHatchAnimation()
end

function EggService:CleanThread()
	if not self.Maid then
		return
	end

	self.Maid:Clean()

	table.clear(self.Threads)
	table.clear(self.HatchInfo)
	table.clear(self.Maid)

	self.HatchInfo = nil
	self.Threads = nil
	self.AnimationIndex = nil
	self.Maid = nil
	self.ParticleHolder = nil

	Hatching = false
end

function EggService:RunThread(i)
	local Thread = coroutine.wrap(function()
		self:PlayHatchAnimation(i)
	end)

	return Thread, table.insert(self.Threads, Thread)
end

function EggService:HatchEgg(HatchInfo)
	if Hatching then
		repeat task.wait()
		until not Hatching
	end

	self:CleanThread()

	Network:Fetch("ToggleInterface", false)

	Hatching = true

	self.HatchInfo = HatchInfo
	self.Threads = {}
	self.AnimationIndex = 0
	self.Maid = MaidClass.new()

	local Pets = HatchInfo.Pets or {}

	for i = 1, #Pets do
		self:RunThread(i)()
	end
end

function EggService:IsHatching()
	return Hatching
end

Network:Bind("HatchEggClient", function(...)
	EggService:HatchEgg(...)
end)

return EggService