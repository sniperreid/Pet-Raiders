local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local TweenV2 = Services.get("TweenV2")
local TextAnimationService = Services.get("TextAnimationService")
local TiersModule = Services.get("TiersModule")
local PetModule = Services.get("PetModule")
local CurrencyModule = Services.get("CurrencyModule")
local SoundService = Services.get("SoundService")
local AnimationService = Services.get("AnimationService")

local GuiService
local Interface
local Frames
local MessageFrame

local Module = {}

function Module:PlayTextAnimation(Template, Time)
	
	local Content = Template.Content

	AnimationService:AnimateUI_Open(
		Template,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0.6, 1, 5
	)

	Content.Amount.Position = UDim2.new(0.5, 0, -1, 0)

	TweenV2:Create(Content.Amount, TweenInfo.new(
		0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out
		), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}
	):Play()

	task.delay(Time or 4, function()
		AnimationService:AnimateUI_Open(
			Template,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.Out,
			1, 0.1, 5
		);

		Debris:AddItem(Template, 1 / 20)
	end)
end

function Module:Create(Data)
	if MessageFrame.Content:FindFirstChild(Data.Status) then return end
	
	local Template = script.Template:Clone()
	Template.Parent = MessageFrame.Content
	Template.Name = Data.Status
	Template.Visible = false
	Template.LayoutOrder = -1
	
	local Content = Template.Content
	local _Amount = Content.Amount
	
	_Amount.TextColor3 = Data.TextColor or Color3.fromRGB(255, 255, 255)
	
	Template.Visible = true
	
	SoundService:PlaySound("Notify3", {
		Volume = .35
	})

	self:PlayTextAnimation(Template, Data.Duration)

	_Amount.Text = Data.Status
end

Network:Bind("DisplayStatus", function(...)
	Module:Create(...)
end)

Network:Bind("RemoveStatus", function(Status)
	local Template = MessageFrame.Content:FindFirstChild(Status)
	
	if not Template then return end
	
	Template:Destroy()
end)

function Module:Give(GS)
	GuiService = GS
	Interface = GS.Interface
	Frames = Interface.Frames
	MessageFrame = Frames.MessageFrame

	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end

	return Module:Create(Type, GSQ, ...)
end