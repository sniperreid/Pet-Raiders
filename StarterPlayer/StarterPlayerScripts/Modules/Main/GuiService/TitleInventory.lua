local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Roblox = Services.get("Roblox")
local AnimationService = Services.get("AnimationService")
local TextAnimationService = Services.get("TextAnimationService")
local TitlesService = Services.get("TitlesService")

local GuiService
local Interface
local Frames
local InventoryFrame
local Content

local Tabs
local TitleTab
local List
local Selection

local Types
local Grid

local GuiUtil

local Inventory = {}
local SelectedTitle = "Clicker"
local CurrentTab = "Progress"

function Inventory:GetTitles()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Titles = PlayerData.Titles or {}

	return Titles
end

function Inventory:GetTitle()
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Title = PlayerData.Title or {}

	return Title
end

function Inventory:GetTitleData(Title)
	for i, v in TitlesService.Titles do
		if v.Title == Title then
			return v
		end
	end
	
	return nil
end

function Inventory:UpdateSelection()
	local PlayerTitles = self:GetTitles()
	
	local TitleData = self:GetTitleData(SelectedTitle)
	
	if not TitleData then
		return
	end
	
	local _TitleName = Selection.TitleName
	local _TitleDescription = Selection.TitleDescription
	local _ChatTag = Selection.ChatTag
	
	_TitleName.Text = SelectedTitle
	_TitleDescription.Text = TitleData.Description
	_ChatTag.Text = TitleData.ChatTag and ("✅ Chat Tag") or ("❌ Chat Tag")
	
	if TitleData.Color then
		TextAnimationService:RequestCleanup(_TitleName)
		
		_TitleName.TextColor3 = TitleData.Color
	else
		TextAnimationService:AnimateText(_TitleName, SelectedTitle)
	end
end

function Inventory:Load(List)
	if not InventoryFrame.Visible or not TitleTab.Visible then
		return
	end
	
	local PlayerTitles = self:GetTitles()
	local PlayerTitle = self:GetTitle()
	
	self:Clear()

	for i, TitleData in List do
		if TitleData.Type ~= CurrentTab then
			continue
		end
		
		local TitleName = TitleData.Title
		
		local Template = GuiUtil:CreateTitle(TitleName, TitleData, PlayerTitles, PlayerTitle, Grid)
		
		Template.LayoutOrder = i
		
		AnimationService:CreateButton(Template, function()
			SelectedTitle = TitleName

			self:UpdateSelection()
			
			return Network:Post("EquipTitle", TitleName)
		end)
	end
end

function Inventory:Update()
	for _, v in Roblox:GetChildrenOfClass(Types, "GuiButton") do
		local _Content = v.Content
		
		local SelectedColor = Color3.fromRGB(0, 180, 255)
		local UnselectedColor = Color3.fromRGB(140, 140, 140)

		_Content.BackgroundColor3 = CurrentTab == v.Name and SelectedColor or UnselectedColor
	end
	
	return self:Load(TitlesService.Titles)
end

function Inventory:Clear()
	return Roblox:ClearChildrenOfClass(Grid, "GuiButton")
end

function Inventory:Create()
	TitleTab:GetPropertyChangedSignal("Visible"):Connect(function()
		if not TitleTab.Visible then
			return self:Clear()
		end
		
		self:Update()
	end)
	
	InventoryFrame:GetPropertyChangedSignal("Visible"):Connect(function()	
		if not InventoryFrame.Visible then
			return self:Clear()
		end

		self:Update()
	end)
	
	for _, v in Roblox:GetChildrenOfClass(Types, "GuiButton") do
		AnimationService:CreateButton(v, function()
			if v.Name == CurrentTab then
				return
			end
			
			CurrentTab = v.Name
			
			self:Update()
		end)
	end
end

return setmetatable(Inventory, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		InventoryFrame = Frames.InventoryFrame
		Content = InventoryFrame.Content
		
		Tabs = Content.Tabs
		TitleTab = Tabs.Titles
		List = TitleTab.List
		Selection = TitleTab.Selection
		
		Types = List.Types
		Grid = List.Grid
		
		GuiUtil = GuiService.GuiUtil

		self:Create()
		
		return self
	end,
})