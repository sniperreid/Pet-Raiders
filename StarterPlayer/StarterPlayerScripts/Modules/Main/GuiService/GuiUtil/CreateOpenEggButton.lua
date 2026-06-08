local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local GuiService

local Module = {}

function Module:Create(Amount, Grid, ...)
	local TemplateExists = Grid and Grid:FindFirstChild(Amount)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = Amount
	
	local Content = Template.Content
	
	local _Amount = Content.Amount
	
	_Amount.Text = ("Open %s"):format(Amount)

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