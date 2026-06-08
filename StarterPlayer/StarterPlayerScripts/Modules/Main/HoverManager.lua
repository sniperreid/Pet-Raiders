local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local MaidClass = Services.get("MaidClass")
local RunService = Services.get("RunService")
local AnimationService = Services.get("AnimationService")
local TextAnimationService = Services.get("TextAnimationService")
local PetModule = Services.get("PetModule")
local Roblox = Services.get("Roblox")
local Network = Services.get("Network")
local Short = Services.get("Short")
local EggModule = Services.get("EggModule")
local PetBuffService = Services.get("PetBuffService")
local ImageModule = Services.get("ImageModule")
local CurrencyModule = Services.get("CurrencyModule")
local BoostModule = Services.get("BoostModule")
local ItemModule = Services.get("ItemModule")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local PlayerGui = Player.PlayerGui

local HoverManager = {}
HoverManager.__index = HoverManager
HoverManager.Serials = {}

function HoverManager:Destroy()
	local Maid = self.Maid
	
	if Maid then
		Maid:Clean()
	end
	
	table.clear(self)
end

function HoverManager:CreateBasicData(PetName)
	local NewDisplay = table.clone(self.Settings.DefaultDisplay)
	
	NewDisplay.Name = PetName
	
	return NewDisplay
end

function HoverManager:GetPet(PetID)
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Pets = PlayerData.Pets or {}

	if self.Data[PetID] then
		return self.Data[PetID]
	end
	
	if PetModule[PetID] then -- from egg data, just use basic generated pet data
		return self:CreateBasicData(PetID)
	end

	for i, Pet in Pets do
		if Pet.ID ~= PetID then
			continue
		end

		return Pet
	end
end

function HoverManager:GetSerial(p)
	if self.Serials[p] then return self.Serials[p] end
	
	self.Serials[p] = Network:Invoke("GetSerialPets", p)
	
	task.delay(10, function()
		self.Serials[p] = nil
	end)
	
	return self.Serials[p]
end

function HoverManager:SubscribeData(a, b)
	self.Data[a] = b
end

function HoverManager:LoadEggInfo(Subject)
	local Subject = Subject or self.Subject
	local Frame = self.HoverFrame

	if not Subject then
		return
	end

	self:SetSubject(Subject)
	
	local EggName = Subject.Name
	
	local PlayerData = Network:Fetch("GetClientData")
	local Eggs = PlayerData.Eggs
	
	local EggAmount = Eggs[EggName] or 0

	local Settings = self.Settings

	local HoverContent = Frame.Content
	local HoverInfo = HoverContent.Info

	if not HoverInfo:FindFirstChild("EggName") then
		return
	end

	HoverInfo.EggName.Text = EggName
	HoverInfo.EggRarity.Text = "Exclusive"
	HoverInfo.Help.Text = Settings.HelpLabel or HoverInfo.Help.Text

	TextAnimationService:AnimateText(HoverInfo.EggRarity, "Exclusive")
	
	local EggManager = Services.get("EggManager")
	
	EggManager:LoadRarityGrid(EggName, HoverInfo.Pets, true, true)
end

function HoverManager:LoadHoverInfo(Subject)
	local Subject = Subject or self.Subject
	local Frame = self.HoverFrame

	if not Subject then
		return
	end
	
	local Settings = self.Settings
	
	if Settings.Boost then
		local Info = self.HoverFrame.Content:FindFirstChild("Info")

		if not Info then
			return
		end

		local BoostData = BoostModule[Subject.Name]
		
		Info.Perks.Text = BoostData.Info or "Unknown"
		Info.Rarity.Text = BoostData and BoostData.Rarity or "Unknown"
		Info.Boost.Text = Subject.Name or "Unknown"
		
		TextAnimationService:AnimateText(Info.Rarity, BoostData.Rarity or "Common")

		return
	end
	
	if Settings.isItem then
		local Info = self.HoverFrame.Content:FindFirstChild("Info")

		if not Info then
			return
		end
		
		local ItemData = ItemModule[Subject.Name]
		
		if not ItemData then
			return
		end
		
		local Rarity = ItemData.Rarity
		
		Info.ItemName.Text = Subject.Name or "Unknown"
		Info.Help.Text = Settings.HelpLabel or "Unknown"
		Info.ItemRarity.Text = Rarity or "Unknown"
		
		TextAnimationService:AnimateText(Info.ItemRarity, Rarity)
		
		return
	end
	
	if Settings.isEgg then
		return self:LoadEggInfo(Subject)
	end

	local PetID = Subject.Name
	local PetData = self:GetPet(PetID)
	
	if not PetData then
		return self:SetSubject()
	end
	
	self:SetSubject(Subject)
	
	local PetName = PetData.Name
	local PetTier = PetData.Tier
	
	if Subject:GetAttribute("Tier") then
		PetTier = Subject:GetAttribute("Tier")
	end

	local pData = PetModule[PetName] or PetModule.Doggy
	local PetRarity = pData.Rarity

	local HoverContent = Frame:FindFirstChild("Content")
	
	if not HoverContent then
		return
	end
	
	local HoverInfo = HoverContent.Info

	local Display = PetTier == "Normal" and PetName or ("%s%s"):format(PetTier, PetName)

	local AmountExisting = self:GetSerial(Display)
	
	if not HoverInfo:FindFirstChild("PetExist") then
		return
	end
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Index = PlayerData.Index or {}

	local isntInIndex = Settings.AccountForIndex and table.find(Index, Display) == nil

	HoverInfo.PetExist.Text = ("%s Exist"):format(AmountExisting or 0)
	HoverInfo.PetName.Text = isntInIndex and "???" or PetName
	HoverInfo.PetRarity.Text = PetRarity
	HoverInfo.Help.Text = isntInIndex and "Undiscovered" or Settings.HelpLabel or HoverInfo.Help.Text

	HoverInfo.PetExist.Visible = true

	TextAnimationService:AnimateText(HoverInfo.PetRarity, PetRarity)
	TextAnimationService:AnimateText(HoverInfo.PetName, PetTier)
	
	if Settings.AccountForIndex then
		return
	end
	
	for i, v in Roblox:GetChildrenOfClass(HoverInfo.Stats, "Frame") do
		v:Destroy()
	end
	
	local PetBuffs = PetBuffService:GetLocalBuff(PetData)
	
	local StatIndex = {
		"Attack",
		"Speed"
	}
	
	for Currency, Multi in PetBuffs do
		local Template = script.StatTemplate:Clone()
		
		Template.Parent = HoverInfo.Stats
		Template.LayoutOrder = table.find(StatIndex, Currency) or CurrencyModule[Currency].Index or 1
		
		local s = Currency == "Speed" and "+" or "x"
		
		Template.Amount.Text = ("%s%s"):format(s, Short:AddSuffix(Multi))
		Template.Icon.Image = ImageModule(Currency)
		
		Template.Amount.TextColor3 = (CurrencyModule[Currency] or {Color=Color3.new(1,1,1)}).Color
	end
end

function HoverManager:HoverSetToMouse(Subject)
	local Subject = Subject or self.Subject
	local PFrame = self.Frame
	local Frame = self.HoverFrame

	if not Subject then
		return
	end
	
	local Grid = Subject.Parent
	
	if not Grid then
		return self:SetSubject()
	end

	local SubjectPos = Subject.AbsolutePosition
	local GridPos = Grid.AbsolutePosition
	local FramePos = PFrame.AbsolutePosition
	
	local SubjectSize = Subject.AbsoluteSize
	local FrameSize = Frame.AbsoluteSize
	
	local Settings = self.Settings
	local Sel = not GuiService.SelectedObject

	local X, Y = Sel and Mouse.X or SubjectPos.X + (SubjectSize.X/2), Sel and Mouse.Y or SubjectPos.Y + (SubjectSize.Y/2)
	
	local XProgress = X - SubjectPos.X
	local YProgress = Y - SubjectPos.Y
	
	if Settings.Boost and not Settings.Prize then
		Frame.Position = UDim2.fromOffset(
			SubjectPos.X - FramePos.X + (SubjectSize.X / 2) - (FrameSize.X / 2) + 30,
			SubjectPos.Y - FramePos.Y - FrameSize.Y + 10
		)

		return
	end
	
	Frame.Position = UDim2.fromOffset(
		SubjectPos.X - FramePos.X + (SubjectSize.X / 2) + XProgress,
		SubjectPos.Y - FramePos.Y + YProgress
	)
end

function HoverManager:ToggleHover(State, Subject)
	local v = self.HoverFrame
	
	if v.Visible == State then
		if State then
			return self:SetSubject(Subject)
		end

		return
	end
	
	v.Visible = State

	if not State then
		return
	end

	AnimationService:AnimateUI_Open(
		v,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0.8, 1, 5
	);

	self:LoadHoverInfo(Subject)
end

function HoverManager:RenderSelection()
	if not self then
		return
	end
	
	if not self.Settings then
		return
	end
	
	local Grid = self.Grid
	
	local Settings = self.Settings
	local AccountForIndex = Settings.AccountForIndex
	
	local X, Y = Mouse.X, Mouse.Y
	local ObjectsAtPosition = PlayerGui:GetGuiObjectsAtPosition(X, Y)

	local PetsInView, PetTemp = false, nil
	
	if not Grid then
		return
	end

	for _, Pet in Roblox:GetDescendantsOfClass(Grid, "GuiButton") do
		if Settings.isItem then
			break
		end
		
		if Settings.Boost then
			break
		end
		
		local PetData = self:GetPet(Pet.Name)
		
		if not PetData then
			continue
		end
		
		local Sel = GuiService.SelectedObject
		
		PetsInView, PetTemp = table.find(ObjectsAtPosition, Pet) and true or false, Pet
		PetsInView = Sel and Sel == Pet or PetsInView

		if not PetsInView then
			continue
		end

		break
	end
	
	for _, Egg in Roblox:GetDescendantsOfClass(Grid, "GuiButton") do
		if Settings.isItem then
			break
		end
		
		local EggName = Egg.Name

		if not EggName then
			continue
		end
		
		if not EggModule[EggName] then
			continue
		end
		
		local Sel = GuiService.SelectedObject

		PetsInView, PetTemp = table.find(ObjectsAtPosition, Egg) and true or false, Egg
		PetsInView = Sel and Sel == Egg or PetsInView

		if not PetsInView then
			continue
		end

		break
	end
	
	for _, Item in Roblox:GetDescendantsOfClass(Grid, "GuiButton") do
		if not Settings.isItem then
			break
		end
		
		local Data = ItemModule[Item.Name]

		if not Data then
			continue
		end

		local Sel = GuiService.SelectedObject

		PetsInView, PetTemp = table.find(ObjectsAtPosition, Item) and true or false, Item
		PetsInView = Sel and Sel == Item or PetsInView

		if not PetsInView then
			continue
		end

		break
	end
	
	for _, Boost in Roblox:GetDescendantsOfClass(Grid, "GuiButton") do
		if not Settings.Boost then
			break
		end
		
		local Data = BoostModule[Boost.Name]
		
		if not Data then
			continue
		end
		
		local Sel = GuiService.SelectedObject

		PetsInView, PetTemp = table.find(ObjectsAtPosition, Boost) and true or false, Boost
		PetsInView = Sel and Sel == Boost or PetsInView

		if not PetsInView then
			continue
		end

		break
	end

	self:ToggleHover(
		PetsInView,
		PetTemp
	)
end

function HoverManager:Render()
	local Maid = self.Maid
	local Frame = self.Frame
	
	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		if not Frame.Visible then
			return
		end
		
		self:HoverSetToMouse()
		self:RenderSelection()
	end))
end

function HoverManager:SetSubject(Subject)
	if self.Subject == Subject then
		return
	end
	
	self.Subject = Subject
	self:LoadHoverInfo()
end

function HoverManager:ChangeSettings(Setting, Value)
	self.Settings[Setting] = Value
end

function HoverManager:Bind(Frame, Grid, Settings)
	local Settings = Settings or {}
	
	Settings.DefaultDisplay = {
		ID = "0",
		Name = "Doggy",
		Tier = "Normal",
		Exp = 0,
		Level = 1,
		Locked = false,
		Equipped = false,
		Serial = 0
	}
	
	local HoverFrame
	
	if Settings.Boost then
		HoverFrame = script.BoostHoverFrame:Clone()
		HoverFrame.Size = Settings.Prize and UDim2.fromScale(.3, .3) or UDim2.fromScale(.125, .125)
	elseif Settings.isItem then
		HoverFrame = script.ItemHoverFrame:Clone()
	elseif Settings.isEgg then
		HoverFrame = script.EggHoverFrame:Clone()
	elseif Settings.AccountForIndex then
		HoverFrame = script.IndexHoverFrame:Clone()
	else
		HoverFrame = script.HoverFrame:Clone()
	end
	
	HoverFrame.Parent = Frame

	local SELF = setmetatable({
		HoverFrame = HoverFrame,
		Frame = Frame,
		Grid = Grid,
		Settings = Settings or {},
		Subject = nil,
		Maid = MaidClass.new(),
		Data = {},
	}, HoverManager)
	
	SELF.Maid:GiveTask(HoverFrame)
	
	local RenderConnection = nil

	local function BeginRender()
		if RenderConnection then
			return
		end
		
		if not SELF then
			return
		end
		
		if not SELF.Maid then
			SELF = nil
			
			return
		end

		RenderConnection = RunService.RenderStepped:Connect(function()
			if not Frame.Visible then
				return
			end

			SELF:HoverSetToMouse()
			SELF:RenderSelection()
		end)

		SELF.Maid:GiveTask({
			RenderConnection,
			
			function()
				RenderConnection = nil
			end
		})
	end

	local function EndRender()
		if RenderConnection then
			RenderConnection:Disconnect()
			RenderConnection = nil
		end
	end
	
	Frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if Frame.Visible then
			BeginRender()
		else
			EndRender()
		end
	end)
	
	Frame.Destroying:Once(function()
		SELF:Destroy()
	end)
	
	if Frame.Visible then
		BeginRender()
	end
	
	return SELF
end

return HoverManager