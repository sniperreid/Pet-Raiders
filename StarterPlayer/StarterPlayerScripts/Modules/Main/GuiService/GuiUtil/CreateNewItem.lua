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

function Module:Create(ItemData)
	local Template = script.Template:Clone()
	Template.Parent = MessageFrame.Content
	Template.Name = ItemData.Name or HttpService:GenerateGUID(false)
	Template.Visible = false
	
	local Content = Template.Content
	local _Amount = Content.Amount
	
	if ItemData.TextColor then
		if typeof(ItemData.TextColor) == "string" then
			TextAnimationService:AnimateText(_Amount, ItemData.TextColor)
		else
			_Amount.TextColor3 = ItemData.TextColor
		end
	else
		_Amount.TextColor3 = Color3.fromRGB(160, 239, 255)
	end
	
	if ItemData.Type == "Pet" then
		local PetData = PetModule[ItemData.Name]
		
		local HatchInfo = {
			Name = ItemData.Name,
			Tier = ItemData.Tier or "Normal",
			ManualEggHatch = true
		}

		Network:Fetch("HatchEggClient", {
			Speed = 1.5,
			Egg = ItemData.Egg or "Common Egg",
			Pets = {
				HatchInfo
			},
			Secret = PetData.Rarity == "Secret"
		})
		
		--SoundService:PlaySound("Notify3", {
		--	Volume = .35
		--})
		
		--Template.Visible = true
		
		--self:PlayTextAnimation(Template)
		
		--_Amount.Text = ("x%s %s"):format(ItemData.Amount, ItemData.Name)
		
		return
	end
	
	Template.Visible = true
	
	if ItemData.Type == "Currency" then
		SoundService:PlaySound("Notify3", {
			Volume = .35
		})
		
		self:PlayTextAnimation(Template)
		
		_Amount.Text = ("+%s %s"):format(Short:AddSuffix(ItemData.Amount), ItemData.Name)
		
		Network:Fetch(
			"PlayEffectDisplayCurrency",
			ItemData.Name, 
			Short:AddSuffix(ItemData.Amount)
		)
	end
	
	if ItemData.Type == "Message" then
		SoundService:PlaySound("Notify3", {
			Volume = .35
		})

		self:PlayTextAnimation(Template, ItemData.Time)
		
		_Amount.Text = ItemData.Message
	end
end

Network:Bind("DisplayNewItem", function(...)
	Module:Create(...)
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