local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local ImageModule = Services.get("ImageModule")

local GuiService

local Module = {}

function Module:Create(MasteryName, MasteryLevel, Grid, ...)
	local TemplateExists = Grid and Grid:FindFirstChild(MasteryName)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = MasteryName
	
	local Content = Template.Content
	
	Content.Icon.Image = ImageModule(MasteryName .. "Mastery")
	Content.Level.Text = MasteryLevel

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