local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local CurrencyModule = Services.get("CurrencyModule")
local Roblox = Services.get("Roblox")
local AnimationService = Services.get("AnimationService")
local RunService = Services.get("RunService")
local EggModule = Services.get("EggModule")
local TextAnimationService = Services.get("TextAnimationService")
local HoverManager = Services.get("HoverManager")
local SortMethods = Services.get("SortMethods")
local ImageModule = Services.get("ImageModule")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local GuiService
local Interface
local Frames
local InventoryFrame
local EggOpenFrame
local Content

local Tabs
local EggTab

local Grid

local GuiUtil

local HoverRender

local Inventory = {}

function Inventory:GetEggs()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Eggs = PlayerData.Eggs or {}

	return Eggs
end

function Inventory:Load(List)
	if not InventoryFrame.Visible or not EggTab.Visible then
		return
	end
	
	for EggName, EggAmount in List do
		local Template = GuiUtil:CreateEgg(EggName, EggAmount, Grid)
		local tContent = Template.Content
		
		Template.LayoutOrder = EggAmount
		
		AnimationService:CreateButton(Template, function()
			self:PromptEggOpen(EggName)
		end)
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
		Grid,
		{
			HelpLabel = "Click to Open",
			isEgg = true
		} 
	)
end

function Inventory:LoadHoverInfo()
	if not HoverRender then
		return
	end

	HoverRender:LoadHoverInfo()
end

function Inventory:Update()
	local Eggs = self:GetEggs()

	self:LoadHoverInfo()

	return self:Load(Eggs)
end

function Inventory:Clear()
	return Roblox:ClearChildrenOfClass(Grid, "ImageButton")
end

local ValidAmounts = {
	1, 3, 6
}

function Inventory:CanPurchase(Egg)
	local Eggs = self:GetEggs()
	
	local Amount = Eggs[Egg] or 0
	
	for i = #ValidAmounts, 1, -1 do
		local v = ValidAmounts[i]
		
		if v > Amount then
			continue
		end

		return v
	end

	return 0
end

function Inventory:PromptEggOpen(Egg)
	GuiService:OpenFrame(EggOpenFrame)
	
	local _Content = EggOpenFrame.Content
	local _Buttons = _Content.Buttons
	
	local MaxPurchase = self:CanPurchase(Egg)
	
	for i, v in Roblox:GetChildrenOfClass(_Buttons, "GuiButton") do
		v:Destroy()
	end
	
	for i = #ValidAmounts, 1, -1 do
		local v = ValidAmounts[i]
		
		if v > MaxPurchase then
			continue
		end
		
		local OpenEggButton = GuiUtil:CreateOpenEggButton(v, _Buttons)
		
		OpenEggButton.LayoutOrder = v
		
		AnimationService:CreateButton(OpenEggButton, function()
			Network:FireServer("OpenExclusiveEgg", Egg, v)
		end)
	end
	
	_Content.Icon.Image = ImageModule(Egg)
end

function Inventory:Create()
	EggTab:GetPropertyChangedSignal("Visible"):Connect(function()
		self:DisconnectHover()
		
		if not EggTab.Visible then
			return self:Clear()
		end
		
		self:Update()
		
		self:LoadHover()
	end)
	
	InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		self:DisconnectHover()
		
		if not InventoryFrame.Visible then
			return self:Clear()
		end

		self:Update()
		
		self:LoadHover()
	end)
end

return setmetatable(Inventory, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		InventoryFrame = Frames.InventoryFrame
		EggOpenFrame = Frames.EggOpenFrame
		Content = InventoryFrame.Content
		
		Tabs = Content.Tabs
		EggTab = Tabs.Eggs
		
		Grid = EggTab.Grid
		
		GuiUtil = GuiService.GuiUtil

		self:Create()
		
		return self
	end,
})