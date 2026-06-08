local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local PetsFolder = Assets:WaitForChild("Pets")

local PetModule = Services.get("PetModule")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")

local GuiService

local Module = {}

function Module:Create(PetName, PetChance, Grid, ...)
	local Template = script.Template:Clone()
	Template.Name = PetName
	Template.Parent = Grid
	
	local Content = Template.Content
	
	local _Squiggle = Content.Squiggle
	local _PetIcon = Content.PetIcon
	local _PetChance = Content.PetChance
	
	local _PetData = PetModule[PetName]
	local PetRarity = _PetData.Rarity
	
	TextAnimationService:AnimateImage(_Squiggle, PetRarity)
	
	_PetChance.Text = ("%s%s"):format(PetChance, "%")
	
	_PetIcon.Image = ImageModule(PetName)

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