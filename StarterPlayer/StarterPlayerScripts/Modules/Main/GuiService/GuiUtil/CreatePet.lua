local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local PetsFolder = Assets:WaitForChild("Pets")

local PetModule = Services.get("PetModule")
local ImageModule = Services.get("ImageModule")
local TextAnimationService = Services.get("TextAnimationService")
local Short = Services.get("Short")
local TiersModule = Services.get("TiersModule")
local AnimationService = Services.get("AnimationService")

local GuiService

local Module = {}

function Module:Create(PetData, Grid, ...)
	local PetID = PetData.ID
	local PetName = PetData.Name
	local PetTier = PetData.Tier
	local PetExp = PetData.Exp
	local PetLevel = PetData.Level
	local PetEquipped = PetData.Equipped
	local PetLocked = PetData.Locked
	local PetEnchant = PetData.Enchant

	local TemplateExists = Grid and Grid:FindFirstChild(PetID)
	
	local Template = TemplateExists or script.Template:Clone()
	Template.Parent = Grid
	Template.Name = PetID
	
	local Content = Template.Content
	local TierData = TiersModule[PetTier]

	local TierColor = TierData.Color
	local TierShade = TierData.Shade
	
	Content.BackgroundColor3 = TierColor
	Content.Inner.BackgroundColor3 = TierShade
	
	local _Equipped = Content.Equipped
	local _PetIcon = Content.PetIcon
	local _Selected = Content.Selected
	local _Info = Content.Info
	local _Serial = Content.PetSerial
	local _Locked = Content.Locked
	local _LockSelected = Content.LockSelected
	local _Enchant = Content.Enchant
	
	local _Glow = Template.Glow
	
	local _PetData = PetModule[PetName]
	local PetRarity = _PetData.Rarity
		
	if not TemplateExists then
		TextAnimationService:AnimateImage(_Glow, PetRarity)
	end
	
	if PetTier == "Shiny" then
		AnimationService:AnimateShinyGradient(Content)
	end
	
	_Info.Level.Text = ("Lvl %d"):format(PetLevel)
	_Info.Secret.Visible = PetRarity == "Secret"
	_Info.Mutated.Visible = PetRarity == "Mutation"
	
	_Equipped.Visible = PetEquipped
	_Locked.Visible = PetLocked
	
	_Selected.Visible = false
	_LockSelected.Visible = false
	
	_Serial.Visible = false
	
	_PetIcon.Image = ImageModule(PetName)
	
	_Enchant.Visible = PetEnchant ~= nil
	_Enchant.Icon.Image = PetEnchant and ImageModule(PetEnchant) or ""
	
	if PetLocked then
		_Enchant.Position = UDim2.fromScale(.845, .5)
	else
		_Enchant.Position = UDim2.fromScale(.845, .815)
	end

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