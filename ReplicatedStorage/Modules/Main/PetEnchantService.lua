local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local RNGService = Services.get("RNGService")

local PetEnchantService = {}

PetEnchantService.Headers = {
	Luck = {
		I = { Mul = .2, Chance = 12, Rarity = "Common", Tags = {"🍀 +0.2 Luck 🍀"} },
		II = { Mul = .35, Chance = 6, Rarity = "Unique", Tags = {"🍀 +0.35 Luck 🍀"} },
		III = { Mul = .5, Chance = 3, Rarity = "Rare", Tags = {"🍀 +0.5 Luck 🍀"} },
		IV = { Mul = .75, Chance = 1.5, Rarity = "Epic", Tags = {"🍀 +0.75 Luck 🍀"} },
		V = { Mul = 1, Chance = .65, Rarity = "Legendary", Tags = {"🍀 +1 Luck 🍀"} }
	},
	
	Hatcher = {
		I = { Mul = .1, Chance = 10, Rarity = "Common", Tags = {"🥚 +10% Hatch Speed 🥚"}},
		II = { Mul = .15, Chance = 6, Rarity = "Unique", Tags = {"🥚 +15% Hatch Speed 🥚"}},
		III = { Mul = .2, Chance = 3, Rarity = "Rare", Tags = {"🥚 +20% Hatch Speed 🥚"}},
		IV = { Mul = .25, Chance = 1.5, Rarity = "Epic", Tags = {"🥚 +25% Hatch Speed 🥚"}},
		V = { Mul = .3, Chance = .5, Rarity = "Legendary", Tags = {"🥚 +30% Hatch Speed 🥚"}},
	},
	
	Coins = {
		I = { Mul = .1, Chance = 15, Rarity = "Common", Tags = {"🪙 +10% Coins 🪙"} },
		II = { Mul = .2, Chance = 10, Rarity = "Unique", Tags = {"🪙 +20% Coins 🪙"} },
		III = { Mul = .35, Chance = 6, Rarity = "Rare", Tags = {"🪙 +35% Coins 🪙"} },
		IV = { Mul = .5, Chance = 2, Rarity = "Epic", Tags = {"🪙 +50% Coins 🪙"} },
		V = { Mul = 1, Chance = .75, Rarity = "Legendary", Tags = {"🪙 +100% Coins 🪙"} }
	},
	
	Speed = {
		I = { Mul = .05, Chance = 15, Rarity = "Common", Tags = {"⚡ +5% Pet Speed ⚡"} },
		II = { Mul = .1, Chance = 10, Rarity = "Unique", Tags = {"⚡ +10% Pet Speed ⚡"} },
		III = { Mul = .175, Chance = 6, Rarity = "Rare", Tags = {"⚡ +17.5% Pet Speed ⚡"} },
		IV = { Mul = .25, Chance = 2, Rarity = "Epic", Tags = {"⚡ +25% Pet Speed ⚡"} },
		V = { Mul = .5, Chance = .75, Rarity = "Legendary", Tags = {"⚡ +50% Pet Speed ⚡"} }
	},
	
	Warrior = { Chance = 1.5, Rarity = "Epic", Tags = {"⚔️ Enables the pet to fight bosses. 🐶"} },
	Flash = { Chance = .75, Rarity = "Mythic", Tags = {"⚡ +100% Pet Speed ⚡"} },
	Rich = { Chance = .75, Rarity = "Mythic", Tags = {"🪙 +200% Coins 🪙"}},
	Lottery = { Chance = .5, Rarity = "Mythic", Tags = {"🍀 +2 Luck 🍀"}},
	["Mad Hatcher"] = { Chance = .5, Rarity = "Mythic", Tags = {"🥚 +50% Hatch Speed 🥚"}},
	Raider = { Chance = .025, Rarity = "Secret", Tags = {"⚡ +100% Pet Speed ⚡", "🪙 +200% Coins 🪙", "⚔️ Enables the pet to fight bosses. 🐶", "🍀 +2 Luck 🍀", "🥚 +50% Hatch Speed 🥚"} }
}

PetEnchantService.EnchantsList = {}

for i, v in PetEnchantService.Headers do
	if v.Chance then
		table.insert(PetEnchantService.EnchantsList, {
			name = i,
			chance = v.Chance,
			rarity = v.Rarity
		})
		
		continue
	end
	
	for numeral, d in v do
		table.insert(PetEnchantService.EnchantsList, {
			name = i .. " " .. numeral,
			chance = d.Chance,
			rarity = d.Rarity
		})
	end
end

table.sort(PetEnchantService.EnchantsList, function(a, b)
	return a.chance > b.chance
end)

PetEnchantService.EnchantRNG = RNGService.new("Enchant")
PetEnchantService.EnchantRNG:AttachItem("Main", PetEnchantService.EnchantsList)

local Ignore = {
	"Epic", 
	"Legendary",
	"Secret"
}

function PetEnchantService.EnchantRNG:GetLuckCalculator(Player)
	return 1
end

function PetEnchantService.EnchantRNG:NewRarityCalculator(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	local Rarities = self.Items.Main
	local Increase = self:GetLuckCalculator(Player, PlayerData)

	local Remove = 0
	local Amount = 0
	local New = DataService.Utility.ShallowCopy(Rarities)

	local HighestChance = math.huge

	for i, Item in New do
		local Name = Item.name
		local Rarity = Item.rarity

		if Rarity ~= "Legendary" then
			continue
		end

		if Increase < (100 / Item.chance) then
			continue
		end

		HighestChance = Item.chance < HighestChance and Item.chance or HighestChance
	end

	for i, Item in New do
		local Name = Item.name
		local IsIgnoringRarity = table.find(Ignore, Item.rarity)

		if Item.chance >= HighestChance and Increase >= 100 / HighestChance and i ~= #New then
			Item.chance = 0

			continue
		end

		if not IsIgnoringRarity then
			Amount += 1

			continue
		end

		Remove += (Item.chance * (Increase - 1))
		Item.chance *= Increase
	end

	for i, Item in New do
		local Name = Item.name
		local IsIgnoringRarity = table.find(Ignore, Item.Rarity)

		if IsIgnoringRarity then
			continue
		end

		New[i].chance -= (Remove / Amount)
	end

	return New
end

function PetEnchantService:GetRandomEnchant(Player)
	return self.EnchantRNG:GetRandomItem(Player)
end

function PetEnchantService:RollEnchant(Player, forPet)
	local PlayerData = DataService:GetPlayerData(Player)
	local Pets = PlayerData.Pets
	
	local Pet
	
	for i, v in Pets do
		if v.ID == forPet then
			Pet = v
			
			break
		end
	end
	
	if not Pet then
		return "The pet you are rolling an enchant for no longer exists.", Color3.fromRGB(255, 61, 64)
	end
	
	local EnchantRolls = PlayerData.EnchantRolls or 0
	
	if EnchantRolls <= 0 then
		--return "You don't have any rolls left!", Color3.fromRGB(255, 61, 64)
	end
	
	--DataService:GiveCurrency(Player, "EnchantRolls", -1)
	
	Pet.Enchant = self:GetRandomEnchant(Player)
	
	DataService:SendUpdateSignal(Player, "Pets")
	
	return "You recieved " .. Pet.Enchant, Color3.fromRGB(123, 253, 87)
end

function PetEnchantService:GetMultiplier(Player, expect)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	local Pets = PlayerData.Pets
	
	local Luck = 0
	
	local hd = self.Headers[expect]
	
	if not hd then return Luck end
	
	for i, v in Pets do
		if not v.Equipped then continue end
		
		local Enchant = v.Enchant or ""
		
		if not Enchant:match(expect) then continue end
		
		-- +2 for Space inbetween Luck and Numeral
		local en = Enchant:sub(expect:len() + 2, Enchant:len())
		local pw = (hd[en] or {}).Mul or 0
		
		Luck += pw
	end
	
	return Luck
end

if RunService:IsServer() then
	Network:Bind("RollEnchant", function(...)
		return PetEnchantService:RollEnchant(...)
	end)
end

return PetEnchantService