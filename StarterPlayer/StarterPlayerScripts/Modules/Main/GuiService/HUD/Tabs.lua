-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local GuiService
local Interface
local Frames

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local Network = Services.get("Network")
local AnimationService = Services.get("AnimationService")

---------------------- Services ----------------------

local Tabs = {}
Tabs.__index = Tabs

function Tabs:CreateButton(Button)
	local Content = Button.Content
	local Title = Content:FindFirstChild("Title") or {}
	
	Title.Text = Button.Name
	
	return AnimationService:CreateButton(Button, function()
		self:OpenTab(Button.Name)
	end)
end

function Tabs:OpenTab(Tab)
	local Frame = self.Frame
	local Content = Frame.Content

	local Tabs = Content.Tabs
	local Tab = Tabs:FindFirstChild(Tab)

	if not Tab then
		return
	end

	self:Clear()

	Tab.Visible = true
end

function Tabs:UpdateTitles(Tabs)
	for _, Tab in Tabs:GetChildren() do
		self:UpdateTitle(Tab)
	end
end

function Tabs:UpdateTitle(Tab)
	local Title = Tab:FindFirstChild("Title")
	local Text = Title and Title.Text
	
	local Label = Text and Text.TextLabel
	local Stroke = Text and Text.Stroke
	
	if not Title then
		return
	end
	
	if Title.Text ~= "?" then
		return
	end
	
	Title.Text = Tab.Name
	Stroke.Text = Tab.Name
end

function Tabs:Clear()
	local Frame = self.Frame
	local Content = Frame.Content

	local Tabs = Content.Tabs
	
	for _, Tab in Tabs:GetChildren() do
		Tab.Visible = false
		
		self:UpdateTitle(Tab)
	end
end

function Tabs:Create()
	local Frame = self.Frame
	local Content = Frame.Content
	
	local Tabs = Content.Tabs
	local Buttons = Content.Buttons
	
	self:UpdateTitles(Tabs)
	
	for _, Button in Buttons:GetChildren() do
		if not Button:IsA("GuiButton") then
			continue
		end
		
		self:CreateButton(Button)
	end
end

function Tabs.new(Frame)
	local self = setmetatable({}, Tabs)
	
	self.Frame = Frame
	
	self:Create()
	
	return self
end

return setmetatable(Tabs, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames

		return self
	end,
})