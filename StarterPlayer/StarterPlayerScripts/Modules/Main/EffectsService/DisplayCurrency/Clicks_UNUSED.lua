-------------------------- Framework --------------------------

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local TweenService = Services.get("TweenV2")
local GuiService = Services.get("GuiService")
local SoundService = Services.get("SoundService")

---------------------- Services ----------------------

local dc = script.Parent
local Fade = require(dc.Fade)

local Info = TweenInfo.new(
	.1,
	Enum.EasingStyle.Linear
)

return function(Display)
	local Content = Display.Content
	
	local UIScale = Content.UIScale
	
	Fade(Display, nil, 1)

	Fade(Display, Info, 0)
	
	task.delay(1, function()
		TweenService:Create(
			UIScale,
			Info,
			{
				Scale = 2.5
			}
		):Play()
		
		Fade(Display, Info, 1.25)
		
		SoundService:PlaySound("Pop_1", {
			Volume = .5
		})
		
		Debris:AddItem(Display, .15)
	end)
end