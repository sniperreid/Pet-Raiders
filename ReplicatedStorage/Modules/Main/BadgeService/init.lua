local BadgeAsync = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local Badges = require(script.Badges)

local BadgeService = {}

function BadgeService:GetBadgeData(BadgeName)
	return Badges[BadgeName]
end

function BadgeService:GetBadgeInfo(BadgeName)
	local BadgeData = self:GetBadgeData(BadgeName) or {}
	local BadgeID = BadgeData.BadgeId
		
	local success, info = pcall(function()
		return BadgeAsync:GetBadgeInfoAsync(BadgeID)
	end)

	if not success then
		return {
			IsEnabled = false
		}
	end
	
	return info
end

function BadgeService:AwardBadge(Player, BadgeName)
	local PlayerData = DataService:GetPlayerData(Player)
	
	if table.find(PlayerData.Badges, BadgeName) then
		return
	end
		
	local BadgeData = self:GetBadgeData(BadgeName)
	local BadgeInfo = self:GetBadgeInfo(BadgeName)
	
	if not BadgeInfo.IsEnabled then
		return
	end
	
	local success, errorMessage = pcall(function()
		return BadgeAsync:AwardBadge(Player.UserId, BadgeData.BadgeId)
	end)
	
	if not success then
		return
	end
	
	table.insert(
		PlayerData.Badges,
		BadgeName
	)
	
	DataService:SendUpdateSignal(Player, "Badges")
	
	if not BadgeData.OnRecieved then
		return
	end
	
	BadgeData:OnRecieved(Player)
end

return BadgeService