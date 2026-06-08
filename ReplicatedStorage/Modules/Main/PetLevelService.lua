local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local PetModule = Services.get("PetModule")
local Tiers = Services.get("TiersModule")
local RarityModule = Services.get("RarityModule")

local PetLevelService = {}

PetLevelService.Exp_Per_Tick = {
	Spawn = 25,
	Desert = 50,
	Snow = 100,
	Jungle = 150,
	Ocean = 200,
	Space = 250
}

PetLevelService.MaxLevel = 25

function PetLevelService:GetEquippedPets(Pets)

	local EquippedPets = { }

	for _, Pet in Pets do
		if not Pet.Equipped then
			continue
		end

		table.insert(EquippedPets, Pet)
	end

	return EquippedPets
end

function PetLevelService:GetMaxExp(Pet)
	
	local PetID = Pet.ID
	local PetName = Pet.Name
	local PetTier = Pet.Tier
	local PetExp = Pet.Exp
	local PetLevel = Pet.Level
	local PetEquipped = Pet.Equipped

	local PetData = PetModule[PetName]
	local PetRarity = PetData.Rarity
	
	local TierData = Tiers[PetTier]
	local TierBuff = TierData.Buff
	
	local ExpTierBuff = math.clamp(
		TierBuff / 1.5,
		1,
		TierBuff
	)
	
	local RarityData = RarityModule[PetRarity] or RarityModule.Secret
	
	local ExpRequirement = RarityData.Exp
	local NextExpRequirement = ExpRequirement * PetLevel
	local TierExpRequirement = NextExpRequirement * ExpTierBuff
	
	return math.floor(TierExpRequirement)
end

function PetLevelService:GiveExp(Player, PetID, Amount)
	
	local PlayerData = DataService:GetPlayerData(Player)
	local Pets = PlayerData.Pets
	
	if not PetID then
		
		local Equipped = self:GetEquippedPets(Pets)

		for i, v in Equipped do
			self:GiveExp(
				Player,
				v.ID,
				Amount / #Equipped
			)
		end

		return
	end

	local Pet
	
	for i, p in Pets do
		if p.ID ~= PetID then
			continue
		end
		
		Pet = p
		
		break
	end
	
	if not Pet then
		return
	end

	Pet.Exp += Amount
	
	local Level_Ups = 0
	
	repeat
		local MaxExp = self:GetMaxExp(Pet)
		
		if MaxExp > Pet.Exp then
			break
		end
		
		if Pet.Level >= self.MaxLevel then
			break
		end
		
		Level_Ups += 1
		
		Pet.Level += 1
		Pet.Exp -= MaxExp
		
		Network:Post(
			Player,
			"DisplayNewItem",
			{
				Type = "Message",
				Message = ("%s has reached level %s!"):format(Pet.Name, Pet.Level)
			}
		)
		
	until MaxExp > Pet.Exp
	
	if Pet.Equipped then
		Network:PostAll(
			"SpawnPet",
			Player,
			Pet
		)
		
		if Level_Ups > 0 then
			Network:PostAll(
				"PlayLevelUpEffect",
				Player,
				PetID
			)
		end
	end
	
	DataService:SendUpdateSignal(
		Player,
		"Pets"
	)
end

return PetLevelService