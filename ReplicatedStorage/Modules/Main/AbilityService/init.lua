local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local AbilityModule = Services.get("AbilityModule")

local AbilityService = {}

local Cooldowns = {}

local Cooldown_Time = {}

for i, v in AbilityModule do
	Cooldown_Time[i] = v.Cooldown or Cooldown_Time[i]
end

Network:Bind("InvokeAbility", function(Player: Player, Ability: string, ...)
	if not Player or not Ability then
		return
	end
	
	if not Cooldown_Time[Ability] then
		return
	end
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	if not table.find(PlayerData.Abilities, Ability) then
		return
	end
	
	local Module = script:FindFirstChild(Ability)
	
	if not Module then
		return
	end
	
	local Now = tick()

	Cooldowns[Player] = Cooldowns[Player] or {}

	local Last = Cooldowns[Player][Ability] or 0
	local Time = Cooldown_Time[Ability] or 0

	if Now - Last < Time then
		return
	end

	Cooldowns[Player][Ability] = Now
	
	local Success = require(Module)(Player, ...)
	
	if not Success then
		Cooldowns[Player][Ability] = nil
		return
	end
	
	Network:Post(
		Player, 
		"DisplayCooldown", 
		Ability, 
		Cooldown_Time[Ability]
	)
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	if not Player then
		return
	end

	Cooldowns[Player] = nil
end)

return AbilityService