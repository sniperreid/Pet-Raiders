local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local WorldService = {}

WorldService.Colors = {
	Desert = "Yellow",
	Snow = "White",
	Jungle = "Green",
	Ocean = "Light Blue",
	Space = "Purple"
}

WorldService.Worlds = {
	{
		Name = "Overworld",
		Spawn = "Spawn",
		Currency = "Coins",
		Areas = {
			[1] = {
				Name = "Spawn",
				-- Already Unlocked
			},
			
			[2] = {
				Name = "Desert",
				Currency = "Coins",
				Amount = 3_500
			},
			
			[3] = {
				Name = "Snow",
				Currency = "Coins",
				Amount = 50_000
			},
			
			[4] = {
				Name = "Jungle",
				Currency = "Coins",
				Amount = 650_000
			},
			
			[5] = {
				Name = "Ocean",
				Currency = "Coins",
				Amount = 5_000_000
			},
			
			[6] = {
				Name = "Space",
				Currency = "Coins",
				Amount = 15_000_000
			}
		}
	},
	
	{
		Name = "Moon",
		Spawn = "Base",
		Currency = "MoonCoins",
		Areas = {
			[1] = {
				Name = "Mars",
				Currency = "MoonCoins",
				Amount = 5_000
			},
		}
	}
}

function WorldService:GetWorldData(World)
	for i, v in self.Worlds do
		if v.Name == World then
			return v
		end
	end
	
	return self.Worlds[1]
end

function WorldService:GetUserWorld(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")
	local World = PlayerData.World
	
	return self:GetWorldData(World)
end

function WorldService:GetNextArea(CurrentArea)
	for _, World in self.Worlds do
		for i, Area in World.Areas do
			if Area.Name == CurrentArea then
				local NextArea = World.Areas[i + 1]

				return NextArea and NextArea.Name
			end
		end
	end
end

function WorldService:GetCurrentArea(Player)
	local PlayerData = DataService and DataService:GetPlayerData(Player) or Network:Fetch("GetClientData")

	local PlrAreas = PlayerData.Areas
	local PlrWorld = PlayerData.World

	local WorldData = self:GetWorldData(PlrWorld)
	local WorldAreas = WorldData.Areas

	local LastArea = 1

	for i, Area in WorldAreas do
		if table.find(PlrAreas, Area.Name) then
			if i > LastArea then
				LastArea = i
			end
		end
	end

	local AreaData = WorldAreas[LastArea]

	if not AreaData then
		return
	end

	return AreaData.Name
end

return WorldService