local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local TweenService = Services.get("TweenV2")

return function(Display, Info, Transparency)
	local Content = Display.Content
	local Currency = Content.Currency
	local Amount = Content.Amount
	local UIStroke = Amount.UIStroke	
	
	if not Info then
		Currency.ImageTransparency = Transparency
		Amount.TextTransparency = Transparency
		UIStroke.Transparency = math.clamp(Transparency, 0, 1)
		
		return
	end
	
	TweenService:Create(
		Currency,
		Info,
		{
			ImageTransparency = Transparency
		}
	):Play()
		
	TweenService:Create(
		Amount,
		Info,
		{
			TextTransparency = Transparency
		}
	):Play()
		
	TweenService:Create(
		UIStroke,
		Info,
		{
			Transparency = math.clamp(Transparency, 0, 1)
		}
	):Play()
end