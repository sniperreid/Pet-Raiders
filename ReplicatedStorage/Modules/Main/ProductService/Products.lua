local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services:GetService("Network")

local Products = {}

Products.Products = {
	Revive = {
		ProductId = 3279659503,
		OnPurchase = function(self, Player)
		end,
	}
}

Products.Gamepasses = {
	Flashlight = {
		ProductId = 1198944578,
		OnPurchase = function(self, Player)
		end,
	},
}

return Products