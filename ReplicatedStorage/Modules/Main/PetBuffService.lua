local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local PetModule = Services.get("PetModule")
local Tiers = Services.get("TiersModule")
local PetLevelService = Services.get("PetLevelService")

local MaxLevel = PetLevelService.MaxLevel

local PetBuffService = { }

function PetBuffService:GetEquippedPets(Pets)

	local EquippedPets = { }

	for _, Pet in Pets do
		if not Pet.Equipped then
			continue
		end

		table.insert(EquippedPets, Pet)
	end

	return EquippedPets
end

function PetBuffService:GetMaxEquip(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	if not PlayerData then
		return
	end
	
	return 3 -- math.huge
end

function PetBuffService:GetMaxStorage(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")

	if not PlayerData then
		return
	end
	
	return 100
end

function PetBuffService:GetLocalBuff(Pet)
	local PetID = Pet.ID
	local PetName = Pet.Name
	local PetTier = Pet.Tier
	local PetLevel = Pet.Level
	
	PetTier = PetTier or "Normal"
	PetLevel = PetLevel or 1
	
	local TierData = Tiers[PetTier] or Tiers.Normal

	PetLevel = PetLevel == 1 and 0 or PetLevel
	
	local PetData = PetModule[PetName] or PetModule.Doggy
	local PetBuff = PetData.Buffs
	
	local CurrentBuff = {}
	
	for Currency, Multi in PetBuff do
		local LevelIncrease = 1 + (PetLevel / MaxLevel)
		local NewMulti = Multi * LevelIncrease
		
		if Currency ~= "Speed" then
			NewMulti *= TierData.Buff
		end
		
		CurrentBuff[Currency] = NewMulti
	end
	
	return CurrentBuff
end

function PetBuffService:GetBuff(Pets)
	local Buffs = {}
	
	for _, Pet in Pets do
		local PetBuff = self:GetLocalBuff(Pet)
		
		for Currency, Multi in PetBuff do
			local CurrentBuff = Buffs[Currency] or 0

			Buffs[Currency] = CurrentBuff + Multi
		end
	end
	
	return Buffs
end

function PetBuffService:GetBuffs(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	local Pets = PlayerData.Pets
	
	local EquippedPets = self:GetEquippedPets(Pets)
	
	return self:GetBuff(EquippedPets)
end

return PetBuffService