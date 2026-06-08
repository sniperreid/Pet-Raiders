local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local FX = Assets:WaitForChild("FX")

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

			if not v or not v.Parent then
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

return function(Player: Player, MousePosition: Vector3)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	if not Character then return end

	local FormingTime = 3
	local MeteorSpeed = 55
	local AttackSize = 35
	local Damage = 100
	local SpawnHeight = 100

	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level

	Damage *= 1 + ((lvl - 1) * .6)

	local RayOrigin = MousePosition + Vector3.new(0, 200, 0)
	local RayDirection = Vector3.new(0, -400, 0)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Assets}
	Params.FilterType = Enum.RaycastFilterType.Include

	local Result = workspace:Raycast(RayOrigin, RayDirection, Params)

	if not Result or not Result.Instance or Result.Instance.Name ~= "Grass" then
		return
	end

	local ImpactPosition = Result.Position

	local RandomX = math.random(-200, 200)
	local RandomZ = math.random(-200, 200)
	local HorizontalOffset = Vector3.new(RandomX, 0, RandomZ)

	local SpawnPosition = ImpactPosition + Vector3.new(0, SpawnHeight, 0) + HorizontalOffset

	local TravelDistance = (SpawnPosition - ImpactPosition).Magnitude
	local TravelTime = TravelDistance / MeteorSpeed

	local TotalAttackTime = FormingTime + TravelTime

	Network:PostAll("PlayEffectMeteor", SpawnPosition, ImpactPosition, FormingTime, TravelTime, AttackSize)

	task.delay(TotalAttackTime, function()
		for i, v in GetValidTargets(p_data.Areas) do
			if not v or not v.Parent or not v:IsA("Model") or not v.PrimaryPart then
				continue
			end

			local pos = v:GetPivot().Position
			local mag = (pos - ImpactPosition).Magnitude

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

			local MaxHealth = v:GetAttribute("MaxHealth")
			local Region = v:GetAttribute("Region")
			local Currency = v:GetAttribute("Currency") or "Coins"
			local Amount = MaxHealth and MaxHealth / 1.5

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

			local DamageDealt = math.clamp(Damage, 0, v:GetAttribute("Health"))

			Network:PostAll(
				"DamagePopup", 
				DamageDealt, 
				v.PrimaryPart
			)

			Network:Post(
				Player,
				"PlayEffectCreateDisplay", 
				DamageDealt
			)

			Network:PostAll(
				"PlayEffectBurn",
				v,
				10
			)

			if v:GetAttribute("Health") - DamageDealt <= 0 then
				TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
				QuestService:UpdateType(Player, "Pickups", 1)
			end

			v:SetAttribute("Health", v:GetAttribute("Health") - DamageDealt)

			if not v then
				return
			end

			local BurnDamage = math.ceil(DamageDealt / 10)
			local b_scale = BurnDamage / 100

			coroutine.wrap(function()
				for _ = 1, 10 do
					task.wait(1)

					if not v or not v.Parent then
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

					v:SetAttribute("Health", math.max(0, _Health - BurnDamage))
				end
			end)()
		end
	end)

	return true
end