local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage.Modules
local Utility = Modules.Util

local MaidClass = require(Utility.MaidClass)
local Fusion = script.Parent

local Fusion_Element = require(Fusion.Element)

local Environment = {}
Environment.__index = Environment

function Environment:Destroy()
	if self.Maid then
		self.Maid:Clean()
	end

	table.clear(self)
end

function Environment:GetWorldOffsetFromMouse()
	
	local Content = self.Content

	local Strength = self.SpriteData.GuiStrength or 200
	local delta = .1
	
	local mouseLocation = UserInputService:GetMouseLocation()
	local screenSize = workspace.CurrentCamera.ViewportSize
	
	local AbsoluteContentSize = Content.AbsoluteSize
	local AbsoluteRatio = screenSize/AbsoluteContentSize
	
	local Size_X = math.clamp(AbsoluteRatio.X*1.5, 1, 3)
	local Size_Y = math.clamp(AbsoluteRatio.Y*1.5, 1, 3)

	self.Object.Size = UDim2.fromScale(Size_X, Size_Y)

	local Offset = (mouseLocation - (screenSize / 2)) / (screenSize / 2)
	local NextOffset = -UDim2.new(.5, Offset.X * Strength, .5, Offset.Y * Strength)

	local Next_X = NextOffset.X
	local Next_Y = NextOffset.Y

	local targetPosition = Content.Position
	
	local Target_X = targetPosition.X
	local Target_Y = targetPosition.Y

	return UDim2.new(
		Target_X.Scale + (Next_X.Scale - Target_X.Scale) * delta,
		Target_X.Offset + (Next_X.Offset - Target_X.Offset) * delta,
		Target_Y.Scale + (Next_Y.Scale - Target_Y.Scale) * delta,
		Target_Y.Offset + (Next_Y.Offset - Target_Y.Offset) * delta
	)
end

function Environment:CreateContent()
	local SpriteData = self.SpriteData
	local ImageID = SpriteData.ID
	local Position = SpriteData.Position
	local Size = SpriteData.Size
	
	local Content = self.Maid:GiveTask(Instance.new("Frame", self.Parent))
	Content.AnchorPoint = Vector2.one/2
	Content.Size = Size
	Content.Position = Position
	Content.BackgroundTransparency = 1
	Content.Name = "EnvironmentContainer::" .. ImageID
	
	local Icon = Instance.new("ImageLabel", Content)
	Icon.AnchorPoint = Vector2.one/2
	Icon.Position = UDim2.fromScale(.5, .5)
	Icon.Size = UDim2.fromScale(1.5, 1.5)
	Icon.BackgroundTransparency = 1
	Icon.Name = "Icon"
	Icon.Image = ImageID

	self.Content = Content
	self.Object = Icon
end

function Environment:init()
	self:CreateContent()
	
	self.is = Fusion_Element.is

	self.CreateTween = Fusion_Element.CreateTween
	self.PlayTween = Fusion_Element.PlayTween

	self.Transform = Fusion_Element.Transform
	self.RotateTo = Fusion_Element.RotateTo
	self.ChangeOpacity = Fusion_Element.ChangeOpacity
	self.ChangeDisplayOrder = Fusion_Element.ChangeDisplayOrder
	
	self.Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Relative = self:GetWorldOffsetFromMouse()
		
		self.Object.Position = Relative
	end))
end

function Environment.new(Controller, SpriteData, Parent)
	local self = setmetatable({
		Controller = Controller,
		Maid = MaidClass.new(),
		SpriteData = SpriteData,
		Parent = Parent,
		[script.Name] = true
	}, Environment)
	
	self:init()

	return self, Controller:BindElement(self.Content)
end

return Environment