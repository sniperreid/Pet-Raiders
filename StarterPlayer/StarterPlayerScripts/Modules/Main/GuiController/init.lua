local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Fusion_Element = require(script.Element)
local Fusion_Flipbook = require(script.Flipbook)
local Fusion_Environment = require(script.Environment)
local Fusion_Viewport = require(script.Viewport)

local Modules = ReplicatedStorage.Modules
local Services = require(Modules.Services)

local SoundService = Services.get("SoundService")
local math = Services.get("MathUtility")

local GlobalRoutines = {}

local Fusion = {}
Fusion.__index = Fusion

function Fusion:Destroy()
	for i, v in self.Elements do
		v:Destroy()
	end
	
	table.clear(self)
end

function Fusion:OrbitElement(Elements, Subject, Radius, OffsetDirection, IntervalDelay)
	
	local Elements = Elements or self.Elements
	
	local NumElements = #Elements
	local CircleArea = 2 * math.pi
	local Radius = Radius or 0.25

	for i, Element in Elements do
		
		if i == 2 then
			i = 1
		elseif i == 1 then
			i = 2
		end
		
		local Offset = tick()
		local Direction = OffsetDirection or 0
		
		local Angle = (i * (CircleArea/NumElements)) + (Offset * Direction)
		
		local x = math.cos(Angle) * Radius
		local z = math.sin(Angle) * Radius
		
		local SubjectObject = ((not Subject:is("Flipbook") and not Subject:is("Environment")) and Subject.Object) or Subject.Content
		
		if not SubjectObject then
			break
		end
		
		local SubjectOrigin = SubjectObject.Position
		local NextPosition = SubjectOrigin + UDim2.fromScale(x/2, z)
		
		Element:Transform(NextPosition, 1)
		
		if IntervalDelay then
			task.wait(IntervalDelay)
		end
	end
end

function Fusion:CreateFlipbook(...)
	return Fusion_Flipbook.new(self, ...)
end

function Fusion:CreateEnvironment(...)
	return Fusion_Environment.new(self, ...)
end

function Fusion:CreateViewport(...)
	return Fusion_Viewport.new(self, ...)
end

function Fusion:CloneElement(Element, ...)
	local NewElement = Element:Clone()
	NewElement.Parent = Element.Parent
	
	return self:BindElement(NewElement, ...)
end

function Fusion:BindElement(Element, ...)
	
	if self.Elements then
		for i, v in self.Elements do
			if v.Object == Element then
				return
			end
		end
	end
	
	local New_Element = Fusion_Element.new(self, Element, ...)

	if self.Elements then
		table.insert(self.Elements, New_Element)
	end
	
	return New_Element
end

function Fusion:CreateElement(ClassName, ...)
	local params = {...}
	local Inst = Instance.new(ClassName)
	
	return function(data)
		for i, v in data do
			Inst[i] = v
		end
		
		return self:BindElement(Inst, unpack(params))
	end
end

function Fusion:CallRoutine(RoutineString, ...)
	return GlobalRoutines[RoutineString](...)
end

function Fusion:CreateRoutine(RoutineString, Routine)
	GlobalRoutines[RoutineString] = Routine
end

function Fusion.new()
	local self = setmetatable({}, Fusion)
	
	self.Elements = {}
	
	return self
end

function Fusion:PlaySound(Sound, Volume)
	return SoundService:PlaySound(Sound, {
		Volume = Volume or 1
	})
end

function Fusion:AnimateUI_Open(Frame, Style, Direction, StartScale, EndScale, AnimationSpeed)
	StartScale = StartScale or 1
	EndScale = EndScale or 0

	local FrameContent = Frame:FindFirstChild("Content") or Frame

	local UIScale = FrameContent:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")

	UIScale.Scale = StartScale

	return TweenService:Create(
		UIScale,
		TweenInfo.new(
			1 / AnimationSpeed,
			Style,
			Direction
		),
		{
			Scale = EndScale
		}
	):Play()
end

Fusion:CreateRoutine("EnterHover", function(Element)
	local Content = Element.Content
	local UIScale = Content.UIScale

	if not Content or not UIScale then
		return
	end

	UIScale:ScaleTo(1.05, .05)
end)

Fusion:CreateRoutine("ExitHover", function(Element)
	local Content = Element.Content
	local UIScale = Content.UIScale

	if not Content or not UIScale then
		return
	end

	UIScale:ScaleTo(1, .05)
end)

Fusion:CreateRoutine("MouseDown", function(Element)
	local Content = Element.Content
	local UIScale = Content.UIScale

	if not Content or not UIScale then
		return
	end

	UIScale:ScaleTo(.97, 1/20)
end)

Fusion:CreateRoutine("MouseUp", function(Element, PlaySound)
	local Content = Element.Content
	local UIScale = Element.UIScale

	if not Content or not UIScale then
		return
	end

	UIScale:ScaleTo(1.05, 1/20)
	
	if not PlaySound then
		return
	end
	
	Fusion:PlaySound("Pop_2", .5)
end)

function Fusion:AnimateShinyGradient(Frame, Settings)

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

	local ShineClipping = Instance.new("CanvasGroup", Frame)
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

	local Connection

	Connection = RunService.RenderStepped:Connect(function()
		local RateTick = (tick() - Start)

		if RateTick < ShineRate then
			return
		end
		
		if not ShineClipping.Parent and Connection then
			Connection:Disconnect()
			Connection = nil
			
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
	end)
end

return Fusion