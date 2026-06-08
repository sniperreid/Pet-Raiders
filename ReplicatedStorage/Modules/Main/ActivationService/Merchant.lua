local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")

local Merch = {}

Merch.Type = "Client"

Merch.init = function(Activation)
	return Activation
end

Merch.Callback = function(Player, Activation)
	local Merchant = Activation.Name :: string
	local Type = Merchant:gsub("Merchant", "")

	Network:Fetch("OpenMerchant", Type)
end

return Merch