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
local SoundService = Services.get("SoundService")
local AnimationService = Services.get("AnimationService")

local Interface = GuiService.Interface
local Frames = Interface.Frames

local StatsFrame = Frames:FindFirstChild("StatsFrame")

local dc = script.Parent
local Fade = require(dc.Fade)

local Info = TweenInfo.new(
	.1,
	Enum.EasingStyle.Linear
)

local destInfo = TweenInfo.new(
	.5,
	Enum.EasingStyle.Linear
)

GetDestination = function(Display)
	local Destination = StatsFrame and StatsFrame.Stats:FindFirstChild(Display.Name)
	
	if not Destination then
		return
	end
	
	local Content = Destination.Content
	local Icon = Content.Icon
	
	return Icon
end

return function(Display)
	local Content = Display.Content
	
	local UIScale = Content.UIScale
	
	SoundService:PlaySound("Pop_1", {
		Volume = .5
	})
	
	Fade(Display, nil, 1)
	
	Fade(Display, Info, 0)
	
	AnimationService:AnimateUI_Open(
		Display,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0.5, 1, 3.5
	)
	
	task.delay(1, function()
		local Origin = Display.AbsolutePosition

		local Destination = GetDestination(Display)
		
		local X, Y = Origin.X, Origin.Y
		
		if Destination then
			local Position = Destination.AbsolutePosition
			local Size = Destination.AbsoluteSize
			
			Display.Position = UDim2.fromOffset(X, Y)
			
			TweenService:Create(
				Display,
				destInfo,
				{
					Position = UDim2.fromOffset(Position.X, Position.Y + Size.Y)
				}
			):Play()
			
			TweenService:Create(
				UIScale,
				destInfo,
				{
					Scale = .25
				}
			):Play()
			
			return Debris:AddItem(Display, .65), Fade(Display, destInfo, 1.25)
		end
		
		Fade(Display, Info, 1.25)

		Debris:AddItem(Display, .15)
	end)
end