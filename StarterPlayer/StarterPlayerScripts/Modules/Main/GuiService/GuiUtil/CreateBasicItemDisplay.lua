local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local PetsFolder = Assets:WaitForChild("Pets")

local PetModule = Services.get("PetModule")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")
local Short = Services.get("Short")
local CurrencyModule = Services.get("CurrencyModule")

local GuiService

local Module = {}

function Module:Create(Info, ...)
	local Name = Info.Name
	local Amount = Info.Amount
	
	local Template = script.Template:Clone()
	
	local Content = Template.Content
	
	local _Icon = Content.Icon
	local _Amount = Content.Amount
	
	local _Glow = Template.Glow
	
	local _PetData = PetModule[Name] or {}
	local PetRarity = _PetData.Rarity
	
	_Glow.ImageColor3 = Color3.fromRGB(255, 255, 255)
		
	if PetRarity then
		TextAnimationService:AnimateImage(_Glow, PetRarity)
	else
		_Glow.ImageColor3 = CurrencyModule[Name].Color
	end
	
	_Icon.Image = ImageModule(Name)
	_Amount.Text = ("x%s"):format(Short:AddSuffix(Amount))

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