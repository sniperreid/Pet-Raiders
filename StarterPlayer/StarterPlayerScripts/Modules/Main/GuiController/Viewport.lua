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

local Viewport = {}
Viewport.__index = Viewport

function Viewport:Destroy()
	if self.Maid then
		self.Maid:Clean()
	end

	table.clear(self)
end

function Viewport:CreateViewport()
	local ViewportFrame = self.Maid:GiveTask(Instance.new("ViewportFrame", self.Content))
	ViewportFrame.AnchorPoint = Vector2.one/2
	ViewportFrame.Size = UDim2.fromScale(1, 1)
	ViewportFrame.Position = UDim2.fromScale(.5, .5)
	ViewportFrame.BackgroundTransparency = 1
	ViewportFrame.Name = "ViewportContainer"
	
	local Camera = Instance.new("Camera", ViewportFrame)
	
	ViewportFrame.CurrentCamera = Camera

	self.ViewportFrame = ViewportFrame
end

function Viewport:InsertModel(Model, Offset)
	
	if self.Subject then
		self.Subject:Destroy()
	end
	
	local Viewport = self.ViewportFrame
	local Camera = Viewport.CurrentCamera
	
	self.Subject = self.Maid:GiveTask(Model)
	self.Subject.Parent = Viewport
	
	local OxY = Offset.Y
	
	local Pivot = Model:GetPivot()
	local NextPivot = Pivot * Offset
	
	local LookAt = Pivot * CFrame.new(0, OxY, 0)
	
	Camera.CFrame = CFrame.new(
		NextPivot.Position,
		LookAt.Position
	)
end

function Viewport:init()
	self:CreateViewport()
	
	self.is = Fusion_Element.is

	self.CreateTween = Fusion_Element.CreateTween
	self.PlayTween = Fusion_Element.PlayTween

	self.Transform = Fusion_Element.Transform
	self.RotateTo = Fusion_Element.RotateTo
	self.ChangeOpacity = Fusion_Element.ChangeOpacity
	self.ChangeDisplayOrder = Fusion_Element.ChangeDisplayOrder
end

function Viewport.new(Controller, Content)
	local self = setmetatable({
		Controller = Controller,
		Maid = MaidClass.new(),
		Content = Content,
		[script.Name] = true
	}, Viewport)
	
	self:init()

	return self, Controller:BindElement(self.Content)
end

return Viewport