local RunService = game:GetService("RunService")

local RoInteract = script.Parent

for i, v in script:GetChildren() do
	v.Parent = RoInteract
end

local AtomicBinder = require(RoInteract.AtomicBinder)
local Run = require(RoInteract.Run)
local infoDictionary = require(RoInteract.infoDictionary)
local Inter_act = require(RoInteract)
local Source = RoInteract.RepSource

local EventsFolder = RoInteract:FindFirstChild("Events") or Instance.new("Folder", RoInteract)
EventsFolder.Name = "Events"

local initializer = RoInteract:FindFirstChild("init") or Instance.new("Script", RoInteract)
initializer.Name = "init"

if not RunService:IsRunMode() then
	initializer.Source = "local RoAct = script.Parent local Run = require(RoAct.Run) return Run('onInit')"
end

local RoInstance = {}

function RoInstance:readInfo(Event)
	local Binder = require(RoInteract)

	for i, v in Binder.Events do
		if v.Event ~= Event then
			continue
		end

		if v.Running then
			continue
		end

		v.Running = true
		
		Binder.Object = RoInteract.Parent
		
		AtomicBinder:OverwriteSource(RoInteract)
		
		coroutine.wrap(function()
			for i, Info in v.Info do
				infoDictionary[Info.Type](Binder, Info)
			end

			v.Running = false
		end)()
	end
end

local usedInstances = {
	"ClickDetector"
}

local EventCreation = {
	onClick = function()
		return Instance.new(usedInstances[1])
	end,
}

local EventConnection = {
	onClick = function(NewCreation, Event)
		return NewCreation.MouseClick:Connect(function(Player)
			local Binder = require(RoInteract)
			
			Binder.Player = Player
			
			warn(Binder)
			
			return Run(Event)
		end)
	end,
}

function RoInstance:CreateEvents()
	for i, v in RoInteract.Parent:GetChildren() do
		if not table.find(usedInstances, v.ClassName) then
			continue
		end
		
		v:Destroy()
	end
	
	local Binder = require(RoInteract)
	
	for i, v in Binder.Events do
		local Event = v.Event
		local newCreation = EventCreation[Event]
		
		if not newCreation then
			continue
		end
		
		local newInstance = newCreation()
		newInstance.Parent = RoInteract.Parent
		
		EventConnection[Event](newInstance, Event)
	end
end

RoInstance:CreateEvents()

return RoInstance