local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local TaskModule = Services.get("TaskModule")
local WorldService = Services.get("WorldService")

local TaskService = {}

function TaskService:Complete(Player, Area, Index)
	local PlayerData = DataService:GetPlayerData(Player)
	
	if PlayerData.Tasks[Index].Completed then
		return
	end

	PlayerData.Tasks[Index].Completed = true
	
	DataService:SendUpdateSignal(Player, "Tasks")
end

function TaskService:Get(Player)
	local PlayerData = DataService:GetPlayerData(Player)
	
	return PlayerData.Tasks
end

function TaskService:UpdateProgress(Player, Type, Increment, extra)
	local PlayerData = DataService:GetPlayerData(Player)
	local PlayerTasks = PlayerData.Tasks
	
	if not PlayerTasks then
		return
	end
	
	local Index

	for i, v in PlayerTasks do
		if v.Type == Type then
			Index = i
		end
	end
	
	if not Index then
		return
	end
	
	local TaskData = PlayerTasks[Index]
	
	if not TaskData then
		return
	end
	
	local NextArea = WorldService:GetNextArea(extra.Area)
	
	if TaskData.Area ~= NextArea then
		return
	end
	
	if TaskData.Type == "Pickups" then
		if not TaskData.PickupsBroken then
			return
		end
		
		if TaskData.Completed then
			return
		end
		
		PlayerTasks[Index].PickupsBroken += Increment
		
		if TaskData.PickupsBroken >= TaskData.Amount then
			self:Complete(Player, TaskData.Area, Index)
			
			Network:Post(Player, "DisplayNewItem", {
				Type = "Message",
				Message = ("You've completed '%s'!"):format(TaskData.Description)
			})
		end
	end
	
	if TaskData.Type == "Boss" then
		self:Complete(Player, TaskData.Area, Index)
		
		Network:Post(Player, "DisplayNewItem", {
			Type = "Message",
			Message = ("You've completed '%s'!"):format(TaskData.Description)
		})
	end
	
	DataService:SendUpdateSignal(Player, "Tasks")
end

function TaskService:GetTaskData(Area, Index)
	local Tasks = TaskModule[Area]

	if not Tasks then
		return
	end

	return Tasks[Index]
end

return TaskService