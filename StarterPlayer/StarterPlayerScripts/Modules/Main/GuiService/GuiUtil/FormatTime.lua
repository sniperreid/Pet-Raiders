local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local TweenService = Services.get("TweenV2")
local math = Services.get("MathUtility")
local Render = Services.get("RenderUtil").Number

local GuiService

local Module = {}

function Module:Create(Time, ...)
	if Time < 60 then
		return ("%s%s"):format(Time, "s")
	end

	return ("%s%s"):format((Time // 3600) > 0 and ("%ih "):format(Time // 3600) or "", (Time % 3600) // 60 > 0 and ("%im"):format((Time % 3600) // 60) or "")
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