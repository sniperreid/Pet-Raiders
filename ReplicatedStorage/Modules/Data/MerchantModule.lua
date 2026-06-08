--!strict

local MerchantModule = {}

export type ItemData = {
	Type: string,
	Name: string,
	Price: number,
	Amount: number,
	MaxStock: number,
	Currency: string
}

export type PlayerMerchantData = {
	CurrentItems: {[string]: number},
	PreviousItems: {string},
	LastRefreshTimestamp: number
}

local Items: {[string]: ItemData} = {

	-- Boosts

	["BOOST001"] = { Type = "Boost", Name = "Lucky", Price = 50, Amount = (30 * 60), MaxStock = 15, Currency = "Gems" },
	["BOOST002"] = { Type = "Boost", Name = "Speedy", Price = 50, Amount = (30 * 60), MaxStock = 15, Currency = "Gems" },
	["BOOST003"] = { Type = "Boost", Name = "Ultra Lucky", Price = 450, Amount = (30 * 60), MaxStock = 15, Currency = "Gems" },

	-- Pets

	["PET001"] = { Type = "Pet", Name = "King Doggy", Price = 10_000, Amount = 1, MaxStock = 1, Currency = "Coins" },
	["PET002"] = { Type = "Pet", Name = "Solar Deity", Price = 35_000, Amount = 1, MaxStock = 1, Currency = "Coins" },
	["PET003"] = { Type = "Pet", Name = "Scorched Shock", Price = 50_000, Amount = 1, MaxStock = 1, Currency = "Coins" },
	["PET004"] = { Type = "Pet", Name = "Dogcat", Price = 1_000, Amount = 1, MaxStock = 1, Currency = "Coins" },
	["PET005"] = { Type = "Pet", Name = "Ascended Doggy", Price = 2_500, Amount = 1, MaxStock = 1, Currency = "Coins" },

	-- Items

	["ITEM001"] = { Type = "Item", Name = "Hallowed Shard", Price = 1_000, Amount = 1, MaxStock = 10, Currency = "Coins" }

}

MerchantModule.Items = Items

table.freeze(MerchantModule.Items)
table.freeze(MerchantModule)

return MerchantModule