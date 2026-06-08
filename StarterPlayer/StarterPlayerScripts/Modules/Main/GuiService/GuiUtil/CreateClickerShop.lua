local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")

local GuiService

local Module = {}

function Module:Create(Grid, ClickerName, ClickerData, ...)
	local Template = script.Template:Clone()
	Template.Parent = Grid
	Template.Name = ClickerName
	Template.LayoutOrder = ClickerData.Buff * 100 or -1
	
	local _Glow = Template.Glow
	local _Content = Template.Content
	
	TextAnimationService:AnimateImage(_Glow, ClickerData.Rarity or "Legendary")
	
	_Content.Icon.Image = ImageModule(ClickerName)

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