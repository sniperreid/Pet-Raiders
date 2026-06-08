local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Abilities = Services.get("Abilities")
local ImageModule = Services.get("ImageModule")

local GuiService

local Module = {}

function Module:Create(Data, Grid, ...)
	local Ability, Keybind = unpack(Data)
	
	local Template = script.Template:Clone()
	Template.Name = Ability
	Template.Parent = Grid
	
	Template.Keybind.Text = Keybind
	
	Template.Content.Title.Text = Ability
	Template.Content.Icon.Image = ImageModule(Ability)
	
	return Template
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