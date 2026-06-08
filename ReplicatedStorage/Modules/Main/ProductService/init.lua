local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local DataService = Services:GetService("DataService")

local Products = require(script.Products)

local DeveloperProducts = Products.Products
local Gamepasses = Products.Gamepasses

local ProductService = {}

-- :GetProductInfo(ProductId) -> ()?;
-- :Purchase(Player, ProductId) -> ();
-- :ProcessReceipt(ReceiptInfo) -> (GiveItem);

function ProductService:GetProductInfo(ProductName)
	local isId = typeof(ProductName) == "number"
	
	for i, Category in Products do
		if isId then
			for a, b in Category do
				if b.ProductId == ProductName then
					return i, b
				end
			end
		end
		
		if Category[ProductName] then
			return i, Category[ProductName]
		end
	end
end

function ProductService:UserOwnsGamepass(Player, ProductName)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or {}
	local PlayerPasses = PlayerData.Passes or {}
	
	return table.find(PlayerPasses, ProductName) and true
end

function ProductService:SyncGamepassInfo(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	local UserId = Player.UserId
	
	for PassName, Data in Gamepasses do
		local ProductId = Data.ProductId
		
		if not MarketplaceService:UserOwnsGamePassAsync(UserId, ProductId) then
			continue
		end
		
		if Data.OnPurchase then
			Data:OnPurchase(Player)
		end
		
		if table.find(PlayerData.Passes, PassName) then
			continue
		end
		
		table.insert(
			PlayerData.Passes,
			PassName
		)
		
		DataService:SendUpdateSignal(Player, "Passes")
	end
end

function ProductService:Purchase(Player, ProductName)
	
	local Category, ProductInfo = self:GetProductInfo(ProductName)
	
	if Category == "Gamepasses" then
		return MarketplaceService:PromptGamePassPurchase(
			Player,
			ProductInfo.ProductId
		)
	end
	
	return MarketplaceService:PromptProductPurchase(
		Player,
		ProductInfo.ProductId
	)
end

function ProductService:ProcessReceipt(ReceiptInfo)
	local PlayerId = ReceiptInfo.PlayerId
	local CurrencySpent = ReceiptInfo.CurrencySpent
	
	local Player = Players:GetPlayerByUserId(PlayerId)
	
	if not Player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	local PlayerData = DataService:GetPlayerData(Player)
	local Category, ProductInfo = self:GetProductInfo(ReceiptInfo.ProductId)

	if not ProductInfo.OnPurchase then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	DataService:GiveCurrency(Player, "RobuxSpent", CurrencySpent)
	
	if not ProductInfo:OnPurchase(Player) then
		DataService:GiveCurrency(Player, "Tokens", CurrencySpent)
		
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ProductService:init()
	for Category, Data in Products do
		for i, v in Data do
			v.Name = i
		end
	end
	
	if not RunService:IsServer() then
		return
	end
	
	MarketplaceService.ProcessReceipt = function(...)
		return ProductService:ProcessReceipt(...)
	end
end

ProductService:init()

return ProductService