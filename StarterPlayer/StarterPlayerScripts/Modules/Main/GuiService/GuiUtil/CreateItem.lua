local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local PetModule = Services.get("EggModule")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")
local Short = Services.get("Short")

local GuiService

local Module = {}

function Module:Create(ItemName, ItemAmount, Grid, ...)
	local TemplateExists = Grid and Grid:FindFirstChild(ItemName)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = ItemName
	
	local Content = Template.Content
	
	local _ItemIcon = Content.ItemIcon
	local _Amount = Content.Amount
	
	local _Glow = Template.Glow
		
	if not TemplateExists then
		TextAnimationService:AnimateImage(_Glow, "Legendary")
	end
	
	_Amount.Text = ("x%s"):format(Short:AddSuffix(ItemAmount))
	
	_ItemIcon.Image = ImageModule(ItemName)

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