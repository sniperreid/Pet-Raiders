local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local TweenService = Services.get("TweenV2")
local math = Services.get("MathUtility")
local Render = Services.get("RenderUtil").Number

local GuiService

local Module = {}

function Module:Create(BarSettings, ...)
	if not BarSettings then
		return
	end
	
	local Frame = BarSettings.Frame
	local FrameColor = BarSettings.Color
	local CornerScale = BarSettings.CornerScale or 1
	local CornerOffset = BarSettings.CornerOffset or 0
	
	local EasingStyle = BarSettings.EasingStyle or "Linear"
	local EasingDirection = BarSettings.EasingDirection or "InOut"
	
	local TextEnabled = BarSettings.TextEnabled
	local TextColor = BarSettings.TextColor
	local TextFont = BarSettings.TextFont
	
	local p0 = BarSettings.Amount1 or 100
	local p1 = BarSettings.Amount2 or 100
	
	local inverse = p0 < p1 and p0 / p1 or p1 / p0
	
	local FrameScale = math.clamp(inverse, 0, 1)
	
	local bTemplate = BarSettings.Template or (Frame and Frame:FindFirstChildOfClass("Frame"))
	
	local Template = bTemplate or script.Template:Clone()
	Template.Parent = Frame
	
	local FrameCorner = Frame and Frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", Frame)
	FrameCorner.CornerRadius = UDim.new(CornerScale or FrameCorner.CornerRadius.Scale, CornerOffset or FrameCorner.CornerRadius.Offset)
	
	local BarCorner = Template:FindFirstChildOfClass("UICorner") or FrameCorner:Clone()
	BarCorner.CornerRadius = UDim.new(FrameCorner.CornerRadius.Scale, FrameCorner.CornerRadius.Offset)
	BarCorner.Parent = Template

	Template.Position = UDim2.fromScale(0, 0)
	Template.AnchorPoint = Vector2.zero
	
	Template.BackgroundColor3 = FrameColor or (bTemplate and bTemplate.BackgroundColor3) or Color3.fromRGB(255, 255, 255)
	
	local TweenTime = BarSettings.TweenTime or math.abs(math.inverse(
		FrameScale,
		Template.Size.X.Scale
	))

	if Frame then
		local bg3 = Template.BackgroundColor3
		local R, G, B = bg3.R, bg3.G, bg3.B
		
		Frame.BackgroundColor3 = Color3.new(
			R - .1,
			G - .1,
			B
		)
	end
	
	local TextLabel = Frame and Frame:FindFirstChildOfClass("TextLabel")
	
	local Min = (TextLabel and TextLabel:GetAttribute("MinNum")) or 0
	
	if (TextEnabled and Frame) or TextLabel then
		TextLabel = Frame:FindFirstChildOfClass("TextLabel") or Instance.new("TextLabel", Frame)
		TextLabel.TextScaled = true
		TextLabel.Size = UDim2.fromScale(1, 1)
		TextLabel.Position = UDim2.fromScale(.5, .5)
		TextLabel.AnchorPoint = Vector2.one/2
		TextLabel.ZIndex = Template.ZIndex + 1
		TextLabel.BackgroundTransparency = 1
		
		TextLabel:SetAttribute("MinNum", p0)
		
		TextLabel.TextColor3 = TextColor or TextLabel.TextColor3
		TextLabel.Font = TextFont or TextLabel.Font
	end

	Render.new(
		{
			Min = Template.Size.X.Scale,
			Max = FrameScale,
			UpdateSpeed = TweenTime
		},
		function(x)
			Template.Size = UDim2.fromScale(x, 1)
		end
	)
	
	local a, b = Min, p0
	
	if BarSettings.Type == "Percent" then
		a = (Min / (p1 / 100))
		b /= (p1 / 100)
	end
	
	if TextLabel then
		Render.new(
			{
				Min = a,
				Max = b,
				UpdateSpeed = TweenTime
			},
			function(x)
				if BarSettings.Type == "Percent" then
					TextLabel.Text = ("%s%s"):format(
						math.round(x),
						"%"
					)
					
					return
				end
				
				TextLabel.Text = ("%s / %s%s"):format(
					math.round(x),
					p1,
					BarSettings.SpecialKey or ""
				)
			end
		)
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