local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local BadgeService = Services.get("BadgeService")
local DataService = Services.get("DataService")

local GroupId = game.CreatorId

local MeetDeveloper = {}
MeetDeveloper.GroupInfo = nil
MeetDeveloper.UserGroups = {}

function MeetDeveloper.get_user_info(user)
	
	if MeetDeveloper.UserGroups[user.UserId] then
		return MeetDeveloper.UserGroups[user.UserId]
	end
	
	MeetDeveloper.UserGroups[user.UserId] = {}
	
	local Info = GroupService:GetGroupsAsync(user.UserId)
	
	for i, v in Info do
		if v.Id == GroupId then
			MeetDeveloper.UserGroups[user.UserId] = v
			
			break
		end
	end
	
	return MeetDeveloper.UserGroups[user.UserId]
	
end

function MeetDeveloper.get_info()
	
	if MeetDeveloper.GroupInfo then
		return MeetDeveloper.GroupInfo
	end
	
	MeetDeveloper.GroupInfo = GroupService:GetGroupInfoAsync(GroupId)
	
	return MeetDeveloper.GroupInfo
	
end

function MeetDeveloper.check_met_dev(Player)
	
	local devs_met = {}
	
	for i, plr in Players:GetPlayers() do
		
		if plr == Player then
			continue
		end
		
		local info = MeetDeveloper.get_user_info(plr)
		
		if not info.Rank then
			continue
		end
		
		if info.Rank < 254 then
			continue
		end

		table.insert(
			devs_met,
			plr
		)
	end
	
	
	return devs_met
	
end

function MeetDeveloper.met_owner(Player)
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	if PlayerData.MetOwner then
		return
	end
	
	PlayerData.MetOwner = true
	DataService:SendUpdateSignal(Player, "MetOwner")
	
	DataService:GivePet(
		Player,
		{
			Name = "Blueshell"
		}
	)
	
	Network:Post(
		Player,
		"DisplayNewItem",
		{
			Type = "Message",
			Message = "You recieved 1x Blueshell Pet"
		}
	)
	
end

function MeetDeveloper.register_join()
	
	local GroupInfo = MeetDeveloper.get_info()
	
	for i, Player in Players:GetPlayers() do
		local devs_met = MeetDeveloper.check_met_dev(Player)
		
		for i, dev in devs_met do
			BadgeService:AwardBadge(Player, "You met a developer!")

			if dev.UserId ~= GroupInfo.Owner.Id then
				continue
			end
			
			MeetDeveloper.met_owner(Player)
		end
		
	end
end

Players.PlayerRemoving:Connect(function(Player)
	MeetDeveloper.UserGroups[Player.UserId] = nil
end)

return MeetDeveloper