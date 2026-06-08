local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Roblox = Services.get("Roblox")
local GuiService = Services.get("GuiService")

local Frames = GuiService.Frames

local LoadingScreen = {}

LoadingScreen.DefaultLoadingContext = {
	LoadingHeader = "rbxasset://textures/ui/GuiImagePlaceholder.png",
	LoadingContext = "Hello there lol: " .. math.random(1, 100),
	TextColor = Color3.fromRGB(209, 182, 75),
	TextFont = Enum.Font["MontserratBold"]
}

LoadingScreen.__index = LoadingScreen

-- NextTransparency, TweenTime
-- I don't feel like writing that out
-- and re-using it abunch
function LoadingScreen:DoFade(NT, TT)
	local TT = TT or 1
	
	for i, v in self.elements do
		if v:IsA("UIGradient") then
			continue
		end

		local p = {BackgroundTransparency=NT}

		if v:IsA("UIStroke") then
			p.BackgroundTransparency=nil
			p.Transparency=NT
		end

		if v:IsA("ImageLabel") then
			p.ImageTransparency=NT
		elseif v:IsA("TextLabel") then
			p.BackgroundTransparency=p.BackgroundTransparency>0 and NT or nil
			p.TextTransparency=NT
		end

		TweenService:Create(
			v,
			TweenInfo.new(
				TT,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.Out
			),
			p
		):Play()
	end
end

function LoadingScreen:Destroy(ny)
	if not ny then
		return task.spawn(function() self:Destroy(true) end)
	end
	
	local tt = 1
	
	self:DoFade(1, tt)
	
	task.wait(tt)
	
	self.elements.loading_frame:Destroy()
	
	table.clear(self)
	setmetatable(self, nil)
end

function LoadingScreen:new_element(class, element)
	self.elements[class] = element
	return element
end

function LoadingScreen:GenerateTip()
	if not self.elements then
		return
	end
	
	local NewTip = self.Tips[math.random(#self.Tips)]
	
	if self.LastTip == NewTip then
		return self:GenerateTip()
	end
	
	self.LastTip = NewTip
	
	self.elements.loading_tip.Text = NewTip
	
	local Dots = 3
	
	for i = 1, Dots do
		if not self.elements then
			break
		end
		
		self.elements.loading_tip.Text = NewTip .. string.rep(".", i)
		
		task.wait(string.len(NewTip) / 10 / Dots)
	end
	
	for i = Dots, 1, -1 do
		if not self.elements then
			break
		end
		
		self.elements.loading_tip.Text = NewTip .. string.rep(".", i)

		task.wait(string.len(NewTip) / 10 / Dots)
	end
	
	if not self.GenerateTip then
		return
	end
	
	self:GenerateTip()
end

function LoadingScreen:init()
	local FadeIn = self.FadeIn
	
	self:new_element("loading_frame", Roblox.Create "ImageLabel" {
		Parent = Frames,
		Name = script.Name .. "-Container",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = FadeIn and 1 or 0,
		ImageTransparency = FadeIn and 1 or 0,
		AnchorPoint = Vector2.one/2,
		Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromScale(1, 1),
		Image = self.ui_info.LoadingHeader
	})
	
	self:new_element("loading_gradient", Roblox.Create "UIGradient" {
		Parent = self.elements.loading_frame,
		Color = ColorSequence.new {
			ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(.2, Color3.new(0, 0, 0)),
			ColorSequenceKeypoint.new(.3, Color3.fromRGB(113, 113, 113)),
			ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
		},
		Rotation = -90
	})
	
	self:new_element("loading_label", Roblox.Create "TextLabel" {
		Parent = self.elements.loading_frame,
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(.025, .875),
		Size = UDim2.fromScale(.3, .045),
		Font = self.ui_info.TextFont,
		Text = self.ui_info.LoadingContext,
		TextColor3 = self.ui_info.TextColor,
		TextScaled = true,
		TextTransparency = FadeIn and 1 or 0,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	self:new_element("loading_tip", Roblox.Create "TextLabel" {
		Parent = self.elements.loading_frame,
		Name = "Tip",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(.025, .92),
		Size = UDim2.fromScale(.715, .04),
		Font = self.ui_info.TextFont,
		TextColor3 = self.ui_info.TextColor,
		TextScaled = true,
		TextTransparency = FadeIn and 1 or 0,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	
	self:new_element("llUS", Roblox.Create "UIStroke" {
		Parent = self.elements.loading_label,
		Color = Color3.new(
			self.ui_info.TextColor.r-.3,
			self.ui_info.TextColor.g-.3,
			self.ui_info.TextColor.b-.3
		),
		Transparency = FadeIn and 1 or 0,
		Thickness = 3
	})
	
	self:new_element("ltUS", Roblox.Create "UIStroke" {
		Parent = self.elements.loading_tip,
		Color = Color3.new(
			self.ui_info.TextColor.r-.3,
			self.ui_info.TextColor.g-.3,
			self.ui_info.TextColor.b-.3
		),
		Transparency = FadeIn and 1 or 0,
		Thickness = 3
	})
	
	task.spawn(function()
		if not FadeIn then
			return self:GenerateTip()
		end
		
		self:DoFade(0, FadeIn)
		
		self:GenerateTip()
	end)
	
	return self
end

function LoadingScreen:NewTips(data)
	for i, v in data do
		table.insert(self.Tips, v)
	end
end

function LoadingScreen.new(args)
	args = args or {}
	
	assert(typeof(args) == "table", "invalid loading arguments.")
	
	for i, v in LoadingScreen.DefaultLoadingContext do
		if args[i] then continue end
		
		args[i] = v
	end
	
	return setmetatable({
		Tips = {},
		elements = {},
		FadeIn = false,
		ui_info = args
	}, LoadingScreen)
end

return LoadingScreen