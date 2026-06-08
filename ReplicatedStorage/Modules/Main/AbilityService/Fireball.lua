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

local BossesFolder = workspace.Bosses
local CurrentBosses = BossesFolder.Models

local function GetValidTargets(Areas)
	local Targets = {}

	for _, Pickup in ipairs(workspace.Pickups:GetChildren()) do
		if not table.find(Areas, Pickup:GetAttribute("Region")) then continue end

		table.insert(Targets, Pickup)
	end

	for _, Boss in ipairs(CurrentBosses:GetChildren()) do
		if not table.find(Areas, Boss:GetAttribute("Area")) then continue end

		table.insert(Targets, Boss)
	end

	return Targets
end

local function DamageBoss(Player, v, Damage)
	Network:PostAll(
		"PlayEffectBurn",
		v,
		10
	)
	
	ServerBossQueue:DealDamage(Player, v:GetAttribute("Area"), Damage)
	
	local BurnDamage = math.ceil(Damage / 10)

	coroutine.wrap(function()
		for _ = 1, 10 do
			task.wait(1)

			if not v then
				break
			end

			if not v.Parent then
				break
			end

			ServerBossQueue:DealDamage(Player, v:GetAttribute("Area"), BurnDamage)

			Network:Post(
				Player,
				"PlaySound",
				"Burn",
				.45
			)
		end
	end)()
end

return function(Player, MousePosition)
	if not Player then 
		return 
	end

	local Character = Player.Character
	
	if not Character then 
		return 
	end

	local FormingSpeed = 0.2
	local TravelSpeed = 120
	local AttackSize = 13
	local Damage = 25
	
	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level
	
	Damage *= 1 + ((lvl - 1) * .6)

	local Origin = Character:GetPivot()
	local Normal = (Origin.Position - MousePosition)
	local Distance = math.clamp(Normal.Magnitude, 0, 300)

	local p2 = (CFrame.new(Origin.Position, MousePosition) * CFrame.new(0, 0, -Distance)).Position
	local p0 = Origin.Position + Vector3.new(0, 20, 0)
	local mid = (p0 + p2) / 2
	local p1 = mid + Vector3.new(0, 50, 0)
	local arc = (p0 - p1).Magnitude + (p1 - p2).Magnitude

	local Duration = arc / TravelSpeed
	local AttackSpeed = FormingSpeed + Duration

	Network:PostAll(
		"PlayEffectFireball", 
		Character:GetPivot(),
		p2,
		FormingSpeed,
		Duration,
		AttackSize
	)

	task.delay(AttackSpeed, function()
		for i, v in GetValidTargets(p_data.Areas) do
			if not v:IsA("Model") then
				continue
			end
			
			if not v.PrimaryPart then
				continue
			end
			
			local pos = v:GetPivot().Position
			local mag = (pos - p2).Magnitude
			
			local as = AttackSize
			
			if v.Parent == CurrentBosses then
				local s = v:GetExtentsSize()
				local a = (s.X/2) + (s.Z/2)
				local r = a / 2
				
				as += r
			end
			
			if mag > as then
				continue
			end
			
			if v.Parent == CurrentBosses then
				DamageBoss(Player, v, Damage)
				
				continue
			end
			
			local Health = v:GetAttribute("Health")
			
			if not Health or Health <= 0 then
				continue
			end
			
			local Health = v:GetAttribute("Health")
			local MaxHealth = v:GetAttribute("MaxHealth")
			local Region = v:GetAttribute("Region")
			local Currency = v:GetAttribute("Currency") or "Coins"
			local Amount = MaxHealth and MaxHealth / 1.5
			
			local PlayerData = DataService:GetPlayerData(Player)
			local Areas = PlayerData.Areas
			
			if Region and not table.find(Areas, Region) then
				return
			end
			
			local Scale = Damage / 100
			
			DataService:GiveCurrency(
				Player, 
				Currency, 
				Amount * Scale, 
				true
			)

			Network:Post(
				Player, 
				"ShootCurrency", 
				3, 
				Player, 
				Currency, 
				pos
			)
			
			for _, Pet in PetUtil.GetEquipped(Player) do
				PetLevelService:GiveExp(Player, Pet.ID, Damage / 10)
			end

			local Damage = math.clamp(Damage, 0, v:GetAttribute("Health"))
			
			Network:PostAll(
				"DamagePopup", 
				Damage, 
				v.PrimaryPart
			)
			
			Network:Post(
				Player,
				"PlayEffectCreateDisplay", 
				Damage
			)
			
			Network:PostAll(
				"PlayEffectBurn",
				v,
				10
			)
			
			if v:GetAttribute("Health") - Damage <= 0 then
				TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
				QuestService:UpdateType(Player, "Pickups", 1)
			end
			
			v:SetAttribute("Health", v:GetAttribute("Health") - Damage)
			
			if not v then
				return
			end
			
			local BurnDamage = math.ceil(Damage / 10)
			
			local b_scale = BurnDamage / 100

			coroutine.wrap(function()
				for _ = 1, 10 do
					task.wait(1)
					
					if not v then
						break
					end
					
					if not v.Parent then
						break
					end
					
					local _Health = v:GetAttribute("Health")
					
					if not _Health or _Health <= 0 then
						break
					end
					
					DataService:GiveCurrency(
						Player, 
						Currency, 
						Amount * b_scale, 
						true
					)
					
					Network:PostAll(
						"DamagePopup",
						BurnDamage,
						v.PrimaryPart
					)
					
					Network:Post(
						Player,
						"PlayEffectCreateDisplay", 
						BurnDamage
					)
					
					Network:Post(
						Player,
						"PlaySound",
						"Burn",
						.45
					)
					
					if v:GetAttribute("Health") - Damage <= 0 then
						TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
						QuestService:UpdateType(Player, "Pickups", 1)
					end
					
					v:SetAttribute("Health", math.max(0, _Health - BurnDamage))
				end
			end)()
		end
	end)

	return true
end