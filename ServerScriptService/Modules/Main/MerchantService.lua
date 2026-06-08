--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local MerchantModule = Services.get("MerchantModule") :: {Items: {[number]: string}}

type MerchantData = {
	LastRefreshTimestamp: number,
	CurrentItems: {[string]: number},
	PreviousItems: {string},
}

type PlayerData = {
	Merchants: {[string]: MerchantData},
	Rerolls: number?,
	[string]: any
}

local MerchantService = {}

local MasterItemPool = {}

local Debounces = {}

for Id in MerchantModule.Items do
	table.insert(MasterItemPool, Id)
end

local MERCHANT_CONFIG = {
	["Default"] = {
		Cooldown = 43200, -- 12 Hours
		SlotCount = 3,
		Discount = 1.0,
	},
	
	["Night Market"] = {
		Cooldown = 86400, -- 24 Hours
		SlotCount = 5,
		Discount = 0.90, -- 10% Off
	}
}

local RNG = Random.new()

local function Shuffle<T>(tbl: {T}): {T}
	for i = #tbl, 2, -1 do
		local j = RNG:NextInteger(1, i)

		tbl[i], tbl[j] = tbl[j], tbl[i]
	end

	return tbl
end

local function GenerateNewShop(PreviousItems: {string}, SlotCount: number): {[string]: number}
	local PreviousItemsSet = {}

	for _, ID in pairs(PreviousItems) do
		PreviousItemsSet[ID] = true
	end

	local CandidatePool = {}

	for _, ID in pairs(MasterItemPool) do
		if not PreviousItemsSet[ID] then
			table.insert(CandidatePool, ID)
		end
	end

	Shuffle(CandidatePool)

	local NewItemsWithStock = {}

	for i = 1, math.min(SlotCount, #CandidatePool) do
		local ItemId = CandidatePool[i]
		local ItemData = MerchantModule.Items[ItemId]

		if ItemData then
			NewItemsWithStock[ItemId] = ItemData.MaxStock
		end
	end

	return NewItemsWithStock
end

local function RefreshShop(Player: Player, MerchantType: string): PlayerData?
	local Config = MERCHANT_CONFIG[MerchantType]

	if not Config then return nil end

	local PlayerData: PlayerData? = DataService:GetPlayerData(Player)

	if not PlayerData then return nil end

	if not PlayerData.Merchants then
		PlayerData.Merchants = {}
	end

	for Type, _ in pairs(MERCHANT_CONFIG) do
		if not PlayerData.Merchants[Type] then
			PlayerData.Merchants[Type] = {
				LastRefreshTimestamp = 0,
				CurrentItems = {},
				PreviousItems = {}
			}
		end
	end

	local MerchantData = PlayerData.Merchants[MerchantType]
	local Now = os.time()

	if (Now - MerchantData.LastRefreshTimestamp) >= Config.Cooldown then
		local OldIds = {}

		for ID, _ in pairs(MerchantData.CurrentItems) do
			table.insert(OldIds, ID)
		end

		local NewItems = GenerateNewShop(OldIds, Config.SlotCount)

		MerchantData.PreviousItems = OldIds
		MerchantData.CurrentItems = NewItems
		MerchantData.LastRefreshTimestamp = Now

		DataService:SendUpdateSignal(Player, "Merchants")
	end

	return PlayerData
end

local function GetRemainingTime(Player: Player, MerchantType: string): number
	local Config = MERCHANT_CONFIG[MerchantType]

	if not Config then return 0 end

	local PlayerData: PlayerData? = DataService:GetPlayerData(Player)

	if not PlayerData or not PlayerData.Merchants or not PlayerData.Merchants[MerchantType] then return 0 end

	local MerchantData = PlayerData.Merchants[MerchantType]
	local NextRefreshTime = MerchantData.LastRefreshTimestamp + Config.Cooldown
	local RemainingTime = NextRefreshTime - os.time()

	return math.max(0, RemainingTime)
end

local function GetOffers(Player: Player, MerchantType: string)
	local PlayerData: PlayerData? = RefreshShop(Player, MerchantType)

	if not PlayerData then return {} end

	local Config = MERCHANT_CONFIG[MerchantType]

	if not Config then return {} end

	local MerchantData = PlayerData.Merchants[MerchantType]

	if not MerchantData then return {} end

	local FormattedOffers = {}

	for ItemId, CurrentStock in pairs(MerchantData.CurrentItems) do
		local ItemData = MerchantModule.Items[ItemId]

		if ItemData then
			local Price = math.floor(ItemData.Price * Config.Discount)

			local Offer = {
				Id = ItemId,
				Type = ItemData.Type,
				Name = ItemData.Name,
				Amount = ItemData.Amount,
				MaxStock = ItemData.MaxStock,
				Price = Price,
				Currency = ItemData.Currency,
				Stock = CurrentStock
			}

			table.insert(FormattedOffers, Offer)
		end
	end

	return FormattedOffers
end

local function PurchaseItem(Player: Player, ItemId: string, MerchantType: string)
	if typeof(ItemId) ~= "string" or typeof(MerchantType) ~= "string" then
		return { Success = false, Message = "Invalid request format." }
	end

	local Config = MERCHANT_CONFIG[MerchantType]

	if not Config then
		return { Success = false, Message = "Invalid merchant type." }
	end

	local PlayerData: PlayerData? = DataService:GetPlayerData(Player)

	if not PlayerData or not PlayerData.Merchants or not PlayerData.Merchants[MerchantType] then
		return { Success = false, Message = "Could not find your data." }
	end

	local MerchantData = PlayerData.Merchants[MerchantType]

	local RemainingStock = MerchantData.CurrentItems[ItemId]

	if not RemainingStock or RemainingStock <= 0 then
		return { Success = false, Message = "This item is not in your shop or is out of stock." }
	end

	local ItemData = MerchantModule.Items[ItemId]

	if not ItemData then
		return { Success = false, Message = "Item does not exist in the game." }
	end

	local FinalPrice = math.floor(ItemData.Price * Config.Discount)

	local HasEnough = PlayerData[ItemData.Currency] and PlayerData[ItemData.Currency] >= FinalPrice

	if not HasEnough then
		return { Success = false, Message = "You do not have enough " .. ItemData.Currency .. "." }
	end

	PlayerData[ItemData.Currency] -= FinalPrice
	DataService:SendUpdateSignal(Player, ItemData.Currency)

	if ItemData.Type == "Pet" then
		DataService:GivePet(Player, { Name = ItemData.Name }, true)
	elseif ItemData.Type == "Boost" then
		DataService:GiveBoost(Player, ItemData.Name, ItemData.Amount)
	elseif ItemData.Type == "Item" then
		DataService:GiveItem(Player, ItemData.Name, ItemData.Amount)
	end

	MerchantData.CurrentItems[ItemId] -= 1
	DataService:SendUpdateSignal(Player, "Merchants")

	return { Success = true, Message = "Purchase successful!", NewStock = MerchantData.CurrentItems[ItemId] }
end

local function Reroll(Player: Player, MerchantType: string)
	local PlayerData: PlayerData? = DataService:GetPlayerData(Player)

	if not PlayerData then return end

	local Config = MERCHANT_CONFIG[MerchantType]

	if not Config then return end

	if not PlayerData.Rerolls or PlayerData.Rerolls <= 0 then
		return nil, Network:Post(Player, "DisplayNewItem", {
			Type = "Message",
			Message = "You do not have any rerolls!",
			TextColor = Color3.fromRGB(255, 61, 64)
		})
	end

	PlayerData.Rerolls -= 1

	local MerchantData = PlayerData.Merchants[MerchantType]

	local OldIds = {}

	for ID, _ in pairs(MerchantData.CurrentItems) do
		table.insert(OldIds, ID)
	end

	local NewItems = GenerateNewShop(OldIds, Config.SlotCount)

	MerchantData.PreviousItems = OldIds
	MerchantData.CurrentItems = NewItems
	MerchantData.LastRefreshTimestamp = os.time()

	DataService:SendUpdateSignal(Player, "Rerolls")
	DataService:SendUpdateSignal(Player, "Merchants")
end

local function DoSomething(Callback: string, Player: Player, ...): any
	if Debounces[Player] then
		return
	end
	
	Debounces[Player] = true
	
	task.delay(.15, function()
		Debounces[Player] = nil
	end)
	
	if Callback == "PurchaseItem" then
		return PurchaseItem(Player, ...)
	end
	
	if Callback == "Reroll" then
		return Reroll(Player, ...)
	end
	
	return
end

Players.PlayerRemoving:Connect(function(Player: Player)
	Debounces[Player] = nil
end)

Network:Bind("GetRemainingMerchantTime", GetRemainingTime)
Network:Bind("GetOffers", GetOffers)

Network:Bind("PurchaseItem", function(...)
	return DoSomething("PurchaseItem", ...)
end)

Network:Bind("Reroll", function(...)
	return DoSomething("Reroll", ...)
end)

return MerchantService