local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local QuestModule = Services.get("QuestModule")

local QuestService = {}

function QuestService:GetQuestData(QuestName: string)
	if not QuestName then
		return
	end

	if typeof(QuestName) ~= "string" then
		return
	end
	
	for i, v in QuestModule do
		if v.Name == QuestName then
			return v
		end
	end
	
	return
end

function QuestService:HasQuest(Player: Player, QuestName: string)
	if not Player or not QuestName then
		return ("No player/quest")
	end
	
	local PlayerData = DataService:GetPlayerData(Player)

	if not PlayerData then
		return warn("No player data")
	end
	
	for i, v in PlayerData.Quests do
		if v.Name == QuestName then
			return v
		end
	end
	
	return
end

function QuestService:RemoveQuest(Player: Player, QuestName: string)
	if not Player or not QuestName then
		return ("No player/quest")
	end

	local PlayerData = DataService:GetPlayerData(Player)

	if not PlayerData then
		return warn("No player data")
	end
	
	for i, v in PlayerData.Quests do
		if v.Name == QuestName then
			table.remove(PlayerData.Quests, i)
		end
	end
	
	DataService:SendUpdateSignal(Player, "Quests")
end

function QuestService:GiveQuest(Player: Player, QuestName: string)
	if not Player or not QuestName then
		return
	end
	
	local QuestData = self:GetQuestData(QuestName)
	
	if not QuestData then
		return
	end
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	local PlayerQuest = self:HasQuest(Player, QuestName)
	
	if PlayerQuest then
		return
	end
	
	table.insert(PlayerData.Quests, {
		Name = QuestName,
		Progress = 0
	})
	
	DataService:SendUpdateSignal(Player, "Quests")
end

function QuestService:CompleteQuest(Player: Player, QuestName: string)
	if not Player or not QuestName then
		return
	end
	
	local QuestData = self:GetQuestData(QuestName)

	if not QuestData then
		return
	end

	local PlayerQuest = self:HasQuest(Player, QuestName)

	if not PlayerQuest then
		return
	end
	
	self:RemoveQuest(Player, QuestName)
	
	for i, v in QuestData.Rewards do
		if v.Type == "Pet" then
			DataService:GivePet(Player, {
				Name = v.Name,
				Tier = v.Tier
			}, true)
		end
		
		if v.Type == "Boost" then
			DataService:GiveBoost(Player, v.Name, v.Amount)
		end
	end
	
	return Network:Post(Player, "DisplayNewItem", {
		Type = "Message",
		Message = ("You've completed '%s'!"):format(QuestData.Description)
	})
end

function QuestService:UpdateQuest(Player: Player, QuestName: string, Progress: number)
	if not Player or not QuestName or not Progress then
		return
	end
	
	local QuestData = self:GetQuestData(QuestName)

	if not QuestData then
		return
	end
	
	local PlayerQuest = self:HasQuest(Player, QuestName)

	if not PlayerQuest then
		return
	end
	
	if QuestData.Type == "Pickups" then
		PlayerQuest.Progress += Progress
		
		if PlayerQuest.Progress >= QuestData.Requirement then
			self:CompleteQuest(Player, QuestName)
		end
	end
	
	if QuestData.Type == "Boss" then
		self:CompleteQuest(Player, QuestName)
	end
	
	DataService:SendUpdateSignal(Player, "Quests")
end

function QuestService:UpdateType(Player: Player, Type: string, Progress: number)
	if not Player or not Type or not Progress then
		return
	end
	
	for i, v in QuestModule do
		if v.Type == Type then
			self:UpdateQuest(Player, v.Name, Progress)
		end
	end
end

return QuestService