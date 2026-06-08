local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local DataService = Services.get("DataService")
local Network = Services.get("Network")
local PetModule = Services.get("PetModule")
local PetBuffService = Services.get("PetBuffService")
local PetLevelService = Services.get("PetLevelService")
local WorldService = Services.get("WorldService")
local TaskService = Services.get("TaskService")
local RecipeModule = Services.get("RecipeModule")
local EggModule = Services.get("EggModule")
local SortMethods = Services.get("SortMethods")
local QuestService = Services.get("QuestService")
local ServerBossQueue = Services.get("ServerBossQueue")

local PetUtil = {}

PetUtil.Clear = require(script.Clear)

function PetUtil.GetPets(Player)
	local PlayerData = DataService:GetPlayerData(Player)
	
	return PlayerData.Pets
end

function PetUtil.GetPet(Player, Id)
	for i, Pet in PetUtil.GetPets(Player) do
		if Pet.ID == Id then
			return Pet, i
		end
	end
end

function PetUtil.GetEquipped(Player)
	local _Pets = {}
	
	for i, Pet in PetUtil.GetPets(Player) do
		if not Pet.Equipped then
			continue
		end
		
		table.insert(
			_Pets,
			Pet
		)
	end
	
	return _Pets
end

function PetUtil.SetEquip(Player, PetID, State)
	if typeof(PetID) ~= "string" then
		return
	end

	if typeof(State) ~= "boolean" then
		return
	end

	local Pet = PetUtil.GetPet(Player, PetID)
	
	if State then
		local Equipped = PetUtil.GetEquipped(Player)
		local MaxEquip = PetBuffService:GetMaxEquip(Player)
		
		if #Equipped >= MaxEquip then
			return
		end
	end

	if Pet.Equipped == State then
		return
	end
	
	Pet.Equipped = State
	
	local Event = State and "SpawnPet" or "DespawnPet"
	
	Network:PostAll(
		Event,
		Player,
		Pet
	)
	
	DataService:SendUpdateSignal(
		Player,
		"Pets"
	)
end

function PetUtil.UnequipAll(Player)
	for i, Pet in PetUtil.GetPets(Player) do
		if Pet.Equipped then
			PetUtil.SetEquip(Player, Pet.ID, false)
		end
	end
end

function PetUtil.DeletePets(Player, GUIDs)
	if typeof(GUIDs) ~= "table" then
		return
	end
	
	local Pets = PetUtil.GetPets(Player)
	local Deleted = false
	
	for i = #Pets, 1, -1 do
		local Pet = Pets[i]
		
		if not Pet then continue end
		if not table.find(GUIDs, Pet.ID) then continue end
		
		if Pet.Locked then continue end
		
		if Pet.Equipped then
			Network:PostAll(
				"DespawnPet",
				Player,
				Pet
			)
		end
		
		table.remove(Pets, i)
		
		Deleted = true
	end
	
	if Deleted then
		DataService:SendUpdateSignal(Player, "Pets")
	end
end

function PetUtil.LockPets(Player, GUIDs)
	if typeof(GUIDs) ~= "table" then
		return
	end

	local Pets = PetUtil.GetPets(Player)
	
	for _, GUID in GUIDs do
		for _, Pet in Pets do
			if Pet.ID ~= GUID then
				continue
			end
			
			Pet.Locked = not Pet.Locked
		end
	end
	
	DataService:SendUpdateSignal(
		Player,
		"Pets"
	)
end

function PetUtil.EquipBest(Player, Sort)
	if typeof(Sort) ~= "string" then
		return
	end
	
	local Pets = table.clone(PetUtil.GetPets(Player))
	
	table.sort(Pets, function(a, b)
		local aName = a.Name
		local bName = b.Name

		local aBuff = PetBuffService:GetLocalBuff(a)
		local bBuff = PetBuffService:GetLocalBuff(b)

		local Stat1 = aBuff[Sort] or 0
		local Stat2 = bBuff[Sort] or 0

		if Stat1 ~= Stat2 then
			return Stat1 > Stat2
		end

		return aName:len() > bName:len()
	end)
	
	PetUtil.UnequipAll(Player)
	
	for i, v in Pets do
		PetUtil.SetEquip(Player, v.ID, true)
	end
	
	table.clear(Pets)
end

function PetUtil.LoadPet(Player, Pet)
	Network:PostAll(
		"SpawnPet",
		Player,
		Pet
	)

	local uPetData = PetUtil.server_attacks[Player] or {}
	local TargetData = uPetData[Pet.ID]

	if not TargetData then
		return
	end

	Network:PostAll(
		"SetTarget",
		Player,
		Pet.ID,
		TargetData.model
	)
end

function PetUtil.LoadPets(Player)
	for i, Pet in PetUtil.GetEquipped(Player) do
		PetUtil.LoadPet(Player, Pet)
	end
	
	for i, plr in Players:GetPlayers() do
		if plr == Player then
			continue
		end
		
		for i, Pet in PetUtil.GetEquipped(plr) do
			PetUtil.LoadPet(plr, Pet)
		end
	end
end

function PetUtil.AutoDelete(Player, PetName)
	if typeof(PetName) ~= "string" then
		return
	end

	if not Assets.Pets:FindFirstChild(PetName) then
		return
	end
	
	local PlayerData = DataService:GetPlayerData(Player)
	local AD_Data = PlayerData.AutoDelete
	
	local idx = table.find(AD_Data, PetName)
	
	if idx then
		table.remove(AD_Data, idx)
	else
		table.insert(AD_Data, PetName)
	end
	
	DataService:SendUpdateSignal(Player, "AutoDelete")
end

function PetUtil.CraftShiny(Player, Pet)
	if typeof(Pet) ~= "table" then
		return warn("Invalid Pet")
	end
	
	local PetID = Pet.ID
	
	if typeof(PetID) ~= "string" then
		return warn("Invalid PetID")
	end

	local BasePet, _ = PetUtil.GetPet(Player, PetID)
	
	if not BasePet or BasePet.Tier ~= "Normal" then
		return warn("Target is Invalid")
	end

	local AllPets = PetUtil.GetPets(Player)
	local Matching = {}

	for i, Pet in AllPets do
		if Pet.Name == BasePet.Name and Pet.Tier == "Normal" and not Pet.Locked then
			table.insert(Matching, Pet)
		end
	end

	if #Matching < 10 then
		return warn("Not enough to Craft")
	end

	for i = 1, 10 do
		local Pet = Matching[i]
		local _, i = PetUtil.GetPet(Player, Pet.ID)
		
		if i then
			if Pet.Equipped then
				PetUtil.SetEquip(Player, Pet.ID, false)
			end
			
			table.remove(AllPets, i)
		end
	end

	DataService:GivePet(Player, {
		Name = BasePet.Name,
		Tier = "Shiny",
		Egg = BasePet.Egg
	})
	
	table.clear(Matching)
	
	return true
end

function PetUtil.Craft(Player, Item)
	local ItemData
	local TabName

	for Category, Recipes in RecipeModule do
		for ProductName, Recipe in Recipes do
			if ProductName == Item then
				ItemData = Recipe
				TabName = Category
				break
			end
		end
	end

	if not ItemData or not TabName then
		return
	end

	local PlayerData = DataService:GetPlayerData(Player)

	local Pets = PlayerData.Pets or {}
	local Items = PlayerData.Items or {}
	local Abilities = PlayerData.Abilities or {}

	local Missing = {}
	local PetRemovals = {}

	for _, Ingredient in ItemData do
		local Type = Ingredient.Type
		local Name = Ingredient.Name
		local Amount = Ingredient.Amount or 1

		if Type == "Pet" then
			local Found = {}

			for _, Pet in Pets do
				if Pet.Name == Name and Pet.Tier == "Normal" and not Pet.Locked then
					table.insert(Found, Pet)
					
					if #Found >= Amount then
						break
					end
				end
			end

			if #Found < Amount then
				return
			end

			for _, Pet in Found do
				table.insert(PetRemovals, Pet)
			end
		end

		if Type == "Item" then
			if (Items[Name] or 0) < Amount then
				return
			end
		end

		if Type == "Ability" then
			local Count = 0

			for _, Ability in Abilities do
				if Ability == Name then
					Count += 1
				end
			end

			if Count < Amount then
				return
			end
		end
	end

	for _, Pet in PetRemovals do
		for i = #Pets, 1, -1 do
			if Pets[i].ID == Pet.ID then
				if Pet.Equipped then
					PetUtil.SetEquip(Player, Pet.ID, false)
				end
				
				table.remove(Pets, i)
				
				break
			end
		end
	end

	for _, Ingredient in ItemData do
		if Ingredient.Type == "Item" then
			Items[Ingredient.Name] -= Ingredient.Amount
		end
	end

	for _, Ingredient in ItemData do
		if Ingredient.Type == "Ability" then
			local RemoveCount = Ingredient.Amount

			for i = #Abilities, 1, -1 do
				if Abilities[i] == Ingredient.Name then
					table.remove(Abilities, i)
					RemoveCount -= 1

					if RemoveCount <= 0 then
						break
					end
				end
			end
		end
	end

	if TabName == "Pets" then
		DataService:GivePet(Player, {
			Name = Item,
			Tier = "Normal",
			Egg = "Common"
		})
	end

	if TabName == "Items" then
		DataService:GiveItem(Player, Item, 1)
	end

	if TabName == "Abilities" then
		if not table.find(PlayerData.AbilitiesOwned, Item) then
			table.insert(PlayerData.AbilitiesOwned, Item)
			DataService:SendUpdateSignal(Player, "AbilitiesOwned")
		end
	end

	DataService:SendUpdateSignal(Player, "Pets")
	DataService:SendUpdateSignal(Player, "Items")
	DataService:SendUpdateSignal(Player, "Abilities")
end

function PetUtil.ClaimIndexReward(Player: Player, Area: number, Tier: string)
	if not Player or not Area or not Tier then
		return
	end
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	local Index = PlayerData.Index or {}
	local IndexClaimed = PlayerData.IndexClaimed or {}
	local Pets = PlayerData.Pets or {}

	local World = WorldService.Worlds[1] -- TODO: Support multiple worlds
	local AreaData = World.Areas[Area]
	
	if not AreaData then
		return
	end

	local TotalPets = 0
	local DiscoveredPets = 0
	local RewardPet = nil

	for EggName, EggData in EggModule do
		if typeof(EggData) ~= "table" or typeof(EggData.Pets) ~= "table" then
			continue
		end

		if EggData.Order ~= Area then
			continue
		end

		for _, PetInfo in EggData.Pets do
			local PetName, _ = unpack(PetInfo)
			local PetData = PetModule[PetName]

			if PetData.Rarity == "Secret" then
				continue
			end

			TotalPets += 1
			
			local FullName = Tier == "Normal" and PetName or (Tier .. PetName)

			if table.find(Index, FullName) then
				DiscoveredPets += 1
			end
		end

		if not RewardPet and EggData.IndexReward then
			RewardPet = EggData.IndexReward
		end
	end

	if not RewardPet or DiscoveredPets < TotalPets then
		return
	end

	local FullRewardName = Tier == "Normal" and RewardPet or (Tier .. RewardPet)

	if table.find(IndexClaimed, FullRewardName) then
		return "You've already claimed this reward!"
	end

	DataService:GivePet(Player, {
		Name = RewardPet,
		Tier = Tier,
		Egg = "Common"
	})

	table.insert(IndexClaimed, FullRewardName)
	
	DataService:SendUpdateSignal(Player, "IndexClaimed")
	
	Network:Post(Player,
		"DisplayNewItem", {
		Type = "Message",
		Message = ("You've successfully claimed '%s'!"):format(RewardPet),
		TextColor = "Legendary"
	})

	return true
end

Network:Bind("LoadPets", PetUtil.LoadPets)
Network:Bind("SetEquip", PetUtil.SetEquip)
Network:Bind("UnequipAll", PetUtil.UnequipAll)
Network:Bind("DeletePets", PetUtil.DeletePets)
Network:Bind("EquipBest", PetUtil.EquipBest)
Network:Bind("LockPets", PetUtil.LockPets)
Network:Bind("AutoDelete", PetUtil.AutoDelete)
Network:Bind("CraftShiny", PetUtil.CraftShiny)
Network:Bind("Craft", PetUtil.Craft)
Network:Bind("ClaimIndexReward", PetUtil.ClaimIndexReward)

-- Pet Attacking System

PetUtil.server_attacks = {}

Network:Bind("SetPetTarget", function(Player, PetId, Target)
	
	local PlayerData = DataService:GetPlayerData(Player)
	local Areas = PlayerData.Areas
	
	local Region = Target and Target:GetAttribute("Region")

	if Region and not table.find(Areas, Region) then
		return
	end
	
	local PetData = PetUtil.GetPet(Player, PetId)
	
	if not PetData then
		return
	end
	
	if not PetData.Equipped then
		return
	end
	
	if not PetUtil.server_attacks[Player] then
		PetUtil.server_attacks[Player] = {}
	end
	
	local server_attack = PetUtil.server_attacks[Player][PetId] or {}
	local last_attack = server_attack.last_attack or tick()
	
	if not Target then
		PetUtil.server_attacks[Player][PetId] = nil
		
		Network:PostAll(
			"SetTarget",
			Player,
			PetId,
			nil
		)
		
		return
	end
	
	PetUtil.server_attacks[Player][PetId] = {
		last_attack = last_attack,
		model = Target
	}
	
	Network:PostAll(
		"SetTarget",
		Player,
		PetId,
		Target
	)
end)

Network:Bind("AttackTarget", function(Player, PetId)
	local PlayerData = DataService:GetPlayerData(Player)
	local PetData = PetUtil.GetPet(Player, PetId)

	if not PetData then
		return
	end
	
	if not PetData.Equipped then
		return
	end
	
	local player_attacks = PetUtil.server_attacks[Player]
	local server_attack = player_attacks and player_attacks[PetId]
	
	if not server_attack then
		return
	end
	
	local last_attack = server_attack.last_attack or tick()

	if tick() - last_attack < 1.4 then
		return
	end
	
	local Buffs = PetBuffService:GetLocalBuff(PetData)

	-- Target may have been destroyed; abort cleanly.
	if not server_attack.model or not server_attack.model.Parent then
		PetUtil.server_attacks[Player][PetId] = nil
		return
	end

	if server_attack.model.Parent:IsDescendantOf(workspace.Bosses.Models) then
		if PetData.Enchant ~= "Warrior" and PetData.Enchant ~= "Raider" then return end

		local Level = PlayerData.Level
		local Damage = (Buffs.Speed / 7) * Level

		ServerBossQueue:DealDamage(Player, server_attack.model.Parent:GetAttribute("Area"), Damage)
		
		Network:PostAll(
			"PlayAttack", 
			Player,
			PetId
		)
		
		Network:PostAll(
			"DamagePopup",
			Damage,
			server_attack.model.PrimaryPart
		)

		Network:Post(
			Player,
			"PlayEffectCreateDisplay", 
			Damage
		)

		return
	end

	-- Validate the target still exists before reading attributes (it may have been destroyed mid-attack)
	if not server_attack.model or not server_attack.model.Parent or not server_attack.model.PrimaryPart then
		PetUtil.server_attacks[Player][PetId] = nil
		return
	end

	local Region = server_attack.model:GetAttribute("Region")
	local PickupCurrency = server_attack.model:GetAttribute("Currency") or "Coins"
	local Amount = server_attack.model:GetAttribute("Amount") or 0
	
	local Character = Player.Character
	local Pivot = Character and Character:GetPivot() or CFrame.new()
	
	local p0 = Pivot.Position
	local p1 = server_attack.model:GetPivot().Position
	
	local should_display = (p0 - p1).Magnitude <= 100
	
	local Health = server_attack.model:GetAttribute("Health")
	local MaxHealth = server_attack.model:GetAttribute("MaxHealth")
	
	Amount = MaxHealth / 1.5
	
	local WorldData = WorldService:GetUserWorld(Player)
	local AreaCurrency = WorldData.Currency or "Coins"

	local _dmg = Buffs[AreaCurrency] or 1

	local Damage = math.clamp(
		_dmg,
		0,
		Health
	)

	if Health == 0 then
		return
	end
	
	local Scale = Damage / 100

	DataService:GiveCurrency(
		Player,
		AreaCurrency,
		Amount * Scale,
		should_display
	)
	
	PetLevelService:GiveExp(
		Player,
		PetId,
		PetLevelService.Exp_Per_Tick[Region] or 100
	)
	
	Network:Post(
		Player,
		"ShootCurrency", 
		1, 
		Player, 
		"Coins", 
		server_attack.model.PrimaryPart.Position
	)
	
	Network:PostAll(
		"PlayAttack", 
		Player,
		PetId
	)
	
	Network:PostAll(
		"DamagePopup",
		Damage,
		server_attack.model.PrimaryPart
	)
	
	Network:Post(
		Player,
		"PlayEffectCreateDisplay", 
		Damage
	)
	
	if server_attack.model:GetAttribute("Health") - Damage <= 0 then
		TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
		QuestService:UpdateType(Player, "Pickups", 1)
	end
	
	server_attack.model:SetAttribute(
		"Health",
		server_attack.model:GetAttribute("Health") - Damage
	)

	server_attack.last_attack = tick()
end)

Players.PlayerRemoving:Connect(function(Player)
	PetUtil.server_attacks[Player] = nil
end)

return PetUtil