local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local RunService = Services.get("RunService")
local EggModule = Services.get("EggModule")
local GuiService = Services.get("GuiService")
local InputManager = Services.get("InputManager")
local EggService = Services.get("EggService")
local Roblox = Services.get("Roblox")
local PetModule = Services.get("PetModule")
local Short = Services.get("Short")
local ImageModule = Services.get("ImageModule")
local CurrencyModule = Services.get("CurrencyModule")
local TextAnimationService = Services.get("TextAnimationService")
local WheelService = Services.get("WheelService")
local AnimationService = Services.get("AnimationService")

local Eggs = workspace.Eggs
local Wheels = workspace.Wheels

local Temp_BillboardGui = script.BillboardGui
local Temp_EggFrame = script.EggFrame

local GuiUtil = GuiService.GuiUtil
local Interface = GuiService.Interface

local Frames = Interface.Frames
local EggOpenFrame = Frames.EggOpenFrame
local WheelFrame = Frames.WheelFrame

local Player = Players.LocalPlayer

local HoverRender
local EggManager = {}

EggManager.Settings = {
	HoverSpeed = 1,
	HoverStrength = .45,
	RotationStrength = 15,
	
	MaxDistance = 20
}

EggManager.EggInfo = {}
EggManager.WheelInfo = {}

local WheelManager = {}

local Keybinds = InputManager.newKeybinder(EggManager, "EggHatching")
local WheelKeybinds = InputManager.newKeybinder(WheelManager, "WheelSpinning")

Keybinds:ToggleMobileInput(false)
Keybinds:ToggleInputType("Disconnect")

WheelKeybinds:ToggleMobileInput(false)
WheelKeybinds:ToggleInputType("Disconnect")

Keybinds:NewBinds("E", {
	PC = Enum.KeyCode.E,
	Xbox = Enum.KeyCode.DPadUp,
	Mobile = Enum.UserInputType.Touch
}, function(self)
	self:AttemptPurchase(1)
end)

WheelKeybinds:NewBinds("E", {
	PC = Enum.KeyCode.E,
	Xbox = Enum.KeyCode.DPadUp,
	Mobile = Enum.UserInputType.Touch
}, function(self)
	self:EnterWheel(1)
end)

Keybinds:NewBinds("R", {
	PC = Enum.KeyCode.R,
	Xbox = Enum.KeyCode.DPadLeft,
	Mobile = Enum.UserInputType.Touch
}, function(self)
	self:AttemptPurchase(self:CanPurchase())
end)

Keybinds:NewBinds("T", {
	PC = Enum.KeyCode.T,
	Xbox = Enum.KeyCode.DPadRight,
	Mobile = Enum.UserInputType.Touch
}, function(self)
	local Egg = self.CurrentEgg

	if not Egg then
		return
	end

	local EggInfo = self:LoadEggInfo(Egg)

	EggInfo.Auto = not EggInfo.Auto
end)

function EggManager:LoadEggInfo(Egg)
	local EggName = Egg.Name
	local EggInfo = self.EggInfo
	
	local Info = EggInfo[EggName]
	
	if Info then
		return Info
	end
	
	if not EggModule[EggName] then
		return
	end
	
	EggInfo[EggName] = {
		BillboardGui = nil,
		Frame = nil,
		
		EggData = EggModule[EggName],
		
		Auto = false
	}
	
	return EggInfo[EggName]
end

function EggManager:LoadWheelInfo(Wheel)
	
	if not Wheel then
		return
	end
	
	local WheelName = Wheel.Name
	local WheelInfo = self.WheelInfo

	if WheelInfo[WheelName] then
		return WheelInfo[WheelName]
	end

	WheelInfo[WheelName] = {
		BillboardGui = nil,
		Button = nil,
		WheelMode = false,
		Hotkey = Wheel:FindFirstChild("Hotkey")
	}

	return WheelInfo[WheelName]
end

function EggManager:GetNearestEgg()
	local Settings = self.Settings
	
	local NearestEgg
	local MaxRange = Settings.MaxDistance/2
	
	local Character = Player.Character
	
	if not Character then
		return
	end
	
	for _, Egg in Eggs:GetChildren() do
		local Origin = Egg:GetPivot()
		local CharOrigin = Character:GetPivot()
		
		local Distance = (Origin.Position - CharOrigin.Position).Magnitude
		
		if Distance > MaxRange then
			continue
		end
		
		NearestEgg = Egg
		MaxRange = Distance
	end
	
	return NearestEgg, MaxRange
end

function EggManager:GetNearestWheel()
	local MaxRange = self.Settings.MaxDistance / 2
	local NearestWheel
	local Character = Player.Character

	if not Character then
		return
	end

	for _, Wheel in Wheels:GetChildren() do
		local Origin = Wheel:GetPivot()
		local CharOrigin = Character:GetPivot()
		local Distance = (Origin.Position - CharOrigin.Position).Magnitude

		if Distance > MaxRange then
			continue
		end
		
		local WheelInfo = self:LoadWheelInfo(Wheel)
		
		--if WheelInfo.WheelMode then
		--	continue
		--end

		NearestWheel = Wheel
		MaxRange = Distance
	end

	return NearestWheel, MaxRange
end

function EggManager:DisableAutoHatch()
	for Egg, Data in self.EggInfo do
		Data.Auto = false
	end
end

function EggManager:ToggleEggGUI(State, OnlyCurrentEgg)
	local CurrentEgg = OnlyCurrentEgg and self.CurrentEgg
	
	for Egg, Data in self.EggInfo do
		local BillboardGui = Data.BillboardGui

		if not BillboardGui then
			continue
		end
		
		if CurrentEgg and Egg ~= CurrentEgg.Name then
			continue
		end

		BillboardGui.Enabled = State
	end
end

function EggManager:ToggleWheelGUI(State, OnlyCurrentWheel)
	local CurrentWheel = OnlyCurrentWheel and self.CurrentWheel

	for _, Data in pairs(self.WheelInfo) do
		local BillboardGui = Data.BillboardGui
		
		if not BillboardGui then
			continue
		end

		if CurrentWheel and Data ~= self.WheelInfo[CurrentWheel.Name] then
			continue
		end

		BillboardGui.Enabled = State
	end
end


function EggManager:EnableEggGUI()
	self:ToggleEggGUI(true, true)
end

function EggManager:HideAllEggGUI(Toggle)
	self.CurrentEgg = Toggle and self.CurrentEgg
	
	self:ToggleEggGUI(false)
end

function EggManager:UpdateStats()
	local Egg = self.CurrentEgg

	if not Egg then
		return
	end
	
	local EggInfo = self:LoadEggInfo(Egg)
	local Frame = EggInfo.Frame

	local Content = Frame.Content
	local Stats = Content.Stats
	
	local Luck = Stats.Luck
	local Speed = Stats.Speed
	
	local LuckMulti = EggModule:RetrievePlayerEggData()
	local SpeedMulti = EggModule:GetEggSpeed()
	
	Luck.Label.Text = ("+%s%%"):format((LuckMulti * 100) - 100)
	Speed.Label.Text = ("+%s%%"):format((SpeedMulti * 100) - 100)
end

function EggManager:UpdateMaxPurchase()
	local Egg = self.CurrentEgg

	if not Egg then
		return
	end
	
	local EggInfo = self:LoadEggInfo(Egg)
	local Frame = EggInfo.Frame
	
	local Content = Frame.Content
	local Buttons = Content.Buttons
	
	local RButton = Buttons.R
	local RContent = RButton.Content

	local RTitle = RContent.Title

	local MaxPurchase = self:CanPurchase() or 0

	RTitle.Text = ("Max (%d)"):format(MaxPurchase)
end

function EggManager:SignalCurrentEgg()
	local Egg = self.CurrentEgg
	
	if not Egg then
		return
	end
	
	local EggInfo = self:LoadEggInfo(Egg)
	
	local Auto = EggInfo.Auto
	local BillboardGui = EggInfo.BillboardGui
	
	if not Auto or not BillboardGui.Enabled then
		return
	end
	
	self:AttemptPurchase()
end

function EggManager:CreateEggController()
	RunService.RenderStepped:Connect(function()
		if EggService:IsHatching() or EggOpenFrame.Visible then
			return self:HideAllEggGUI(true)
		end
		
		local Egg, Distance = self:GetNearestEgg()
		
		self:SignalCurrentEgg()
		
		if not Egg then
			return self:HideAllEggGUI()
		end
		
		if self.CurrentEgg == Egg then
			self:UpdateMaxPurchase()
			self:UpdateStats()
			
			return self:EnableEggGUI()
		end
		
		self:HideAllEggGUI()
		self:DisableAutoHatch()
		
		self.CurrentEgg = Egg
		
		self:UpdatePets()
		self:UpdateKeybinds(Egg)
		
		local EggInfo = self:LoadEggInfo(Egg)
		local BillboardGui = EggInfo.BillboardGui
		
		BillboardGui.Enabled = true
	end)
end

function EggManager:CreateWheelController()
	RunService.RenderStepped:Connect(function()
		local Wheel, Distance = self:GetNearestWheel()
		
		if not Wheel then
			self.CurrentWheel = nil

			return self:ToggleWheelGUI(false)
		end
		
		local WheelInfo = self:LoadWheelInfo(Wheel)
		
		if WheelInfo.WheelMode then
			return self:ToggleWheelGUI(false)
		end

		if self.CurrentWheel == Wheel then
			return self:ToggleWheelGUI(true, true)
		end

		self:ToggleWheelGUI(false)
		self.CurrentWheel = Wheel
		self:AdornWheelGUI(Wheel)
		self:UpdateWheelKeybinds(Wheel)
	end)
end

function EggManager:LoadRarityGrid(Egg, Grid, AllowSecrets, DontUseIndex)
	local EggRarities = EggModule.RNG:NewRarityCalculator(nil, Egg)
	
	Roblox:ClearChildrenOfClass(Grid, "ImageButton")
	
	local PlayerData = Network:Fetch("GetClientData")
	local AutoDelete = PlayerData.AutoDelete or {}

	for i, Pet in EggRarities do
		local PetName, PetChance = unpack(Pet)
		local PetData = PetModule[PetName]

		local PetRarity = PetData.Rarity

		if PetRarity == "Secret" and not AllowSecrets then
			continue
		end

		local GotIcon = Grid:FindFirstChild(PetName)
		
		if PetChance <= 0 then
			PetChance = 0
		elseif PetChance >= 100 then
			PetChance = 100
		else
			PetChance = Short:RoundDecimal(PetChance)
		end

		local PetIcon = GotIcon or GuiUtil:CreateEggPetIcon(PetName, PetChance, Grid)
		local AutoDeleted = table.find(AutoDelete, PetName)

		local pContent = PetIcon.Content
		local pDeleting = pContent.Deleting
		local pIcon = pContent.PetIcon
		local pChance = pContent.PetChance

		local isInIndex = DontUseIndex or table.find(PlayerData.Index, PetName)
		local ShowChance = not (not isInIndex and PetRarity == "Legendary")

		pIcon.ImageColor3 = isInIndex and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
		pChance.Text = ShowChance and ("%s%s"):format(PetChance, "%") or "???"

		pDeleting.Visible = AutoDeleted and true or false

		AnimationService:CreateButton(PetIcon, function()
			Network:Post("AutoDelete", PetName)
		end)
	end
end

function EggManager:UpdatePets()
	local Egg = self.CurrentEgg
	
	if not Egg then
		return
	end
	
	local EggInfo = self:LoadEggInfo(Egg)
	
	local BillboardGui = EggInfo.BillboardGui
	local Frame = EggInfo.Frame
	local EggData = EggInfo.EggData
	
	if not BillboardGui then
		return
	end
	
	local Content = Frame.Content
	local Grid = Content.Grid
	
	self:UpdateMaxPurchase()
	self:UpdateStats()
	
	self:LoadRarityGrid(Egg.Name, Grid)
end

function EggManager:GetPurchaseState(Amount)
	local Egg = self.CurrentEgg

	if not Egg then
		return
	end
	
	local EggName = Egg.Name

	if EggService:IsHatching() then
		return "Hatching"
	end

	local EggInfo = self:LoadEggInfo(Egg)

	local BillboardGui = EggInfo.BillboardGui
	local Frame = EggInfo.Frame
	local EggData = EggInfo.EggData

	local EggData = EggModule[EggName]
	local Currency, Cost = unpack(EggData.Cost)

	Cost *= Amount

	local PlayerData = Network:Fetch("GetClientData")

	if PlayerData[Currency] < Cost then
		Network:Fetch(Player, "DisplayNewItem", {
			Type = "Message",
			Message = "You cannot afford this egg!",
			TextColor = Color3.fromRGB(255, 60, 60)
		})
		
		return "Insufficient funds"
	end

	return true
end

local ValidAmounts = {
	1, 2, 3, 4, 5, 6
}

function EggManager:CanPurchase()
	local Egg = self.CurrentEgg

	if not Egg then
		return 0
	end
	
	for i = #ValidAmounts, 1, -1 do
		local v = ValidAmounts[i]
		
		local PurchaseState = EggModule:CanPurchaseEgg(nil, Egg.Name, v)

		if PurchaseState == true then
			return v
		end
	end

	return 0
end

function EggManager:AttemptPurchase(Amount)
	local Amount = Amount or self:CanPurchase()
	local Egg = self.CurrentEgg
	
	if not Egg then
		return
	end
	
	local EggInfo = self:LoadEggInfo(Egg)
	local BillboardGui = EggInfo and EggInfo.BillboardGui
	
	local Enabled = BillboardGui and BillboardGui.Enabled
	
	if not Enabled then
		return
	end
	
	local EggName = Egg.Name
	
	for i = Amount, 1, -1 do
		local _amt = ValidAmounts[i]

		local PurchaseState = self:GetPurchaseState(_amt)
		
		if PurchaseState == true then
			return Network:Post("PurchaseEgg", EggName, _amt)
		end
		
		if PurchaseState and PurchaseState ~= "Insufficient Funds" then
			continue
		end
		
		EggInfo.Auto = false
	end
end

function EggManager:UpdateWheelKeybinds(Wheel)
	local WheelInfo = self:LoadWheelInfo(Wheel)
	local Button = WheelInfo.Button

	WheelKeybinds:RenderKeybinds()

	WheelKeybinds:NewButton(Button.Name, Button)

	local WheelKeybinds = WheelManager.Keybinds

	for Title, Data in WheelKeybinds do
		local userDevice = InputManager:GetUserDevice()

		local BContent = Button.Content
		local BLetter = BContent.Letter
		local BIcon = BContent.IconLetter
		local BTitle = BContent.Title

		local kBind = Data.Binds[userDevice].Name

		BLetter.Visible = userDevice == "PC"
		BIcon.Visible = not BLetter.Visible
		BIcon.Image = Data.Icons[userDevice][kBind]
		BLetter.Text = kBind
		BTitle.Text = "Spin"
	end
end

function EggManager:UpdateKeybinds(Egg)
	local EggInfo = self:LoadEggInfo(Egg)
	local Frame = EggInfo.Frame
	
	local Content = Frame.Content
	local Buttons = Content.Buttons
	
	Keybinds:RenderKeybinds()
	
	for _, Button in Buttons:GetChildren() do
		if not Button:IsA("TextButton") then
			continue
		end
		
		Keybinds:NewButton(Button.Name, Button)
	end
	
	local Keybinds = self.Keybinds
	
	for Title, Data in Keybinds do
		local Button = Buttons:FindFirstChild(Title)
		
		local userDevice = InputManager:GetUserDevice()
		
		local BContent = Button.Content
		local BLetter = BContent.Letter
		local BIcon = BContent.IconLetter
		
		local kBind = Data.Binds[userDevice].Name

		BLetter.Visible = userDevice == "PC"
		BIcon.Visible = not BLetter.Visible
		BIcon.Image = Data.Icons[userDevice][kBind]
		BLetter.Text = kBind
	end
end

function EggManager:AdornEggGUI(Egg)
	local EggInfo = self:LoadEggInfo(Egg)
	
	local BillboardGui = EggInfo.BillboardGui
	local Frame = EggInfo.Frame
	local EggData = EggInfo.EggData
	
	if not BillboardGui then
		return
	end
	
	if BillboardGui.Adornee then
		return
	end
	
	local Settings = self.Settings
	
	BillboardGui.Parent = Interface
	BillboardGui.Name = Egg.Name .. " Interface"
	BillboardGui.Adornee = Egg.PrimaryPart
	BillboardGui.MaxDistance = math.huge
	
	Frame.Parent = BillboardGui
	Frame.Visible = true
	
	BillboardGui:GetPropertyChangedSignal("Enabled", function()
		local State = BillboardGui.Enabled
		
		task.delay(.05, function()
			if BillboardGui.Enabled ~= State then
				return
			end
			
			Frame.Visible = State
		end)
	end)
	
	local Content = Frame.Content
	local Buttons = Content.Buttons
	
	local cCost = Content.Cost
	local eCost = EggData.Cost
	
	local cCurrency, cAmount = cCost.Currency, cCost.Amount
	local eCurrency, eAmount = unpack(eCost)
	
	local CurrencyData = CurrencyModule[eCurrency]
	local CurrencyColor = CurrencyData.Color or Color3.fromRGB(255, 255, 255)
	
	local cTitle = Content.Title
	local cText = cTitle.Text
	
	local cIcon = cTitle.Icon
	
	cIcon.Image = ImageModule(Egg.Name)
	cText.Label.Text = Egg.Name
	cText.Stroke.Text = Egg.Name
	
	cCurrency.Image = ImageModule(eCurrency)
	cAmount.Text = Short:AddSuffix(eAmount)
	cAmount.TextColor3 = CurrencyColor
	
	self:UpdateMaxPurchase()
	self:UpdateStats()
	self:UpdateKeybinds(Egg)
end

function EggManager:CreateEggGUI(Egg)
	local EggInfo = self:LoadEggInfo(Egg)
	
	if not EggInfo then
		return
	end
	
	if EggInfo.BillboardGui then
		return
	end
	
	EggInfo.BillboardGui = Temp_BillboardGui:Clone()
	EggInfo.Frame = Temp_EggFrame:Clone()
	
	self:CreateEggController(Egg)
	self:AdornEggGUI(Egg)
end

function WheelManager:EnterWheel(...)
	if not EggManager.CurrentWheel then
		return
	end
	
	local WheelInfo = EggManager:LoadWheelInfo(EggManager.CurrentWheel)
	WheelInfo.WheelMode = true
	
	GuiService:OpenFrame(WheelFrame)
	
	Network:Fetch("ToggleInterface", false)
	
	return WheelService:EnterWheel(EggManager.CurrentWheel.Name, ...)
end

function WheelManager:ExitWheel()
	
	if WheelService.WheelInfo.Spinning then
		return
	end
	
	GuiService:CloseFrame(WheelFrame)
	WheelService:ExitWheel()
	
	Network:Fetch("ToggleInterface", true)
	
	local WheelInfo = EggManager:LoadWheelInfo(EggManager.CurrentWheel) or {}
	WheelInfo.WheelMode = false
end

function EggManager:AdornWheelGUI(Wheel)
	local WheelInfo = self:LoadWheelInfo(Wheel)
	local BillboardGui = WheelInfo.BillboardGui
	local Button = WheelInfo.Button

	if not BillboardGui then
		return
	end

	if BillboardGui.Adornee then
		return
	end

	BillboardGui.Parent = GuiService.Interface
	BillboardGui.Name = Wheel.Name .. " Interface"
	BillboardGui.Adornee = WheelInfo.Hotkey
	BillboardGui.MaxDistance = math.huge

	Button.Parent = BillboardGui

	BillboardGui:GetPropertyChangedSignal("Enabled"):Connect(function()
		Button.Visible = BillboardGui.Enabled
	end)
	
	AnimationService:CreateButton(Button, function()
		WheelService:EnterWheel(Wheel.Name)
	end)
end

function EggManager:CreateWheelGUI(Wheel)
	local WheelInfo = self:LoadWheelInfo(Wheel)

	if WheelInfo.BillboardGui then
		return
	end

	WheelInfo.BillboardGui = Temp_BillboardGui:Clone()
	WheelInfo.Button = script.PromptButton:Clone()
	WheelInfo.Button.Name = "E"
	WheelInfo.Button.Parent = WheelInfo.BillboardGui
	
	self:AdornWheelGUI(Wheel)
end

function EggManager:GetEggHoverPower()
	local Settings = self.Settings

	local HoverSpeed = Settings.HoverSpeed
	local HoverStrength = Settings.HoverStrength
	
	local Offset = tick()

	return math.sin(Offset / HoverSpeed) * HoverStrength
end

function EggManager:ManageEggHover(Egg)
	local Model = Egg:WaitForChild("Model")
	local PrimaryPart = Model and Model.PrimaryPart

	if not PrimaryPart then
		return
	end

	local Origin = Model:GetPivot()
	local Radius = 0
	
	local Settings = self.Settings
	
	local HoverSpeed = Settings.HoverSpeed
	local HoverStrength = Settings.HoverStrength
	
	local RotationStrength = Settings.RotationStrength

	RunService.RenderStepped:Connect(function(dt)
		Radius += (dt * RotationStrength)
		
		local NewPower = Origin * CFrame.new(
			0,
			self:GetEggHoverPower(),
			0
		)
		
		local NewPivot = NewPower * CFrame.Angles(
			0,
			math.rad(Radius),
			0
		)

		Model:PivotTo(NewPivot)
	end)
end

function EggManager:CreateEgg(Egg)
	self:ManageEggHover(Egg)
	self:CreateEggGUI(Egg)
end

function EggManager:Initialize()
	for _, Egg in Eggs:GetChildren() do
		self:CreateEgg(Egg)
	end
	
	Eggs.ChildAdded:Connect(function(Egg)
		self:CreateEgg(Egg)
	end)
	
	for _, Wheel in Wheels:GetChildren() do
		self:CreateWheelGUI(Wheel)
	end

	Wheels.ChildAdded:Connect(function(Wheel)
		self:CreateWheelGUI(Wheel)
	end)
	
	self:CreateEggController()
	self:CreateWheelController()
	
	AnimationService:CreateButton(WheelFrame.Exit, function()
		WheelManager:ExitWheel()
	end)
	
	AnimationService:CreateButton(WheelFrame.Spin, function()
		WheelService:SpinWheel()
	end)
	
	InputManager.ControllerConnected:Connect(function()
		local Egg = self.CurrentEgg
		
		if not Egg then
			return
		end
		
		self:UpdateKeybinds(Egg)
	end)
	
	InputManager.ControllerDisconnected:Connect(function()
		local Egg = self.CurrentEgg

		if not Egg then
			return
		end

		self:UpdateKeybinds(Egg)
	end)
end

EggManager:Initialize()

return EggManager