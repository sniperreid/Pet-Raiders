local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local CurrencyModule = Services.get("CurrencyModule")
local Pager = Services.get("Pager")
local Roblox = Services.get("Roblox")
local AnimationService = Services.get("AnimationService")
local RunService = Services.get("RunService")
local PetModule = Services.get("PetModule")
local TextAnimationService = Services.get("TextAnimationService")
local HoverManager = Services.get("HoverManager")
local SortMethods = Services.get("SortMethods")
local PetBuffService = Services.get("PetBuffService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local GuiService
local Interface
local Frames
local InventoryFrame
local Content

local Tabs
local PetTab

local ConfirmDelete

local MultiMode
local LockMode

local Grid
local PageFlip

local Top
local Search
local Bottom

local Buttons
local Sort

local sContent
local sMain

local Input

local GuiUtil

local RecentPage
local HoverRender

local Inventory = {}

Inventory.DeleteMode = false
Inventory.LockMode = false
Inventory.MultiDeleteQueue = {}
Inventory.LockQueue = {}
Inventory.Zoomed = false
Inventory.SortMode = "Coins"
Inventory.GridSizes = {
	[true] = UDim2.fromScale(0.15, 0.25),
	[false] = UDim2.fromScale(0.187, 0.3),
}

function Inventory:GetSort(Method)
	if self.Sorter then
		return self.Sorter
	end
	
	self.Sorter = SortMethods.new(Method)
	
	return self.Sorter
end

function Inventory:Sort(Pets)
	local Method = self:GetSort("Pets")
	
	Method:addWhitelist(self.MultiDeleteQueue)
	
	return Method:Sort(Pets)
end

function Inventory:GetPets()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Pets = PlayerData.Pets or {}

	self:Sort(Pets)

	return Pets
end

function Inventory:UpdateGrid()
	local Sizes = self.GridSizes

	local Size = Sizes[self.Zoomed]

	Grid.UIGridLayout.CellSize = Size
end

function Inventory:ZoomGrid()
	self.Zoomed = not self.Zoomed

	local img = self.Zoomed and "ZoomIn" or "ZoomOut"

	-- local zContent = ZoomButton.Content

	-- zContent.Icon.Image = ImageModule(img)

	self:UpdateGrid()
end

function Inventory:BouncerAllowed(v, List)
	local isInList = false

	for _, p in List do
		if isInList then
			break
		end

		isInList = p.ID == v.Name
	end
	
	return isInList
end

function Inventory:Bouncer(List)
	for _, v in Roblox:GetChildrenOfClass(Grid, "ImageButton") do
		if self:BouncerAllowed(v, List) then
			continue
		end

		v:Destroy()
	end
end

function Inventory:GetPet(PetID)
	local Pets = self:GetPets()
	
	for i, Pet in Pets do
		if Pet.ID ~= PetID then
			continue
		end
		
		return Pet
	end
end

function Inventory:ConfirmDelete()
	local Pets = self.MultiDeleteQueue or {}
	
	if not Pets[1] then
		return -- no pets stored in array.
	end
	
	local PetsStored = {}
	local ConfirmContent = ConfirmDelete.Content
	
	for i, PetID in Pets do
		local Pet = self:GetPet(PetID)
		local PetName = Pet.Name
		local PetTier = Pet.Tier

		local Display = PetTier ~= "Normal" and ("%s %s"):format(PetTier, PetName) or PetName
		local Stored = PetsStored[Display] or 0
		
		PetsStored[Display] = Stored + 1
	end
	
	local NewDisplay = ""
	local UseComma = false
	
	for Display, Amount in PetsStored do
		local Comma = UseComma and ", " or ""
		NewDisplay = ("%s%sx%d %s"):format(NewDisplay, Comma, Amount, Display)
		
		UseComma = true
	end
	
	ConfirmDelete.Visible = true

	AnimationService:AnimateUI_Open(
		ConfirmDelete,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0.8, 1, 5
	)
	
	local cPets = ConfirmContent.Pets
	
	local ConfirmButtons = ConfirmContent.Buttons
	
	cPets.Text = NewDisplay
	
	AnimationService:CreateButton(ConfirmButtons.Confirm, function()
		Network:Post("DeletePets", Pets)

		ConfirmDelete.Visible = false
		
		table.clear(Pets)
		table.clear(self.MultiDeleteQueue)
	end)

	AnimationService:CreateButton(ConfirmButtons.Cancel, function()
		ConfirmDelete.Visible = false
		
		table.clear(Pets)
		table.clear(self.MultiDeleteQueue)
	end)
end

function Inventory:ConfirmLock()
	local Pets = self.LockQueue or {}
	
	Network:Post("LockPets", Pets)

	table.clear(self.LockQueue)
end

function Inventory:isMultiDeleting(PetID)
	return table.find(self.MultiDeleteQueue, PetID)
end

function Inventory:isLocking(PetID)
	return table.find(self.LockQueue, PetID)
end

function Inventory:AddToDeleteQueue(PetID)
	local Got = self:isMultiDeleting(PetID)
	
	if Got then
		table.remove(
			self.MultiDeleteQueue,
			Got
		)
	else
		table.insert(
			self.MultiDeleteQueue,
			PetID
		)
	end
	
	local Temp = Grid:FindFirstChild(PetID)
	local tContent = Temp and Temp.Content
	local tel = tContent and tContent.Selected or {}
	
	tel.Visible = not Got and true or false
end

function Inventory:AddToLockQueue(PetID)
	local Got = self:isLocking(PetID)

	if Got then
		table.remove(
			self.LockQueue,
			Got
		)
	else
		table.insert(
			self.LockQueue,
			PetID
		)
	end

	local Temp = Grid:FindFirstChild(PetID)
	local tContent = Temp and Temp.Content
	local tel = tContent and tContent.LockSelected or {}

	tel.Visible = not Got and true or false
end

function Inventory:Clear()
	return Roblox:ClearChildrenOfClass(Grid, "ImageButton")
end

function Inventory:Load(List)
	if not InventoryFrame.Visible or not PetTab.Visible then
		return
	end
	
	local Pager = self.Pager
	local Page = Pager.Page

	local MaxPage = Pager:GetMaxPage()

	PageFlip.Title.Text = (MaxPage > 1) and ("Page %d"):format(Page) or ""
	PageFlip.Next.Visible = Page < MaxPage
	PageFlip.Previous.Visible = Page > 1
	
	local Equipped = 0
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Pets = PlayerData.Pets or {}
	
	for i, Pet in Pets do
		Equipped += (Pet.Equipped and 1 or 0)
	end
	
	self:Bouncer(List)

	for i, Pet in List do
		local PetID = Pet.ID
		
		local Template = GuiUtil:CreatePet(Pet, Grid)
		local tContent = Template.Content

		tContent.Selected.Visible = self:isMultiDeleting(PetID) and true or false
		tContent.LockSelected.Visible = self:isLocking(PetID) and true or false
		tContent.LockSelected.Image = Pet.Locked and "rbxassetid://140491474317775" or "rbxassetid://133034891143156"
		Template.LayoutOrder = i
		
		local PetData = self:GetPet(PetID)
		
		AnimationService:CreateButton(Template, function()
			if self.DeleteMode then
				return self:AddToDeleteQueue(PetID)
			end
			
			if self.LockMode then
				return self:AddToLockQueue(PetID)
			end
			
			PetData = self:GetPet(PetID)
			
			if not PetData then
				self:Clear()
				
				return self:Update()
			end
			
			Network:Post("SetEquip", PetID, not PetData.Equipped)
		end)
	end
	
	for i, v in Bottom.Equipped.Text:GetChildren() do
		v.Text = Equipped .. "/" .. PetBuffService:GetMaxEquip()
	end
	
	for i, v in Bottom.Storage.Text:GetChildren() do
		v.Text = #Pets .. "/" .. PetBuffService:GetMaxStorage()
	end
end

function Inventory:DisconnectHover()
	if not HoverRender then
		return
	end

	HoverRender:Destroy()
	HoverRender = nil
end

function Inventory:LoadHover()
	HoverRender = HoverManager:Bind(
		InventoryFrame,
		Grid
	)
end

function Inventory:LoadHoverInfo()
	if not HoverRender then
		return
	end
	
	HoverRender:LoadHoverInfo()
end

function Inventory:Update()
	local Pets = self:GetPets()
	
	self:LoadHoverInfo()
	
	return self.Pager:UpdateList(Pets)
end

function Inventory:DeleteAll()
	local Pets = self:GetPets() or {}
	
	local Include = {
		"Common",
		"Unique",
		"Rare",
		"Epic"
	}
	
	for i, v in Pets do
		local PetData = PetModule[v.Name]
		local PetRarity = PetData.Rarity
		
		if not table.find(Include, PetRarity) then
			continue
		end
		
		if v.Equipped then
			continue
		end
		
		if v.Locked then
			continue
		end
		
		table.insert(self.MultiDeleteQueue, v.ID)
	end
	
	return self:ConfirmDelete()
end

function Inventory:Create()
	local Pets = self:GetPets()
	
	self.Pager = Pager.new(Pets, 32, function(page, ...)
		return self:Load(...)
	end)
	
	self.Pager:SetIndexer("Name")

	task.delay(.1, function()
		self:Clear()
		self:Update()
	end)
	
	Input:GetPropertyChangedSignal("Text"):Connect(function()
		self.Pager:Search(Input.Text)
	end)

	AnimationService:CreateButton(PageFlip.Next, function()
		self.Pager:NextPage()
	end)

	AnimationService:CreateButton(PageFlip.Previous, function()
		self.Pager:PreviousPage()
	end)
	
	-- Function Buttons
	
	AnimationService:CreateButton(Buttons.Lock, function()
		if self.LockMode then
			self:ConfirmLock()
		end
		
		self.LockMode = not self.LockMode
		
		LockMode.Visible = self.LockMode
	end)
	
	AnimationService:CreateButton(Buttons.DeleteAll, function()
		self:DeleteAll()
	end)
	
	AnimationService:CreateButton(Buttons.EquipBest, function()
		Network:Post("EquipBest", self.SortMode)
	end)
	
	AnimationService:CreateButton(Buttons.MultiDelete, function()
		if self.DeleteMode then
			self:ConfirmDelete()
		end
		
		self.DeleteMode = not self.DeleteMode
		
		MultiMode.Visible = self.DeleteMode
	end)
	
	AnimationService:CreateButton(Buttons.UnequipAll, function()
		Network:Post("UnequipAll")
	end)
	
	-- Sort Buttons
	
	for i, v in Roblox:GetChildrenOfClass(Sort, "GuiButton") do
		AnimationService:CreateButton(v, function()
			self.SortMode = v.Name
			
			SortMethods:SubscribeStat(v.Name)
			
			task.delay(.1, function()
				self:Update()
			end)
		end)
	end
	
	PetTab:GetPropertyChangedSignal("Visible"):Connect(function()
		if not PetTab.Visible then
			return self:Clear(), self:DisconnectHover()
		end
		
		ConfirmDelete.Visible = false
		self.Pager:Update()
		
		self:LoadHover()
	end)
	
	InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		self.DeleteMode = false
		self.LockMode = false
		
		ConfirmDelete.Visible = false
		MultiMode.Visible = false
		LockMode.Visible = false
		
		if not InventoryFrame.Visible then
			return self:Clear(), self:DisconnectHover()
		end

		ConfirmDelete.Visible = false
		
		self.Pager:Update()
		
		self:LoadHover()
	end)
end

return setmetatable(Inventory, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		InventoryFrame = Frames.InventoryFrame
		Content = InventoryFrame.Content
		
		Tabs = Content.Tabs
		PetTab = Tabs.Pets
		
		ConfirmDelete = PetTab.ConfirmDelete
		
		MultiMode = PetTab.MultiMode
		LockMode = PetTab.LockMode
		
		Grid = PetTab.Grid
		PageFlip = PetTab.PageFlip
		
		Buttons = PetTab.Buttons
		Sort = PetTab.Sort
		
		Top = PetTab.Top
		Bottom = PetTab.Bottom
		
		Search = Top.Search
		sContent = Search.Content
		Input = sContent.Input
		
		GuiUtil = GuiService.GuiUtil

		self:Create()
		
		return self
	end,
})