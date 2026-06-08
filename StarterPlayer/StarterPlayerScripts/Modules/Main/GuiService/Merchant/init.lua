local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local TextAnimationService = Services.get("TextAnimationService")
local AnimationService = Services.get("AnimationService")
local ImageModule = Services.get("ImageModule")
local Short = Services.get("Short")
local HoverManager = Services.get("HoverManager")

local PetModule = Services.get("PetModule")
local BoostModule = Services.get("BoostModule")
local ItemModule = Services.get("ItemModule")

local GuiService
local Interface
local Frames
local MerchantFrame

local module = {}
module.Type = "Default"

local ItemFrames = {}

local Themes = require(script.Themes)

function module:ApplyTheme(Theme: string)
	local Colors = Themes[Theme]
	
	if not Colors then return end

	local Content = MerchantFrame.Content
	local Grid = Content.Grid
	local Info = Content.Info

	Content.BackgroundColor3 = Colors[1]
	Content.Inner.BackgroundColor3 = Colors[2]

	for _, v in Info:GetChildren() do
		if v:IsA("Frame") then
			v.BackgroundColor3 = Colors[2]
		end
	end

	for _, v in Grid:GetChildren() do
		if v:IsA("Frame") then
			v.BackgroundColor3 = Colors[2]
			local ItemButton = v:FindFirstChildOfClass("ImageButton")
			
			if ItemButton then
				ItemButton.Content.BackgroundColor3 = Colors[2]
				ItemButton.Content.Inner.BackgroundColor3 = Colors[1]
			end
		end
	end
end

function module:UpdateTime()
	if not MerchantFrame.Visible then return end

	local RemainingMerchantTime = Network:Invoke("GetRemainingMerchantTime", self.Type)
	
	if typeof(RemainingMerchantTime) ~= "number" then return end

	local TimeRemainingLabel = MerchantFrame.Content.Info.TimeRemaining.Time
	
	TimeRemainingLabel.Text = Short:FormatBoost(RemainingMerchantTime)
end

function module:OnPurchase(ItemId: string)
	if not ItemId then return end

	local Result = Network:Invoke("PurchaseItem", ItemId, self.Type)

	if not Result then
		return
	end

	if Result.Success then
		Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = Result.Message,
			TextColor = Color3.fromRGB(123, 253, 87)
		})

		local Frame = ItemFrames[ItemId]
		
		if Frame and Frame.Parent then
			Frame.ItemStock.Text = `{Result.NewStock}/{Frame.MaxStock.Value} in stock`

			if Result.NewStock <= 0 then
				Frame.Buy.Interactable = false
				Frame.Buy.Content.Amount.Text = "Sold"
				Frame.Buy.Content.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			end
		end
	else
		Network:Fetch("DisplayNewItem", {
			Type = "Message",
			Message = Result.Message,
			TextColor = Color3.fromRGB(255, 61, 64)
		})
	end
end

function module:Update()
	local MerchantData = Network:Invoke("GetOffers", self.Type)
	
	if not MerchantData then return end

	local Grid = MerchantFrame.Content.Grid

	for _, frame in pairs(ItemFrames) do
		frame:Destroy()
	end
	
	table.clear(ItemFrames)
	
	local PlayerData = Network:Fetch("GetClientData")
	
	if not PlayerData then
		return
	end
	
	MerchantFrame.Content.Info.Reroll.Rerolls.Text = `Rerolls: {PlayerData.Rerolls}`

	for _, ItemData in ipairs(MerchantData) do
		local ItemUI = script.Entry:Clone()

		ItemUI.Name = ItemData.Id
		ItemUI.Parent = Grid

		ItemUI.ItemName.Text = ItemData.Name
		ItemUI.ItemStock.Text = `{ItemData.Stock}/{ItemData.MaxStock} in stock`

		local MaxStockValue = Instance.new("IntValue")
		MaxStockValue.Name = "MaxStock"
		MaxStockValue.Value = ItemData.MaxStock
		MaxStockValue.Parent = ItemUI

		local ItemIcon = ItemUI.Item
		ItemIcon.Name = ItemData.Name
		ItemIcon.Content.PetIcon.Image = ImageModule(ItemData.Name)
		ItemIcon.Content.Amount.Text = ItemData.Type == "Boost" and Short:FormatBoost(ItemData.Amount) or `x{ItemData.Amount}`

		local BuyButton = ItemUI.Buy
		BuyButton.Content.Icon.Image = ImageModule(ItemData.Currency)
		BuyButton.Content.Amount.Text = Short:AddSuffix(ItemData.Price)
		
		local Discount = ItemIcon.Content.Discount
		Discount.Visible = self.Type == "Night Market"
		
		AnimationService:CreateButton(BuyButton, function()
			if ItemData.Stock <= 0 then
				return
			end
			
			self:OnPurchase(ItemData.Id)
		end)

		if ItemData.Stock <= 0 then
			BuyButton.Interactable = false
			BuyButton.Content.Amount.Text = "Sold"
			BuyButton.Content.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end

		local ItemModuleData = ItemData.Type == "Pet" and PetModule[ItemData.Name] or ItemData.Type == "Boost" and BoostModule[ItemData.Name] or ItemData.Type == "Item" and ItemModule[ItemData.Name]

		TextAnimationService:AnimateText(ItemUI.ItemName, ItemModuleData.Rarity)
		TextAnimationService:AnimateImage(ItemIcon.Glow, ItemModuleData.Rarity)

		ItemFrames[ItemData.Id] = ItemUI
	end
	
	self:ApplyTheme(self.Type)
end

function module:init()
	HoverManager:Bind(MerchantFrame.Content, MerchantFrame.Content.Grid, { HelpLabel = "Shop Item" })
	HoverManager:Bind(MerchantFrame.Content, MerchantFrame.Content.Grid, { HelpLabel = "Shop Item", Boost = true, Prize = true })
	HoverManager:Bind(MerchantFrame.Content, MerchantFrame.Content.Grid, { HelpLabel = "Shop Item", isItem = true })
	
	AnimationService:CreateButton(MerchantFrame.Content.Info.Reroll.Reroll, function()
		return Network:Post("Reroll", self.Type)
	end)

	task.spawn(function()
		while true do
			self:UpdateTime()
			
			task.wait(1)
		end
	end)
end

function module:OpenMerchant(Theme: string)
	if not Themes[Theme] then return end

	self.Type = Theme
	GuiService:OpenFrame(MerchantFrame)

	self:Update()
end

Network:Bind("OpenMerchant", function(...)
	return module:OpenMerchant(...)
end)

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = Interface.Frames
		MerchantFrame = Frames.MerchantFrame

		self:init()
		
		return self
	end,
})