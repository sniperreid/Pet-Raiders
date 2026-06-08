local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local ServerBossQueue = Services.get("ServerBossQueue")
local PetUtil = Services.get("PetUtil")
local PetLevelService = Services.get("PetLevelService")
local TaskService = Services.get("TaskService")
local QuestService = Services.get("QuestService")

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
	ServerBossQueue:DealDamage(Player, v:GetAttribute("Area"), Damage)
end

return function(Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	if not Character then return end

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

	if not HumanoidRootPart then return end

	local Range = 20
	local Damage = 40

	local p_data = DataService:GetPlayerData(Player)
	local lvl = p_data.Level

	Damage *= 1 + ((lvl - 1) * .6)

	Network:PostAll("PlayEffectIce Aura", HumanoidRootPart)

	task.spawn(function()
		for i = 1, 4 do
			Network:Post(
				Player,
				"PlaySound",
				"Ice",
				.45
			)

			for _, Target in ipairs(GetValidTargets(p_data.Areas)) do
				if Target:IsA("Model") and Target.PrimaryPart then
					if (Target.PrimaryPart.Position - HumanoidRootPart.Position).Magnitude <= Range then
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
			end

			task.wait(.5)
		end
	end)

	return true
end