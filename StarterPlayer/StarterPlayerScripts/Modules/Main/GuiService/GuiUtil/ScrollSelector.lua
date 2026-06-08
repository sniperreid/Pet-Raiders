local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local TweenService = Services.get("TweenV2")
local math = Services.get("MathUtility")
local Render = Services.get("RenderUtil").Number
local InputManager = Services.get("InputManager")
local RunService = Services.get("RunService")
local Roblox = Services.get("Roblox")
local ImageModule = Services.get("ImageModule")

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = Player.PlayerGui
local Mouse = Player:GetMouse()

local GuiService

local Create = Roblox.Create

local Module = {}
Module.__index = Module

function Module:Destroy()
	for i, connection in self.Connections or {} do
		connection:Disconnect()
	end
	
	if self.Template then
		self.Template:Destroy()
	end
	
	table.clear(self)
end

function Module:GetInputs()
	return {
		StartSwipe = {
			Keybinds = {Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonX},
			Context = "Connect",
			Gpe = nil,
			Callback = function()
				self.BeginScroll = Mouse.X
			end,
		},
		
		EndSwipe = {
			Keybinds = {Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonX},
			Context = "Disconnect",
			Gpe = nil,
			Callback = function()
				self.BeginScroll = nil
			end,
		}
	}
end

function Module:LockToNearest()
	local canvas = self.Template
	local NearestItem = self.NearestItem

	if not NearestItem then
		return
	end
	
	Roblox.Canvas.LerpTo(canvas, NearestItem, .15)
end

function Module:GetNearestItem()
	local Template = self.Template
	local NearestItem
	local MinSize = 0
	
	local Children = Roblox:GetChildrenOfClass(Template, "Frame")
	
	for _, temp in Children do
		local tSize = temp.Content.AbsoluteSize.Magnitude
		
		if tSize < MinSize then
			continue
		end
		
		MinSize = tSize
		NearestItem = temp
	end
	
	self.NearestItem = NearestItem
	
	return NearestItem
end

function Module:ResizeObjects()
	local Template = self.Template
	
	for _, frame in Template:GetChildren() do
		local Content = frame:FindFirstChild("Content")
		local uiScale = Content and Content:FindFirstChild("ScaleFactor")
		
		if not uiScale then
			continue
		end
		
		local canvasSize = Template.AbsoluteSize.X
		
		local distanceFromCenter = math.abs(Roblox.Canvas.DistanceFromFrame(Template, frame).X)
		
		local maxDistance = canvasSize/1.33
		local minScale = 0
		local maxScale = 1

		local scale = maxScale - ((distanceFromCenter / maxDistance) * (maxScale - minScale))
		
		frame.ZIndex = scale * 10
		
		uiScale.Scale = math.clamp(scale, minScale, maxScale)
	end
end

function Module:CreateViewport(Item, Parent)
	local ImageLabel = Parent.Parent:FindFirstChild("ImageLabel")
	ImageLabel.Parent = Parent
	ImageLabel.Image = ImageModule(Item)
end

function Module:CreateItemIcon(Item)
	local itemTemp = script.ItemTemp:Clone()
	itemTemp.Name = Item
	
	local Content = Create("Frame") {
		Parent = itemTemp,
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(.5, .5),
		AnchorPoint = Vector2.one/2
	}
	
	Create("UIScale") {
		Parent = Content,
		Name = "ScaleFactor"
	}
	
	if self.DisplayOnTop then
		Create("TextLabel") {
			Parent = Content,
			Name = "Label",
			Size = UDim2.fromScale(1, 0.25),
			Text = Item,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font["MontserratBold"]
		}
	end
	
	self:CreateViewport(Item, Content)
	
	return itemTemp
end

function Module:PluginInputs()
	self.Connections = {}
	
	for input, data in self:GetInputs() do
		
		for _, Keybind in data.Keybinds do
			self.Connections[input .. tostring(Keybind)] = InputManager.new(
				input .. HttpService:GenerateGUID(false),
				Keybind,
				data.Context,
				data.Gpe,
				data.Callback
			)
		end
		
	end

	self.Connections["StartSwipe"] = InputManager.new(
		"StartSwipe" .. HttpService:GenerateGUID(false),
		Enum.UserInputType.MouseButton1,
		"Connect",
		nil,
		function()
			local GuiObjects = PlayerGui:GetGuiObjectsAtPosition(Mouse.X, Mouse.Y)
			local Template = self.Template

			if not table.find(GuiObjects, Template) then
				return table.clear(GuiObjects)
			end
			
			self.BeginScroll = Mouse.X
			
			table.clear(GuiObjects)
		end
	)

	self.Connections["EndSwipe"] = InputManager.new(
		"EndSwipe" .. HttpService:GenerateGUID(false),
		Enum.UserInputType.MouseButton1,
		"Disconnect",
		nil,
		function()
			self.BeginScroll = nil
		end
	)

	self.Connections["ToggleSwipe"] = RunService.RenderStepped:Connect(function()
		self:ResizeObjects()
		
		coroutine.wrap(
			self.Callback
		)(
			self,
			self:GetNearestItem().Name
		)
		
		if not self.BeginScroll then
			return self:LockToNearest()
		end
		
		local Template = self.Template
		local CanvasPos = Template.CanvasPosition

		self.Power = (self.BeginScroll - Mouse.X)
		
		Template.CanvasPosition = CanvasPos:Lerp(
			Vector2.new(
				CanvasPos.X + self.Power,
				0
			),
			.75
		)
		
		self.BeginScroll = Mouse.X
	end)
end

function Module:Create(Settings, ...)
	local Parent = Settings.Parent
	local Items = Settings.Items or {}
	local Item = Settings.Item
	local Callback = Settings.Callback or function(Item)

	end
	
	local ScrollSelector = setmetatable({}, Module)
	local Template = script.Template:Clone()
	Template.Parent = Parent
	
	ScrollSelector.DisplayOnTop = Settings.DisplayOnTop
	ScrollSelector.Parent = Parent
	ScrollSelector.Items = Items
	ScrollSelector.Item = Item
	ScrollSelector.Callback = Callback
	
	ScrollSelector.Template = Template
	ScrollSelector.BeginScroll = false
	
	local BlankCenter = ScrollSelector:CreateItemIcon("")
	BlankCenter.Size = UDim2.new(0.243, 0, 1, 0)
	BlankCenter.Content.BackgroundTransparency = 1
	BlankCenter.Parent = Template
	BlankCenter.LayoutOrder = -1
	BlankCenter.Content.ImageLabel:Destroy()
	
	self.BlankCenter = BlankCenter
	
	for i, Item in Items do
		local temp = ScrollSelector:CreateItemIcon(Item)
		temp.Parent = Template
		temp.LayoutOrder = i
	end
	
	if ScrollSelector.Item then
		Roblox.Canvas.LerpTo(
			Template,
			Template:FindFirstChild(ScrollSelector.Item),
			1
		)
	end
	
	local BlankCenter2 = ScrollSelector:CreateItemIcon("")
	BlankCenter2.Size = UDim2.new(0.243, 0, 1, 0)
	BlankCenter2.Content.BackgroundTransparency = 1
	BlankCenter2.Parent = Template
	BlankCenter2.LayoutOrder = #Items + 1
	BlankCenter2.Content.ImageLabel:Destroy()
	
	Template.CanvasSize = UDim2.new(0, Template.AbsoluteSize.X, 0, 0)
	
	ScrollSelector:PluginInputs()
	
	return ScrollSelector
end

function Module:Give(GS)
	GuiService = GS
	
	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end
	
	return Module:Create(Type, GSQ, ...)
end