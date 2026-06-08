local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PetModule = Services.get("PetModule")
local PetUtil = Services.get("PetUtil")
local QuestService = Services.get("QuestService")

local StarterService = {}

StarterService.Starters = {
	"Doggy",
	"Kitty"
}

function StarterService:Load(Player)
	local PlayerData = DataService:GetPlayerData(Player)
	local PlayerStarter = PlayerData.Starter
	
	if PlayerStarter then
		return
	end
	
	Network:Post(
		Player,
		"OpenStarterMenu",
		self.Starters
	)
	
	QuestService:GiveQuest(Player, "Pickups1")
	QuestService:GiveQuest(Player, "Boss1")
end

function StarterService:Select(Player, Starter)
	local PlayerData = DataService:GetPlayerData(Player)
	local PlayerStarter = PlayerData.Starter
	
	if not table.find(self.Starters, Starter) then
		return
	end
	
	if PlayerStarter then
		return
	end
	
	local StarterData = DataService:GivePet(
		Player,
		{
			Name = Starter,
			CantAutoDelete = true
		}
	)
	
	local HatchInfo = {
		Name = Starter,
		Tier = "Normal",
		ManualEggHatch = true
	}
	
	local pm_data = PetModule[Starter]
	
	Network:Post(Player, "HatchEggClient", {
		Speed = 1,
		Egg = "Common Egg",
		Pets = {
			HatchInfo
		},
		Secret = pm_data.Rarity == "Secret"
	})
	
	PetUtil.SetEquip(
		Player,
		StarterData.ID,
		true
	)
	
	PlayerData.Starter = StarterData
	
	DataService:SendUpdateSignal(
		Player,
		"Starter"
	)
	
	-- Network:Post(Player, "PromptTutorial")
	
end

Network:Bind("SelectStarter", function(...)
	return StarterService:Select(...)
end)

return StarterService