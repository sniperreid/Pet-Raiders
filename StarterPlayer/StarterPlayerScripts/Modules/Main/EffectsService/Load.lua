-------------------------- Framework --------------------------

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local GuiService = Services.get("GuiService")

---------------------- Services ----------------------

return function(...)
	GuiService:CreateTransition(...)
end