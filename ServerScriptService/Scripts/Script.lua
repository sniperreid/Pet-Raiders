local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local sv = Instance.new("StringValue")
sv.Name = "StringValue"
sv.Parent = workspace

local Network = Services.get("Network")

local PlayerLoader = Services.get("PlayerLoader")

Services.get("CurrencyModule")
Services.get("DataService")
Services.get("TaskService")
Services.get("AreaService")
Services.get("PetUtil")
Services.get("PickupService")
Services.get("GiftService")
Services.get("EggModule")
Services.get("DoorService")
Services.get("ActivationService")
Services.get("AbilityService")
Services.get("ServerBossQueue")
Services.get("SettingsService")
Services.get("QuestService")
Services.get("BossClass")
Services.get("PrizeService")
Services.get("CodeModule")
Services.get("MerchantService")
Services.get("TradingServer")

Players.PlayerRemoving:Connect(PlayerLoader.Disconnect)

game:BindToClose(function()
	for _, Player in Players:GetPlayers() do
		PlayerLoader.Disconnect(Player)
	end
end)