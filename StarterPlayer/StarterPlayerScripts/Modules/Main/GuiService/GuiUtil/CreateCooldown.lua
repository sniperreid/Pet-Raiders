local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local MaidClass = Services.get("MaidClass")
local RunService = Services.get("RunService")

local GuiService

local Module = {}

function Module:Create(Button, Time, ...)
	if not Button or not Time then
		return
	end
	
	local Maid = MaidClass.new()
	
	local Blackout = Maid:GiveTask(script.Blackout:Clone())
	Blackout.Parent = Button
	
	local TimeRemaining = Maid:GiveTask(Blackout.Time)
	
	local Start = tick()

	Maid:GiveTask(RunService.RenderStepped:Connect(function()
		local Elapsed = tick() - Start
		local Remaining = math.max(0, Time - Elapsed)

		TimeRemaining.Text = ("%.1f"):format(Remaining)

		if Remaining <= 0 then
			Maid:Clean()
		end
	end))
end

function Module:Give(GS)
	GuiService = GS

	return self
end

return function(Type, GSQ, ...)
	if Type == "Give" then
		return Module:Give(GSQ)
	end

	return Module:Create(Type, GSQ, ...)
end