-------------------------- Framework --------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Player = Players.LocalPlayer
local Mouse = Player and Player:GetMouse()

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local SoundService = Services.get("SoundService")
local MaidClass = Services.get("MaidClass")
local math = Services.get("MathUtility")
local TweenService = Services.get("TweenV2")
local FlipbookModule = Services.get("FlipbookModule")

---------------------- Services ----------------------

local AnimationService = { }

AnimationService.Tasks = { }
AnimationService.ButtonCache = { }
AnimationService.RunningGradients = { }

local ButtonScales = {
	MouseEnter = 1.05,
	MouseLeave = 1,
	MouseButton1Down = 0.97,
	MouseButton1Up = 1.05,
	MouseButton2Down = 0.97,
	MouseButton2Up = 1.05
}

local SpecialScales = {
	KeybindDown = .85,
	KeybindUp = 1
}

local ButtonPositions = {
	MouseButton1Down = {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	},
	
	MouseButton2Down = {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	},

	Default = {
		Size = UDim2.new(1, 0, 0.925, 0),
		Position = UDim2.new(0.5, 0, 0.465, 0)
	},
}

function AnimationService:RenderFlipbook(Button, RegisterAsButton)
	local ButtonContent = Button:FindFirstChild("Content")
	local ButtonIcon = ButtonContent:FindFirstChild("Icon")
	
	if not ButtonIcon then
		return
	end
	
	local FlipbookTitle = Button:GetAttribute("FlipbookTitle")
	local FlipSpeed = Button:GetAttribute("FlipSpeed")
	local FlipDelay = Button:GetAttribute("FlipDelay")
	local FlipColor = Button:GetAttribute("FlipColor")
	
	if not FlipbookTitle then
		return
	end
	
	local FlipbookAnimation = FlipbookModule[FlipbookTitle]
	
	if not FlipbookAnimation then
		return
	end
	
	local FlipSpeed = FlipSpeed or FlipbookAnimation.AnimationSpeed or .1
	local StartDelay = FlipDelay or FlipbookAnimation.StartDelay or 0
	local FlipColor = FlipColor or FlipbookAnimation.Color or Color3.fromRGB(255, 255, 255)
	local StartFlipbook = 0
	local StartDelayTick = 0
	local OriginImage = ButtonIcon.Image
	
	local Connection = RunService.Heartbeat:Connect(function()
		local GuisAtPosition = Player.PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)
		
		if not table.find(GuisAtPosition, Button) and RegisterAsButton then
			ButtonIcon.Image = OriginImage
			
			if ButtonIcon:FindFirstChild("FlipbookIcon") then
				ButtonIcon:FindFirstChild("FlipbookIcon"):Destroy()
			end
			
			return
		end
		
		if (tick() - StartDelayTick) < StartDelay then
			return
		end
		
		if (tick() - StartFlipbook) < FlipSpeed then
			return
		end
		
		StartFlipbook = tick()
		
		local FlipbookAnimation = FlipbookModule[FlipbookTitle]
		local GridSize = FlipbookAnimation.GridSize
		local FlipbookImg = FlipbookAnimation.Image
		
		local FlipbookIcon = ButtonIcon:FindFirstChild("FlipbookIcon")
		
		if not FlipbookIcon then
			FlipbookIcon = ButtonIcon:Clone()
			FlipbookIcon.Name = "FlipbookIcon"
			FlipbookIcon.Parent = ButtonIcon
			FlipbookIcon.AnchorPoint = Vector2.zero
			
			if FlipbookIcon:FindFirstChild("UIAspectRatioConstraint") then
				FlipbookIcon:FindFirstChild("UIAspectRatioConstraint"):Destroy()
			end
		end
		
		FlipbookIcon.ImageColor3 = FlipColor
		
		ButtonIcon.ClipsDescendants = true
		
		FlipbookIcon.Image = FlipbookImg
		ButtonIcon.Image = ""
		FlipbookIcon.Size = UDim2.fromScale(GridSize, GridSize)
		
		local FlipState = FlipbookIcon:GetAttribute("FlipState") or 1
		
		local X = -((FlipState - 1) % GridSize)
		local Y = -math.floor((FlipState - 1) / GridSize)
		
		FlipbookIcon.Position = UDim2.fromScale(
			X,
			Y
		)
		
		FlipState += 1
		
		if FlipState > GridSize^2 then
			FlipState = 0
			
			StartDelayTick = tick()
			FlipbookIcon.Image = FlipbookAnimation.FadeOnEnd and "" or FlipbookIcon.Image
		end
		
		FlipbookIcon:SetAttribute("FlipState", FlipState)
	end)
	
	if self.ButtonCache[Button] then
		self.ButtonCache[Button].Flipbook = Connection
	end
end

function AnimationService:HandleTween(Button, ConnectionType, OriginalScale)
	local ButtonObject = Button:FindFirstChild("Content")
	
	if not ButtonObject then
		return
	end
	
	local ButtonScale = ButtonObject:FindFirstChild("UIScale")
	local ButtonMain = ButtonObject:FindFirstChild("Main")

	if not ButtonObject or not ButtonScale then
		return
	end

	local NewScale = ButtonScales[ConnectionType] or SpecialScales[ConnectionType]
	local PositionInfo = ButtonPositions[ConnectionType] or ButtonPositions.Default

	TweenService:Create(
		ButtonScale,
		TweenInfo.new(0.03, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Scale = OriginalScale * NewScale }
	):Play()

	if not ButtonMain then
		return
	end

	-- TweenService:Create(
	-- 	ButtonMain,
	-- 	TweenInfo.new(0.03, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	-- 	{ Size = PositionInfo.Size, Position = PositionInfo.Position }
	-- ):Play()
end

function AnimationService:CreateButton(Button, Callback)
	local cButton = self.ButtonCache[Button]
	
	if cButton and cButton.MouseButton1 then
		local ButtonObject = Button:FindFirstChild("Content")
		local ButtonScale = ButtonObject:FindFirstChild("UIScale")
		
		if ButtonScale then
			ButtonScale.Scale = 1
		end
		
		for i, Connection in cButton do
			if typeof(Connection) ~= "RBXScriptConnection" then
				continue
			end
			
			Connection:Disconnect()
		end
	else
		self.ButtonCache[Button] = {}
	end
	
	local MouseButton1 = Button.MouseButton1Click:Connect(function()
		SoundService:PlaySound("Pop_2", {Volume = 0.2}); Callback()
	end)

	local MouseEnter = Button.MouseEnter:Connect(function()
		SoundService:PlaySound("Pop_1", {Volume = .1});
	end)

	local ButtonObject = Button:FindFirstChild("Content")

	if not ButtonObject then
		return
	end
	
	self:RenderFlipbook(Button, true)

	local ButtonScale = ButtonObject:FindFirstChild("UIScale")

	local ButtonMeta = self.ButtonCache[Button]
	
	for ConnectionType, _ in ButtonScales do
		if not ButtonScale then
			continue
		end
		
		local OriginalScale = ButtonScale.Scale
		
		ButtonMeta[ConnectionType] = Button[ConnectionType]:Connect(function()
			self:HandleTween(Button, ConnectionType, OriginalScale)
		end)
	end
	
	ButtonMeta.MouseButton1 = MouseButton1
	ButtonMeta.MouseEnter = MouseEnter
	
	Button.Destroying:Once(function()
		for i, Connection in ButtonMeta do
			if typeof(Connection) ~= "RBXScriptConnection" then
				continue
			end

			Connection:Disconnect()
		end
	end)
end

function AnimationService:AnimateUI(Frame, Scale, Rotation)
	local Maid = MaidClass.new()
	
	self:DisconnectAnimation("AnimateUI", Frame)

	Scale = Scale or 0
	Rotation = Rotation or 0

	local FrameContent = Frame:FindFirstChild("Content")

	if not FrameContent then 
		return 
	end

	local UIScale = FrameContent:FindFirstChildOfClass("UIScale")

	local OriginalScale = UIScale.Scale
	local OriginalRotation = FrameContent.Rotation

	local AnimationStart = tick()
	local AnimationSpeed = 3.5

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local AnimationStep = (tick() - AnimationStart) * AnimationSpeed
		
		if AnimationStep >= 1 then
			self.Tasks["AnimateUI"][Frame] = nil

			UIScale.Scale = OriginalScale
			FrameContent.Rotation = OriginalRotation
			
			Maid:Clean()
			
			return
		end

		UIScale.Scale = math.Lerp(
			OriginalScale,
			Scale,
			math.sin(AnimationStep * math.pi)
		)

		FrameContent.Rotation = math.Lerp(
			OriginalRotation,
			Rotation,
			math.sin(AnimationStep * math.pi)
		)
	end))

	self.Tasks["AnimateUI"][Frame] = {
		Revert = function(self)
			UIScale.Scale = OriginalScale
			FrameContent.Rotation = OriginalRotation
		end,
	}
end

function AnimationService:AnimateUI_Open(Frame, Style, Direction, StartScale, EndScale, AnimationSpeed)
	local Maid = MaidClass.new()
	
	self:DisconnectAnimation("AnimateUI_Open", Frame)

	StartScale = StartScale or 1
	EndScale = EndScale or 0

	local FrameContent = Frame:FindFirstChild("Content") or Frame

	local UIScale = FrameContent:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")

	UIScale.Scale = StartScale

	local Tween = TweenService:Create(
		UIScale,
		TweenInfo.new(
			1 / AnimationSpeed,
			Style,
			Direction
		),
		{
			Scale = EndScale
		}
	)

	Maid:GiveTask({
		Play = function(self)
			if not Tween.Play then
				return
			end

			Tween:Play()
		end,
		Destroy = function(self)
			if not Tween.Cancel then
				return
			end

			Tween:Cancel()
			Tween:Destroy()
		end,
	}):Play()

	task.delay(1 / AnimationSpeed, function()
		Maid:Clean()
	end)

	self.Tasks["AnimateUI_Open"][Frame] = {
		Revert = function(self)
			UIScale.Scale = StartScale
		end
	}
end

function AnimationService:AnimateShinyGradient(Frame, Settings)

	if not Settings then
		Settings = {}
	end

	local ShineCount = Settings.ShineCount or 0.35
	local ShineRate = Settings.ShineRate or 0.3
	local ShineSpeed = Settings.ShineSpeed or 0.35
	
	local MinShineRate = ShineRate / 10
	local MaxShineRate = ShineRate * 1.1
	
	local function NewShineRate()
		ShineRate = Random.new():NextNumber(MinShineRate, MaxShineRate)
	end
	
	NewShineRate()

	if self.RunningGradients[Frame] then
		self.RunningGradients[Frame]:Destroy()
	end

	local Maid = MaidClass.new()

	local ShineClipping = Maid:GiveTask(Instance.new("CanvasGroup", Frame))
	ShineClipping.Name = "ShineClipping"
	ShineClipping.BackgroundTransparency = 1
	ShineClipping.ZIndex = 30
	ShineClipping.AnchorPoint = Vector2.one/2
	ShineClipping.Size = UDim2.fromScale(1, 1)
	ShineClipping.Position = UDim2.fromScale(0.5, 0.5)
	ShineClipping.ClipsDescendants = true

	--local UICorner = Instance.new("UICorner", ShineClipping)
	--UICorner.CornerRadius = UDim.new(0.12, 0)

	local ShineUI = script.UI.Shine:Clone()
	ShineUI.Parent = ShineClipping
	ShineUI.Position = UDim2.fromScale(-2, -2)
	ShineUI.Size = UDim2.fromScale(1.25, 1.25)

	local Start = tick()

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local RateTick = (tick() - Start)
		
		if RateTick < ShineRate then
			return
		end

		local Update = (RateTick - ShineRate) * ShineSpeed

		local Origin = math.Lerp(
			-2,
			2,
			Update
		)

		ShineUI.Position = UDim2.fromScale(Origin, Origin)

		if Update >= 1 then
			NewShineRate()
			
			Start = tick()
		end
	end))

	self.RunningGradients[Frame] = {
		Maid = Maid,
		Destroy = function(self)
			self.Maid:Clean()
			
			AnimationService.RunningGradients[Frame] = nil
		end,
	}

	Frame.Destroying:Once(function()
		if not self.RunningGradients[Frame] then
			return
		end
		
		self.RunningGradients[Frame]:Destroy()
	end)
end

function AnimationService:DisconnectAnimation(
	AnimationType,
	Frame
)
	if not self.Tasks[AnimationType] then
		self.Tasks[AnimationType] = {}
	end

	if self.Tasks[AnimationType][Frame] then
		self.Tasks[AnimationType][Frame]:Revert()
		self.Tasks[AnimationType][Frame] = nil
	end
end

return AnimationService