local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PetUtil = Services.get("PetUtil")
local PetLevelService = Services.get("PetLevelService")
local TaskService = Services.get("TaskService")
local QuestService = Services.get("QuestService")
local ServerBossQueue = Services.get("ServerBossQueue")

local BossesFolder = workspace.Bosses
local CurrentBosses = BossesFolder.Models

local function FindNearestTarget(Player: Player, Position: Vector3, ExcludeList: {[number]: Instance})
	local NearestTarget, MinDist = nil, 100

	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then return nil end

	local UnlockedAreas = PlayerData.Areas

	for _, Pickup in ipairs(workspace.Pickups:GetChildren()) do
		if not table.find(ExcludeList, Pickup) and Pickup:IsA("Model") and Pickup.PrimaryPart then
			local Region = Pickup:GetAttribute("Region")
			local isUnlocked = not Region or table.find(UnlockedAreas, Region)

			if isUnlocked then
				local Dist = (Pickup.PrimaryPart.Position - Position).Magnitude
				
				if Dist < MinDist then
					MinDist = Dist
					NearestTarget = Pickup
				end
			end
		end
	end

	for _, Boss in ipairs(CurrentBosses:GetChildren()) do
		if not table.find(ExcludeList, Boss) and Boss:IsA("Model") and Boss.PrimaryPart then
			local Dist = (Boss.PrimaryPart.Position - Position).Magnitude
			
			if Dist < MinDist then
				MinDist = Dist
				NearestTarget = Boss
			end
		end
	end

	return NearestTarget
end

local function DamageBoss(Player, v, Damage)
	ServerBossQueue:DealDamage(Player, v:GetAttribute("Area"), Damage)
end

return function(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then return end

	local ChainCount = 10
	local ChainDelay = 0.05
	local Damage = 75

	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level

	Damage *= 1 + ((lvl - 1) * .6)
	
	task.spawn(function()
		local ChainedTargets = {}
		local CurrentTarget = FindNearestTarget(Player, HumanoidRootPart.Position, ChainedTargets)
		
		for i = 1, ChainCount do
			if not CurrentTarget then break end

			table.insert(ChainedTargets, CurrentTarget)

			Network:PostAll("PlayEffectStormCharge", CurrentTarget)
			Network:Post(Player, "PlaySound", "LightZap", .45)

			if not CurrentTarget.PrimaryPart then return end

			CurrentTarget = FindNearestTarget(Player, CurrentTarget.PrimaryPart.Position, ChainedTargets)

			task.wait(ChainDelay)
		end
		
		for _, Target in ipairs(ChainedTargets) do
			if Target and Target.Parent then
				Network:PostAll("PlayEffectStormExplode", Target.PrimaryPart.Position)
				Network:Post(Player, "PlaySound", "Lightning", .45)

				if Target.Parent == CurrentBosses then
					DamageBoss(Player, Target, Damage)
				else
					local Health = Target:GetAttribute("Health")

					if Health and Health > 0 then
						local DamageDealt = math.min(Damage, Health)

						Target:SetAttribute("Health", Health - DamageDealt)
						Network:PostAll("DamagePopup", DamageDealt, Target.PrimaryPart)

						local MaxHealth = Target:GetAttribute("MaxHealth")
						local Region = Target:GetAttribute("Region")
						local Currency = Target:GetAttribute("Currency") or "Coins"
						local Amount = MaxHealth and MaxHealth / 1.5

						local Scale = DamageDealt / 100

						DataService:GiveCurrency(Player, Currency, Amount * Scale, true)
						Network:Post(Player, "ShootCurrency", 3, Player, Currency, Target.PrimaryPart.Position)

						for _, Pet in PetUtil.GetEquipped(Player) do
							PetLevelService:GiveExp(Player, Pet.ID, DamageDealt / 10)
						end

						if Target:GetAttribute("Health") <= 0 then
							TaskService:UpdateProgress(Player, "Pickups", 1, {Area=Region})
							QuestService:UpdateType(Player, "Pickups", 1)
						end
					end
				end
			end
		end
	end)

	return true
end