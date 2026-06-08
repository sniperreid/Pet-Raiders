local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Services = require(Modules:WaitForChild("Services"))

local HoverManager = Services.get("HoverManager")

local GuiService
local Interface
local Frames
local StatsFrame
local Boosts

local GuiUtil

local HoverInstance

local module = {}

local ActiveHovers = {}

function module:Update(PlayerBoosts)
	if not GuiService then
		return
	end
	
	if not HoverInstance then
		return
	end
	
	local SeenThisTick = {}

	for i, v in PlayerBoosts do
		local Template = GuiUtil:CreateBoost(Boosts, {Name = i, Time = v})
		
		if not Template then
			continue
		end
		
		SeenThisTick[i] = true
		
		if v <= 0 then
			Template:Destroy()
			
			ActiveHovers[i] = nil
			HoverInstance.Data[i] = nil
			
			continue
		elseif not ActiveHovers[i] then
			ActiveHovers[i] = true
			HoverInstance:SubscribeData(i, {Name = i})
		end
	end
	
	for i in ActiveHovers do
		if not SeenThisTick[i] then
			ActiveHovers[i] = nil
			HoverInstance.Data[i] = nil
		end
	end
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = GS.Frames
		StatsFrame = Frames.StatsFrame
		Boosts = StatsFrame.Boosts
		
		GuiUtil = GuiService.GuiUtil
		
		HoverInstance = HoverManager:Bind(StatsFrame, Boosts, {
			Boost = true,
			HelpLabel = "Boost"
		})
		
		return self
	end,
})