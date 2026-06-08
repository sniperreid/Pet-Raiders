local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local TweenService = Services.get("TweenV2")
local GuiService = Services.get("GuiService")
local Network = Services.get("Network")
local EasyRender = Services.get("RenderUtil").Number

local Interface = GuiService.Interface
local Frames = GuiService.Frames

local RNG = Random.new()
local Area = {
	x = .2,
	y = .3
}

local newArea = function()
	local x = Area.x
	local y = Area.y
	
	local ViewSize = 1
	
	return {
		x = RNG:NextNumber(x, ViewSize - x),
		y = RNG:NextNumber(y, ViewSize - y)
	}
end

return function(Currency, Amount)
	local Display = script.Display:Clone()
	Display.Name = Currency
	Display.ZIndex = 999
	
	Display.Parent = Frames
	
	local dContent = Display.Content
	
	local dIcon = dContent.Currency
	local dAmount = dContent.Amount
	
	local Special = script:FindFirstChild(Currency) or script:FindFirstChild("Default")
	
	local PlayerData = Network:Fetch("GetClientData") or {}

	local Image = ImageModule(Currency)
	
	dIcon.Image = Image
	dAmount.Text = ("+%s"):format(
		Short:AddSuffix(EasyRender:ReplaceDecimals(
			Amount,
			2
		))
	)
	
	local Area = newArea()
	
	Display.Position = UDim2.fromScale(Area.x, Area.y) -- (Area.x, 1)
	
	dContent.UIScale.Scale = .9
	
	TweenService:Create(
		dContent.UIScale,
		TweenInfo.new(
			.1,
			Enum.EasingStyle.Sine
		),
		{
			Scale = 1
		}
	):Play()
	
	return require(Special)(Display)
end