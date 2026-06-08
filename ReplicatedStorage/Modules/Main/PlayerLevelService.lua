local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get "Network"
local DataService = Services.get "DataService"

local PlayerLevel = {}
PlayerLevel.MaxLevel = 70

PlayerLevel.MinExp = 30
PlayerLevel.MaxExp = 350
PlayerLevel.ExpCap = 30 -- the level that EXP stops at, then capping at [self.MaxExp]

function PlayerLevel:GrantExp(Player: Player, Exp: number)
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then return end
	
	local PlayerLevel = PlayerData.Level
	local PlayerExp = PlayerData.Exp
	
	local RequiredExp = self:GetExpRequired(Player)
	
	PlayerData.Exp += Exp
	
	local gained_lvl = false
	
	while true do
		if PlayerData.Level >= self.MaxLevel then
			-- Reached the level cap — don't bank further EXP past the ceiling.
			PlayerData.Exp = 0
			gained_lvl = gained_lvl or false
			break
		end

		if PlayerData.Exp < RequiredExp then
			break
		end

		PlayerData.Level += 1
		PlayerData.Exp -= RequiredExp

		gained_lvl = true

		RequiredExp = self:GetExpRequired(Player)
	end
	
	if gained_lvl then DataService:SendUpdateSignal(Player, "Level") end
	DataService:SendUpdateSignal(Player, "Exp")
end

function PlayerLevel:GetExpRequired(Player: Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	
	if not PlayerData then return end
	
	local PlayerLevel = PlayerData.Level
	
	local t = math.clamp((PlayerLevel-1) / (self.ExpCap-1), 0, 1)
	local s = 2.2 -- curve steepness
	
	return math.floor(
		self.MinExp + (self.MaxExp - self.MinExp) * math.pow(t, s)
	)
end

return PlayerLevel