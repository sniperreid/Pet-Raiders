local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PetModule = Services.get("PetModule")
local TiersModule = Services.get("TiersModule")
local Debouncer = Services.get("Debouncer")
local RNGService = Services.get("RNGService")
local ChallengeService = Services.get("ChallengeService")
local PetEnchantService = Services.get("PetEnchantService")

if RunService:IsServer() then
	for _, Egg in workspace.Eggs:GetChildren() do
		local Model = Egg:FindFirstChildOfClass("Model")
		local Origin = Model and Model:GetPivot() or CFrame.new()
		
		local NewModel = Assets.Eggs:FindFirstChild(Egg.Name)
		
		if not NewModel then
			continue
		end
		
		NewModel = NewModel:Clone()
		NewModel.Parent = Egg
		NewModel.Name = "Model"
		NewModel:PivotTo(Origin)
		NewModel:ScaleTo(1.5)
		
		if not Model then
			continue
		end
		
		Model:Destroy()
	end
end

local EggRNG = RNGService.new("Eggs")
local EggModule = {
	RNG = EggRNG
}

for _, Egg in script:GetChildren() do
	local Name, Data = Egg.Name, require(Egg)
	
	EggModule[Name] = Data
	EggRNG:AttachItem(Name, Data.Pets)
end

local RNG = Random.new()

local ShallowCopy = function(tab)
	local newTab = {}

	for i = 1, #tab do
		newTab[i] = {
			unpack(tab[i])
		}
	end

	return newTab
end

local Ignore = {
	"Epic", 
	"Legendary",
	"Secret"
}

function EggModule:GetTierIncrease(Player)
	local BaseTier = 100
	local Tier = 100

	return Tier
end

function EggModule:GetEggSpeed(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	local BaseSpeed = 1
	local MaxSpeed = 5

	local Speed = BaseSpeed
	
	if PlayerData.Boosts["Speedy"] then
		Speed += .35
	end

	return math.clamp(Speed, BaseSpeed, MaxSpeed)
end

function EggModule:RetrievePlayerEggData(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	local Luck = 1
	
	if PlayerData.Boosts["Lucky"] then
		Luck += .5
	end
	
	if PlayerData.Boosts["Ultra Lucky"] then
		Luck += 1.5
	end
	
	if PlayerData.Boosts["Developer Lucky"] then
		Luck += 10
	end
	
	Luck += PetEnchantService:GetMultiplier(Player, "Luck")

	return math.floor(Luck * 100) / 100
end

function EggRNG:GetLuckCalculator(...)
	return EggModule:RetrievePlayerEggData(...)
end

function EggRNG:NewRarityCalculator(Player, EggName, dontUpdate)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	local Rarities = self.Items[EggName] or {}
	local EggData = EggModule[EggName] or {}
	
	if dontUpdate then
		return Rarities
	end
	
	if EggData.Exclusive then
		return Rarities
	end

	if not PlayerData then
		return Rarities
	end
	
	if EggData.ProductID then
		return Rarities
	end
	
	local Increase = self:GetLuckCalculator(Player, PlayerData)

	local Remove = 0
	local Amount = 0
	local New = ShallowCopy(Rarities)

	local HighestChance = math.huge

	for i, Item in New do
		local Name = Item[1]

		local Rarity = PetModule[Name] and PetModule[Name].Rarity

		if Rarity ~= "Legendary" then
			continue
		end

		if Increase < (100 / Item[2]) then
			continue
		end

		HighestChance = Item[2] < HighestChance and Item[2] or HighestChance
	end

	for i, Item in New do
		local Name = Item[1]
		local IsIgnoringRarity = table.find(Ignore, PetModule[Name].Rarity)

		if Item[2] >= HighestChance and Increase >= 100 / HighestChance and i ~= #New then
			Item[2] = 0

			continue
		end

		if not IsIgnoringRarity then
			Amount += 1

			continue
		end

		Remove += (Item[2] * (Increase - 1))
		Item[2] *= Increase
	end

	for i, Item in New do
		local Name = Item[1]

		local IsIgnoringRarity = table.find(Ignore, PetModule[New[i][1]].Rarity)

		if IsIgnoringRarity then
			continue
		end

		New[i][2] -= (Remove / Amount)
	end

	return New
end

function EggModule:GetPetTier(...)
	local TierChance = self:GetTierIncrease(...)
	local Tiers = {}

	for Tier, TierData in TiersModule do
		Tiers[TierData.Index] = Tier
	end

	for _, Tier in Tiers do
		if RNG:NextInteger(1, math.ceil(TierChance)) == 1 then
			continue
		end

		Tiers[#Tiers] = Tier
	end

	return Tiers[#Tiers]
end

function EggModule:GetPetChance(Pet, EggName)
	local EggData = (typeof(EggName) == "string" and self[EggName] or EggName) or {}

	for _, Data in EggData.Pets or EggData do
		if Data[1] ~= Pet then
			continue
		end

		return Data[2]
	end

	return 100
end

function EggModule:CanPurchaseEgg(Player, EggName, Amount)
	if Player and typeof(Player) ~= "Instance" then
		return "Invalid Player"
	end

	if typeof(EggName) ~= "string" then
		return "Invalid EggName"
	end

	if typeof(Amount) ~= "number" then
		return "Invalid Amount"
	end
	
	if (Amount <= 0) then
		return "Amount not Available"
	end

	if (Amount > 6) then
		return "Amount not Available"
	end

	local PlayerData = RunService:IsServer() and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	local EggData = self[EggName]
	
	if EggData.Exclusive then
		return
	end

	if not EggData then
		return "No EggData"
	end

	local Currency, CostOfEgg = unpack(EggData.Cost)

	CostOfEgg *= Amount

	return PlayerData[Currency] >= CostOfEgg
end

function EggModule:CalculateHatchTime(Speed)
	return (1 / Speed) + (2.5 / Speed) + (0.75 / Speed) + (0.25 / Speed) + (0.1 / Speed) + (0.1 / Speed) + (0.05 / Speed) + (0.05 / Speed) + (0.05 / Speed) + ((0.75 + (1 * 0.03) + (0.25 * 5)) / Speed)
end

local EggDebounces = {}

function EggModule:SimulateOpenEgg(Player, EggName, Amount)
	local Secrets = 0
	local Pets = {}
	
	for i = 1, Amount do
		local Pet = EggRNG:GetRandomItem(Player, EggName)
		local PetTier = self:GetPetTier(Player)

		local PetData = PetModule[Pet]

		if PetData.Rarity == "Secret" then
			Secrets += 1
		end

		local _Pet, NewPet = DataService:GivePet(Player, {
			Name = Pet,
			Tier = PetTier,
			Hatched = true,
			Chance = self:GetPetChance(Pet, EggName),
			Egg = EggName
		})
		
		if NewPet then
			ChallengeService:onPetHatched(Player, _Pet)
		end

		table.insert(
			Pets,
			{
				Name = Pet,
				Tier = PetTier,
				Chance = self:GetPetChance(Pet, EggName),
				NewPet = NewPet
			}
		)
	end
	
	if Secrets > 0 then
		
		local Queue = {}
		
		for i, v in Pets do
			local PetData = PetModule[v.Name]

			if PetData.Rarity ~= "Secret" then
				table.insert(Queue, v)
			end
		end
		
		for a, b in Queue do
			table.remove(
				Pets,
				table.find(Pets, b)
			)
		end
	end
	
	return Pets, Secrets
end

function EggModule:SimulateEggHatch(Player, EggName, Amount, ManualEggHatch, from_egg)
	local EggData = EggModule[EggName]

	if not EggData then
		return
	end
	
	if EggDebounces[Player.UserId] then
		return
	end
	
	EggDebounces[Player.UserId] = true
	
	local Currency, Cost = unpack(EggData.Cost)
	
	DataService:GiveCurrency(
		Player,
		Currency,
		-(Cost * Amount)
	)
	
	DataService:GiveCurrency(
		Player,
		"Eggs Hatched",
		Amount
	)
	
	local Pets, Secret = EggModule:SimulateOpenEgg(Player, EggName, Amount)
	local Speed = 1.5

	Speed = (Secret > 0) and 1.1 or Speed

	local HatchTime = EggModule:CalculateHatchTime(Speed)

	task.delay(HatchTime - 0.75, function()
		EggDebounces[Player.UserId] = nil
	end)

	local HatchInfo = {
		Speed = Speed,
		Egg = EggName,
		Pets = Pets,
		Secret = Secret,
		ManualEggHatch = ManualEggHatch,
		from_egg = from_egg
	}

	Network:Post(Player, "HatchEggClient", HatchInfo)
	
	return true
end

if RunService:IsServer() then
	Network:Bind("OpenExclusiveEgg", function(Player, EggName, Amount)
		Amount = math.clamp(Amount, 0, 6)

		local PlayerData = DataService:GetPlayerData(Player)
		local Eggs = PlayerData.Eggs
		
		local CurrentEggAmount = Eggs[EggName] or 0
		
		if CurrentEggAmount < Amount then
			return
		end
		
		if EggDebounces[Player.UserId] then
			return
		end
		
		DataService:AddEgg(Player, EggName, -Amount)
		
		return EggModule:SimulateEggHatch(Player, EggName, Amount, true)
	end)
	
	Network:Bind("PurchaseEgg", function(Player, EggName, Amount)
		local PurchaseStatus = EggModule:CanPurchaseEgg(Player, EggName, Amount)
		
		if PurchaseStatus ~= true then
			return PurchaseStatus
		end

		return EggModule:SimulateEggHatch(Player, EggName, Amount, false, true)
	end)
	
	Players.PlayerRemoving:Connect(function(Player)
		EggDebounces[Player.UserId] = nil
	end)
end

return EggModule