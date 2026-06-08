local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get("Network")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Interface = PlayerGui:WaitForChild("Interface")
local Frames = Interface.Frames

local GuiService = {
	PlayerGui = PlayerGui,
	Interface = Interface,
	Frames = Frames
}

function GuiService:load()
	
	self.GuiUtil = require(script.GuiUtil)(self)
	
	for i, add_on in script:GetChildren() do
		
		if self[add_on.Name] then
			continue
		end
		
		self[add_on.Name] = require(add_on)(self)
	end
end

function GuiService:init()
	for i, add_on in script:GetChildren() do
		if not self[add_on.Name] then
			continue
		end
		
		if not self[add_on.Name].init then
			continue
		end
		
		self[add_on.Name]:init()
	end
end

GuiService:load()
GuiService:init()

function GuiService:OpenFrame(...)
	return self.FramesController:OpenFrame(...)
end

function GuiService:CloseFrame(...)
	return self.FramesController:CloseFrame(...)
end

local Exclude = {
	"MessageFrame",
	"WheelFrame"
}

Network:Bind("ToggleInterface", function(State)
	for _, v in Frames:GetChildren() do
		if table.find(Exclude, v.Name) then
			continue
		end

		local Content = v:FindFirstChild("Content")

		if not Content then
			continue
		end

		if not Content.Visible then
			continue
		end

		if State then
			continue
		end

		GuiService:CloseFrame(v)
	end

	Frames.StatsFrame.Visible = State
end)

return GuiService