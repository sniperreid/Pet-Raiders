local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local TextAnimationService = Services.get("TextAnimationService")
local AnimationService = Services.get("AnimationService")
local BoostModule = Services.get("BoostModule")

local GuiService

local Module = {}

function Module:Create(Grid, BoostData, ...)
	local BoostModuleData = BoostModule[BoostData.Name]
	
	local Template = Grid:FindFirstChild(BoostData.Name)
	
	if not Template then
		Template = script.Template:Clone()
		Template.Parent = Grid
		Template.Name = BoostData.Name
		
		local Content = Template.Content
		local Squiggle = Content.Squiggle
		
		TextAnimationService:AnimateImage(Squiggle, BoostModuleData.Rarity)
		
		AnimationService:AnimateUI_Open(
			Template, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0.3, 1, 5
		);
	end
	
	local Content = Template.Content
	local Icon = Content.Icon
	local Amount = Content.Amount
	
	Icon.Image = ImageModule(BoostData.Name)
	Amount.Text = Short:FormatBoost(BoostData.Time)

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