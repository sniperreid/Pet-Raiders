local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage.Modules
local Utility = Modules.Util

local MaidClass = require(Utility.MaidClass)
local Fusion = script.Parent

local Fusion_Element = require(Fusion.Element)

local Flipbook = {}
Flipbook.__index = Flipbook

function Flipbook:Destroy()
	if self.Maid then
		self.Maid:Clean()
	end

	table.clear(self)
end

function Flipbook:CalculateCoordinatePosition()
	local FlipState = self.FlipState or 0
	
	local SpriteData = self.SpriteData
	local GridSize = SpriteData.Size
	
	local X = -((FlipState - 1) % GridSize)
	local Y = -math.floor((FlipState - 1) / GridSize)
	
	return UDim2.fromScale(
		X,
		Y
	)
end

function Flipbook:CreateContainer()
	
	local CoordinateData = self.CoordinateData
	local SpriteData = self.SpriteData
	
	local ImageID = SpriteData.ID
	
	local Size = CoordinateData.Size
	local Position = CoordinateData.Position
	
	local GridSize = SpriteData.Size
	
	local Content = self.Maid:GiveTask(Instance.new("Frame", self.Parent))
	Content.AnchorPoint = Vector2.one/2
	Content.Size = Size
	Content.Position = Position
	Content.BackgroundTransparency = 1
	Content.Name = "FlipbookContainer::" .. ImageID
	Content.ClipsDescendants = true

	local Icon = Instance.new("ImageLabel", Content)
	Icon.Size = UDim2.fromScale(GridSize, GridSize)
	Icon.BackgroundTransparency = 1
	Icon.Name = "Icon"
	Icon.Image = ImageID
	
	self.Content = Content
	self.Object = Icon
end

function Flipbook:init()
	
	self:CreateContainer()
	
	self.is = Fusion_Element.is
	
	self.CreateTween = Fusion_Element.CreateTween
	self.PlayTween = Fusion_Element.PlayTween
	
	self.Transform = Fusion_Element.Transform
	self.RotateTo = Fusion_Element.RotateTo
	self.ChangeOpacity = Fusion_Element.ChangeOpacity
	
	local SpriteData = self.SpriteData
	local PauseDelay = 0

	self.Maid:GiveTask(RunService.RenderStepped:Connect(function(dt)
		
		if (tick() - PauseDelay) < SpriteData.Pause then
			return
		end
		
		local GridSize = SpriteData.Size
		
		local Content = self.Content
		local Icon = self.Object
		
		local Coordinate = self:CalculateCoordinatePosition()
		
		Icon.Position = Coordinate
		Icon.Image = SpriteData.ID
		
		self.FlipState = (self.FlipState or 0) + 1
		
		if self.FlipState > (GridSize^2 + 1) then
			
			self.FlipState = 0
			Icon.Image = ""
			
			PauseDelay = tick()
		end

	end))
end

function Flipbook.new(Controller, CoordinateData, SpriteData, Parent)
	local self = setmetatable({
		Controller = Controller,
		Maid = MaidClass.new(),
		CoordinateData = CoordinateData,
		SpriteData = SpriteData,
		Parent = Parent,
		[script.Name] = true
	}, Flipbook)
	
	self:init()

	return self, Controller:BindElement(self.Content)
end

return Flipbook