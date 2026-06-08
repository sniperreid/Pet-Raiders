--[[

Credit to @0astralz for inspo

]]

local AreaEvents = {}
AreaEvents.IterationTime = 15 * 60
AreaEvents.SpawnOnInit = false
AreaEvents.DestroyTime = 2 * 60

AreaEvents.LastEvent = nil
AreaEvents.Events = {}

function AreaEvents.Random()
	return AreaEvents.Events[math.random(#AreaEvents.Events)]
end

function AreaEvents:DespawnActiveEvent()
	if not self.LastEvent then return end
	
	self.LastEvent:Destroy()
	self.LastEvent = nil
end

function AreaEvents:SpawnRandomEvent()
	local Event
	
	repeat task.wait()
		Event = AreaEvents.Random()
	until self.LastEvent ~= Event
	
	self.LastEvent = Event
	
	workspace:SetAttribute("ActiveEvent", Event)
	
	Event:init()
	
	task.delay(Event.DestroyTime or self.DestroyTime, function()
		self:DespawnActiveEvent()
	end)
end

function AreaEvents:init()
	task.spawn(function()
		while true do
			if not self.SpawnOnInit then
				task.wait(self.IterationTime)
			end
			
			self:SpawnRandomEvent()
			
			repeat task.wait()
				
			until not self.LastEvent
			
			if self.SpawnOnInit then
				task.wait(self.IterationTime)
			end
		end
	end)
end

AreaEvents:init()

return AreaEvents