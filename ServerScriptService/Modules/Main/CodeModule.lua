local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local Codes = {
	["release"] = {
		Rewards = {
			{
				Type = "Pet",
				
				Name = "Doggy",
				Tier = "Normal"
			},
			
			{
				Type = "Boost",

				Name = "Lucky",
				Amount = 5 * 60
			}
		},
		
		Expiration = nil
	},
	
	["spidey"] = {
		Rewards = {
			{
				Type = "Pet",

				Name = "King Doggy",
				Tier = "Shiny"
			},
			
			{
				Type = "Pet",

				Name = "King Doggy",
				Tier = "Shiny"
			},

			{
				Type = "Pet",

				Name = "King Doggy",
				Tier = "Shiny"
			},

			{
				Type = "Boost",

				Name = "Lucky",
				Amount = 10 * 60 * 60
			},
			
			{
				Type = "Boost",

				Name = "Speedy",
				Amount = 10 * 60 * 60
			},
			
			{
				Type = "Boost",

				Name = "Ultra Lucky",
				Amount = 10 * 60 * 60
			},
			
			{
				Type = "Boost",

				Name = "Developer Lucky",
				Amount = 10 * 60 * 60
			}
		}
	}
}

local module = {}

function module:RedeemCode(Player: Player, Code: string)
	if not Player or typeof(Code) ~= "string" then
		return ("Something went wrong."), Color3.fromRGB(255, 61, 64)
	end
	
	Code = Code:lower()
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return ("Something went wrong."), Color3.fromRGB(255, 61, 64)
	end
	
	if table.find(PlayerData.Codes, Code) then
		return ("Already redeemed code."), Color3.fromRGB(255, 61, 64)
	end
	
	local CodeData = Codes[Code]
	
	if not CodeData then
		return ("Invalid code."), Color3.fromRGB(255, 61, 64)
	end
	
	local PetsGiven = {}
	
	for i, v in CodeData.Rewards do
		if v.Type == "Pet" then
			local Pet = {
				Name = v.Name,
				Tier = v.Tier
			}
			
			DataService:GivePet(Player, Pet)
			
			table.insert(PetsGiven, Pet)
		end
		
		if v.Type == "Boost" then
			DataService:GiveBoost(Player, v.Name, v.Amount)
		end
	end
	
	if #PetsGiven > 0 then
		Network:Post(Player, "HatchEggClient", {
			Speed = 1.5,
			Egg = "Common Egg",
			Pets = PetsGiven,
			Secret = false
		})
	end
	
	table.insert(PlayerData.Codes, Code)
	
	DataService:SendUpdateSignal(Player, "Codes")
	
	return ("Successfully redeemed code!"), Color3.fromRGB(123, 253, 87)
end

Network:Bind("RedeemCode", function(...)
	return module:RedeemCode(...)
end)

return module