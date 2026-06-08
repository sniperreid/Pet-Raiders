local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PetUtil = Services.get("PetUtil")
local PetLevelService = Services.get("PetLevelService")
local WorldService = Services.get("WorldService")
local TaskService = Services.get("TaskService")
local QuestService = Services.get("QuestService")
local ServerBossQueue = Services.get("ServerBossQueue")

local function GetPickup(Player: Player)
	local Targets = {}
	local Seen = {}
	local player_attacks = PetUtil.server_attacks[Player]

	if not player_attacks then 
		return Targets 
	end

	for i, v in player_attacks do
		local Model = v.model
		
		if Model and Model:IsDescendantOf(workspace.Pickups) and not Seen[Model] then
			table.insert(Targets, Model)
			
			Seen[Model] = true
		end
	end

	return Targets
end

local function GetBoss(Player: Player)
	local player_attacks = PetUtil.server_attacks[Player]

	if not player_attacks then 
		return 
	end
	
	for i, v in player_attacks do
		local Model = v.model

		if Model and Model:IsDescendantOf(workspace.Bosses.Models) then
			return Model.Parent
		end
	end
end

return function(Player: Player)
	if not Player then
		return
	end
	
	local Damage = 35
	
	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level

	Damage *= 1 + ((lvl - 1) * .6)
	
	local Boss = GetBoss(Player)

	if Boss then
		
		Network:PostAll("PlayEffectLightning", Boss)
		
		task.delay(.1, function()

			local Scale = Damage / 100
			
			for id, data in PetUtil.server_attacks[Player] do
				if not data.model or not data.model.Parent then continue end
				
				if data.model.Parent ~= Boss then
					continue
				end

				PetLevelService:GiveExp(
					Player,
					id,
					Damage / 10
				)
			end

			Network:PostAll(
				"DamagePopup", 
				Damage, 
				Boss.PrimaryPart
			)

			Network:Post(
				Player,
				"PlayEffectCreateDisplay", 
				Damage
			)
			
			ServerBossQueue:DealDamage(Player, Boss:GetAttribute("Area"), Damage)
		end)
		
		return true
	end
	
	local Targets = GetPickup(Player)
	
	if #Targets == 0 then
		return
	end

	local Target = #Targets == 1 and Targets[1] or Targets[math.random(1, #Targets)]
	
	if not Target then 
		return 
	end

	local Health = Target:GetAttribute("Health")
	local MaxHealth = Target:GetAttribute("MaxHealth")
	local Region = Target:GetAttribute("Region")
	local Amount = MaxHealth and MaxHealth / 1.5 --Target:GetAttribute("Amount") or 0
	local Currency = Target:GetAttribute("Currency") or "Coins"
	
	if not Health or not MaxHealth or not Region or not Amount then 
		return 
	end

	local temp_pos = Target.PrimaryPart.Position
	
	Network:PostAll("PlayEffectLightning", Target)

	task.delay(.1, function()

		local Scale = Damage / 100
		
		if Target:GetAttribute("Health") == 0 then
			return
		end

		DataService:GiveCurrency(
			Player,
			Currency,
			Amount * Scale,
			true
		)
		
		for id, data in PetUtil.server_attacks[Player] do
			if data.model ~= Target then
				continue
			end
			
			PetLevelService:GiveExp(
				Player,
				id,
				Damage / 10
			)
		end

		Network:Post(
			Player,
			"ShootCurrency", 
			10, 
			Player, 
			"Coins", 
			temp_pos
		)
		
		local dmg = math.clamp(
			Damage,
			0,
			Health
		)
		
		Network:PostAll(
			"DamagePopup", 
			dmg, 
			Target.PrimaryPart
		)
		
		Network:Post(
			Player,
			"PlayEffectCreateDisplay", 
			dmg
		)
		
		if Target:GetAttribute("Health") - dmg <= 0 then
			TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
			QuestService:UpdateType(Player, "Pickups", 1)
		end

		Target:SetAttribute(
			"Health", 
			Target:GetAttribute("Health") - dmg
		)
	end)
	
	return true
end