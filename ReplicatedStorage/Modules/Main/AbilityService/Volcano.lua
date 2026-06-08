local HttpService = game:GetService("HttpService")
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

local function GetValidTargets()
	local Targets = {}

	for i, v in workspace.Pickups:GetChildren() do
		table.insert(Targets, v)
	end

	for i, v in CurrentBosses:GetChildren() do
		table.insert(Targets, v)
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

return function(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then return end

	local FloorRayOrigin = HumanoidRootPart.Position + Vector3.new(0, 100, 0)
	local FloorRayDirection = Vector3.new(0, -200, 0)

	local Params = RaycastParams.new()
	Params.FilterDescendantsInstances = {workspace.Assets}
	Params.FilterType = Enum.RaycastFilterType.Include

	local Result = workspace:Raycast(FloorRayOrigin, FloorRayDirection, Params)

	if not Result or not Result.Instance then return end

	if Result.Instance.Name ~= "Grass" then return end

	local Floor = Result.Instance
	local VolcanoPosition = Result.Position + (HumanoidRootPart.CFrame.LookVector * 15)

	local Eruptions = 10
	local MaxRetries = 100

	local FormingSpeed = 0.2
	local AttackSize = 20
	local Damage = 20
	local TravelSpeed = 120

	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level

	Damage *= 1 + ((lvl - 1) * .6)
	
	local FireballOrigin = VolcanoPosition + Vector3.new(0, 15, 0)
	
	local GUID = HttpService:GenerateGUID(false)
	
	Network:PostAll("SummonVolcano", VolcanoPosition, GUID)

	task.spawn(function()
		for i = 1, Eruptions do
			local Success = false
			local Attempts = 0

			while not Success and Attempts < MaxRetries do
				Attempts += 1

				local FloorSize = Floor.Size

				local RandomX = (math.random() - 0.5) * FloorSize.X
				local RandomZ = (math.random() - 0.5) * FloorSize.Z

				local RandomOffset = Vector3.new(RandomX, 0, RandomZ)

				local RandomPointOnFloor = Floor.CFrame:ToWorldSpace(CFrame.new(RandomOffset)).Position

				local EruptionRayOrigin = RandomPointOnFloor + Vector3.new(0, 100, 0)
				local EruptionRayDirection = Vector3.new(0, -200, 0)

				local EruptionRayResult = workspace:Raycast(EruptionRayOrigin, EruptionRayDirection, Params)

				if EruptionRayResult and EruptionRayResult.Instance and EruptionRayResult.Instance.Name == "Grass" then
					Success = true

					local ImpactPosition = EruptionRayResult.Position

					Network:PostAll("PlayEffectVolcano", FireballOrigin, ImpactPosition, FormingSpeed, AttackSize)

					local p0 = FireballOrigin + Vector3.new(0, 20, 0)
					local p2 = ImpactPosition
					local mid = (p0 + p2) / 2
					local p1 = mid + Vector3.new(0, 50, 0)

					local arc = (p0 - p1).Magnitude + (p1 - p2).Magnitude
					local travelDuration = arc / TravelSpeed

					local AttackSpeed = FormingSpeed + travelDuration

					task.delay(AttackSpeed, function()
						for i, v in GetValidTargets() do
							if not v:IsA("Model") or not v.PrimaryPart then
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

									if v:GetAttribute("Health") - Damage <= 0 then
										TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
										QuestService:UpdateType(Player, "Pickups", 1)
									end

									v:SetAttribute("Health", math.max(0, _Health - BurnDamage))
								end
							end)()
						end
					end)
				end
			end

			task.wait(0.5)
		end

		Network:PostAll("DestroyVolcano", GUID)
	end)

	return true
end