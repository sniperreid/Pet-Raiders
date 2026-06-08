local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local InputManager = Services.get("InputManager")
local MaidClass = Services.get("MaidClass")
local RunService = Services.get("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player and Player.PlayerGui
local Interface = PlayerGui and PlayerGui.Interface
local Frames = Interface and Interface.Frames
local DoorOpenFrame = Frames and Frames.DoorOpenFrame

local PromptButton = script.PromptButton:Clone()

local Prompt = {}
Prompt.__index = Prompt

function Prompt:Destroy()
	if self.Maid then
		self.Maid:Clean()
		self.Maid = nil
	end
	
	table.clear(self)
end

function Prompt:createAttachment()
	return Instance.new("Attachment", self.Part)
end

function Prompt:is_in_range()
	
	local Model = self.Model
	local Attachment = self.Attachment
	
	local Character = Player.Character
	local Pivot = Character and Character:GetPivot() or CFrame.new()

	local p0 = Attachment.WorldCFrame.Position
	local p1 = Pivot.Position

	local normalized = p0 - p1

	local dist = normalized.Magnitude
	
	if not self.Exception() then
		return
	end

	return dist < self.Range
end

function Prompt:load_prompt()

	local Model = self.Model
	local in_range = self:is_in_range()
	
	if not in_range then

		if self.Selected == Model then
			self.newButton.Visible = false
		end

		return
	end

	self.newButton.Visible = in_range

	if DoorOpenFrame.Visible then
		return
	end

	local Display = workspace.CurrentCamera:WorldToScreenPoint(
		self.Attachment.WorldCFrame.Position
	)

	self.newButton.Position = UDim2.fromOffset(
		Display.X,
		Display.Y + 50
	)

	self.newButton.Content.Title.Text = "Unlock " .. Model.Name

	self.Selected = Model

end

function Prompt:ConstrainConfines(worldPos)
	
	local Part = self.Part

	local relative = Part.CFrame:PointToObjectSpace(worldPos)
	local size = Part.Size / 2

	relative = CFrame.new(
		math.clamp(relative.X, -size.X, size.X),
		math.clamp(relative.Y, -size.Y, size.Y),
		math.clamp(relative.Z, -size.Z, size.Z)
	)

	return Part.CFrame * relative

end

function Prompt:trace_attachment()

	local Character = Player.Character
	local Pivot = Character and Character:GetPivot() or CFrame.new()

	local Model = self.Model
	local Display = Model:FindFirstChild("Display")
	
	if not Display then
		return self:Destroy()
	end
	
	if not Display:FindFirstChild("SurfaceGui") then
		return
	end
	
	local Attachment = self.Attachment

	local p1 = Pivot.Position

	Attachment.WorldCFrame = self:ConstrainConfines(p1)

	self:load_prompt(self.Part)
	
end

function Prompt:init()
	self.Maid = MaidClass.new()
	self.Attachment = self.Maid:GiveTask(
		self:createAttachment()
	)
	
	local Keybinds = InputManager.newKeybinder(Prompt, self.Class)

	Keybinds:ToggleMobileInput(false)
	Keybinds:ToggleInputType("Disconnect")
	
	local Tag = "Prompt" .. self.Model.Name

	Keybinds:NewBinds(Tag, {
		PC = Enum.KeyCode.E,
		Xbox = Enum.KeyCode.DPadUp,
		Mobile = Enum.UserInputType.Touch
	}, function()
		self:trigger(self.Selected)
	end)
	
	self.newButton = self.Maid:GiveTask(
		PromptButton:Clone()
	)
	
	self.newButton.Parent = Interface
	self.newButton.Name = "PromptDoor"
	self.newButton.Visible = false

	Keybinds:RenderKeybinds()

	Keybinds:NewButton(
		Tag,
		self.newButton
	)
	
	self.Maid:GiveTask(RunService.RenderStepped:Connect(function()
		self:trace_attachment()
	end))
end

function Prompt:trigger(...)
	if not self.Callback then
		return
	end
	
	if not self:is_in_range() then
		return
	end
	
	return self.Callback(...)
end

function Prompt:triggerException(Callback)
	self.Exception = Callback
end

function Prompt:onTrigger(Callback)
	self.Callback = Callback
end

function Prompt.new(Model, Class, Range)
	local self = setmetatable({
		Model = Model,
		Part = Model.PrimaryPart,
		Range = Range or 15,
		Class = Class
	}, Prompt)
	
	self:init()
	
	return self
end

return Prompt