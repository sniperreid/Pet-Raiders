local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local GuiService = Services.get "GuiService"
local Frames = GuiService.Frames
local LoadingFrame = Frames.LoadingContext

local LoadingIcon = LoadingFrame.Icon
local LoadingLabel = LoadingFrame.Reason

LoadingFrame.Visible = false

local TweensInfo = TweenInfo.new(
	.3,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.In
)

local TweenIn = {
	TweenService:Create(
		LoadingIcon,
		TweensInfo,
		{
			Position = LoadingIcon.Position,
			ImageTransparency = LoadingIcon.ImageTransparency
		}
	),
	
	TweenService:Create(
		LoadingLabel,
		TweensInfo,
		{
			Position = LoadingLabel.Position,
			TextTransparency = LoadingLabel.TextTransparency
		}
	)
}

local TweenOut = {
	TweenService:Create(
		LoadingIcon,
		TweensInfo,
		{
			Position = UDim2.fromScale(.5, .6),
			ImageTransparency = 1
		}
	),

	TweenService:Create(
		LoadingLabel,
		TweensInfo,
		{
			Position = UDim2.fromScale(.5, .681),
			TextTransparency = 1
		}
	)
}

for i, v in TweenOut do
	v:Play()
end

local ActivelyLoading = false

local LoadContext = {}
LoadContext.AverageLoadTime = TweensInfo.Time

function LoadContext:Start(Reason)
	self:Stop(true)
	
	ActivelyLoading = true
	
	LoadingLabel.Text = Reason or "Loading..."
	LoadingFrame.Visible = true
	
	local StartRot = (tick() * 100) % (360 * 100)
	
	LoadingIcon.Rotation = StartRot
	
	task.spawn(function()
		while true do
			if not ActivelyLoading then
				
				local s = tick()
				
				repeat task.wait()
					LoadingIcon.Rotation += 20 * ((TweensInfo.Time - (tick() - s)) / TweensInfo.Time)
				until (tick() - s) > TweensInfo.Time
				
				break
			end
			
			LoadingIcon.Rotation += 5
			
			task.wait()
		end
	end)
	
	for i, v in TweenIn do
		v:Play()
	end
end

function LoadContext:Stop(yield)
	if not ActivelyLoading then return end
	
	ActivelyLoading = false
	
	for i, v in TweenOut do
		v:Play()
	end
	
	if yield then
		task.wait(TweensInfo.Time)
		
		LoadingFrame.Visible = false
	else
		task.delay(TweensInfo.Time, function()
			LoadingFrame.Visible = false
		end)
	end
end

return LoadContext