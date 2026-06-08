local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

local EffectsService = {}

for _, VFX in script:GetChildren() do
	local VFXTitle = VFX.Name
	local VFX = require(VFX)
	
	if VFXTitle == "ShootCurrency" then
		VFX()
	end
	
	EffectsService[VFXTitle] = VFX
	
	Network:Bind("PlayEffect" .. VFXTitle, VFX)
end

return EffectsService