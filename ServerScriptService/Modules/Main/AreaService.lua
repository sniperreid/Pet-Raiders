local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules.Services)

local TaskModule = Services.get("TaskModule")
local TaskService = Services.get("TaskService")
local DataService = Services.get("DataService")
local WorldService = Services.get("WorldService")

local AreaService = {}

function AreaService:AssignTasks(Player, Area)
	local Tasks = TaskModule[Area]

	if not Tasks then
		return
	end

	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	if not PlayerData.Tasks then
		return
	end
	
	PlayerData.Tasks = DataService.Utility.ShallowCopy(Tasks)
	
	DataService:SendUpdateSignal(Player, "Tasks")
end

function AreaService:HasCompletedArea(Player, Area)
	if not TaskModule[Area] then
		return
	end
	
	return true
end

return AreaService