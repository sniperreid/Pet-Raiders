-------------------------- Framework --------------------------

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local GuiService
local Interface
local Frames

local HUD
local Tabs

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local Network = Services.get("Network")
local AnimationService = Services.get("AnimationService")
local InputManager = Services.get("InputManager")

---------------------- Services ----------------------

local Buttons = {}

Buttons.DeviceKeybinds = {
	Inventory = {
		PC = Enum.KeyCode.F,
		Xbox = Enum.KeyCode.ButtonY,
		Mobile = Enum.UserInputType.Touch
	},
	
	Settings = {
		PC = Enum.KeyCode.Q,
		Xbox = Enum.KeyCode.DPadUp,
		Mobile = Enum.UserInputType.Touch
	},
	
	Index = {
		PC = Enum.KeyCode.V,
		Xbox = Enum.KeyCode.DPadRight,
		Mobile = Enum.UserInputType.Touch
	},
	
	Shop = {
		PC = Enum.KeyCode.X,
		Xbox = Enum.KeyCode.DPadLeft,
		Mobile = Enum.UserInputType.Touch
	},
	
	Crafting = {
		PC = Enum.KeyCode.B,
		Xbox = Enum.KeyCode.DPadDown,
		Mobile = Enum.UserInputType.Touch
	}
}

local Keybinds = InputManager.newKeybinder({}, "Buttons")

Keybinds:ToggleMobileInput(false)
Keybinds:ToggleInputType("Disconnect")

function Buttons:GetFrame(Button)
	return Button.Name .. "Frame"
end

function Buttons:SetFrame(Button)
	local Title = Button.Parent
	local Content = Title.Parent
	
	if not Frames.StatsFrame.Visible then
		return
	end

	if not Content.Visible then
		return
	end

	if Button.Name == "Close" then
		local BFrame = Content.Parent

		if Content.Name ~= "Content" then
			BFrame = Content
		end

		return GuiService:CloseFrame(BFrame)
	end

	GuiService:OpenFrame(
		self:GetFrame(Button),
		true
	)
end

function Buttons:UpdateKeybinds(Button, Keybinder)
	local Keybinds = Keybinder or Keybinds

	local Buttons = Button.Parent
	local Tab = Buttons.Parent
	local isTab = Tab.Name == "Content"

	local bContent = Button.Content
	local KeybindLabel = Button:FindFirstChild("Keybind")
	local KeybindIcon = Button:FindFirstChild("KeybindIcon")

	local DeviceKeybinds = self.DeviceKeybinds
	local Tag = isTab and "Tab_" .. Button.Name or Button.Name

	local userTag = DeviceKeybinds[Tag]

	KeybindIcon.Visible = false
	KeybindLabel.Visible = false

	if not userTag then
		return
	end

	Keybinds:UpdateButton(Tag)
end

function Buttons:CreateButton(Button)
	local Buttons = Button.Parent
	local Tab = Buttons.Parent
	local isTab = Tab.Name == "Content"

	local bContent = Button.Content
	local KeybindLabel = Button:FindFirstChild("Keybind")
	local KeybindIcon = Button:FindFirstChild("KeybindIcon")
	local Keybind = KeybindLabel and KeybindLabel.Text

	if not Keybind then
		return AnimationService:CreateButton(Button, function()
			self:SetFrame(Button)
		end)
	end

	local DeviceKeybinds = self.DeviceKeybinds
	local Tag = isTab and "Tab_" .. Button.Name or Button.Name

	local userTag = DeviceKeybinds[Tag]

	KeybindIcon.Visible = false
	KeybindLabel.Visible = false

	if not userTag then
		return AnimationService:CreateButton(Button, function()
			self:SetFrame(Button)
		end)
	end

	Keybinds:NewBinds(Tag, userTag, function()
		if isTab and not Tab.Parent.Visible then
			return
		end
		
		if not Button.Visible then
			return
		end

		self:SetFrame(Button)
	end, Button)
end

function Buttons:CreateTabs()
	for _, Frame in Frames:GetChildren() do
		if not Frame:IsA("Frame") then
			continue
		end

		local Content = Frame:FindFirstChild("Content")

		if not Content then
			continue
		end

		local _Tabs = Content:FindFirstChild("Tabs")
		local _Buttons = Content:FindFirstChild("Buttons")

		if not _Tabs or not _Buttons then
			continue
		end

		Tabs.new(Frame)
	end
end

function Buttons:CreateCloses()
	for _, Frame in Frames:GetChildren() do
		if not Frame:IsA("Frame") then
			continue
		end

		local isContent = Frame:FindFirstChild("Content")
		local Content = isContent or Frame

		if not Content then
			continue
		end

		local Title = Content:FindFirstChild("Title")
		local Close = Title and Title:FindFirstChild("Close")

		if not Close then
			continue
		end

		self:CreateButton(Close)
	end
end

function Buttons:CreateMain()
	local StatsFrame = Frames:FindFirstChild("StatsFrame")
	local Buttons = StatsFrame and StatsFrame:FindFirstChild("Buttons")
	local Stats = StatsFrame and StatsFrame:FindFirstChild("Stats")
	local Bottom = StatsFrame and StatsFrame:FindFirstChild("Bottom")

	if not Buttons then
		return
	end

	for _, Button in Buttons:GetChildren() do
		if not Button:IsA("GuiButton") then
			continue
		end

		self:CreateButton(Button)
		self:UpdateKeybinds(Button)
	end
	
	for _, Button in Stats.Buttons:GetChildren() do
		if not Button:IsA("GuiButton") then
			continue
		end
		
		self:CreateButton(Button)
		self:UpdateKeybinds(Button)
	end

	if not Bottom then
		return
	end

	for _, Button in Bottom:GetChildren() do
		if not Button:IsA("GuiButton") then
			continue
		end

		self:CreateButton(Button)
		self:UpdateKeybinds(Button)
	end
end

function Buttons:Initialize()
	local StatsFrame = Frames:FindFirstChild("StatsFrame")
	local Buttons = StatsFrame and StatsFrame:FindFirstChild("Buttons")
	local Bottom = StatsFrame and StatsFrame:FindFirstChild("Bottom")

	self:CreateMain()
	self:CreateCloses()
	self:CreateTabs()

	Keybinds:RenderKeybinds()

	InputManager.ControllerConnected:Connect(function()
		self:CreateMain()
		self:CreateTabs()
	end)

	InputManager.ControllerDisconnected:Connect(function()
		self:CreateMain()
		self:CreateTabs()
	end)
end

return setmetatable(Buttons, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		
		coroutine.wrap(function()
			repeat task.wait()
				
			until GuiService.HUD
			
			HUD = GuiService.HUD
			Tabs = HUD.Tabs
			
			self:Initialize()
		end)()

		return self
	end,
})