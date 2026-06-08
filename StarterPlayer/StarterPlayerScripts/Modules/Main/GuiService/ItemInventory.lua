local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Roblox = Services.get("Roblox")
local AnimationService = Services.get("AnimationService")
local HoverManager = Services.get("HoverManager")

local Player = Players.LocalPlayer

local GuiService
local Interface
local Frames
local InventoryFrame
local Content
local Tabs
local ItemTab
local Grid
local GuiUtil

local HoverRender

local ItemInventory = {}

function ItemInventory:GetItems()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Items = PlayerData.Items or {}

	return Items
end

function ItemInventory:Load(List)
	if not InventoryFrame.Visible or not ItemTab.Visible then
		return
	end

	for ItemName, ItemAmount in List do
		local Template = GuiUtil:CreateItem(ItemName, ItemAmount, Grid)
		Template.LayoutOrder = ItemAmount

		AnimationService:CreateButton(Template, function()
			-- Item clicked
		end)
	end
end

function ItemInventory:DisconnectHover()
	if not HoverRender then
		return
	end

	HoverRender:Destroy()
	HoverRender = nil
end

function ItemInventory:LoadHover()
	HoverRender = HoverManager:Bind(
		InventoryFrame,
		Grid,
		{
			HelpLabel = "Used for Crafting",
			isItem = true
		}
	)
end

function ItemInventory:LoadHoverInfo()
	if HoverRender then
		HoverRender:LoadHoverInfo()
	end
end

function ItemInventory:Update()
	local Items = self:GetItems()
	self:LoadHoverInfo()
	self:Load(Items)
end

function ItemInventory:Clear()
	Roblox:ClearChildrenOfClass(Grid, "ImageButton")
end

function ItemInventory:Create()
	ItemTab:GetPropertyChangedSignal("Visible"):Connect(function()
		self:DisconnectHover()

		if not ItemTab.Visible then
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

return setmetatable(ItemInventory, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		InventoryFrame = Frames.InventoryFrame
		Content = InventoryFrame.Content

		Tabs = Content.Tabs
		ItemTab = Tabs.Items
		Grid = ItemTab.Grid

		GuiUtil = GuiService.GuiUtil

		self:Create()

		return self
	end,
})