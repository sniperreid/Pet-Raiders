local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local RS_Gui = RS_Assets:WaitForChild("GUI")

local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local MaidClass = Services.get("MaidClass")
local States = Services.get("States")
local PetUtil = Services.get("PetUtil")
local StarterService = Services.get("StarterService")
local LinkService = Services.get("LinkService")
local MeetDeveloper = Services.get("MeetDeveloper")
local AreaService = Services.get("AreaService")
local WorldService = Services.get("WorldService")
local TaskService = Services.get("TaskService")
local TaskModule = Services.get("TaskModule")
local PlayerLevelService = Services.get("PlayerLevelService")
local ChallengeService = Services.get("ChallengeService")
local PetEnchantService = Services.get("PetEnchantService")
local TitlesService = Services.get("TitlesService")

local Devs = {
	1914386899,
	3189284332
}

local PlayerLoader = {}
PlayerLoader.cache = {}

function PlayerLoader.GetPlayersLoaded(Player)
	return PlayerLoader.cache[Player.UserId]
end

function PlayerLoader.InsertPlayerLoaded(Player)
	local Cache = PlayerLoader.GetPlayersLoaded(Player)

	if Cache then
		return Cache
	end

	PlayerLoader.cache[Player.UserId] = {
		Data = nil,
		Maid = MaidClass.new()
	}

	return PlayerLoader.cache[Player.UserId]
end

function PlayerLoader.LoadPlayerData(Player)
	local Loaded = PlayerLoader.GetPlayersLoaded(Player) or PlayerLoader.InsertPlayerLoaded(Player)
	local Data = Loaded.Data

	if Data then
		return Data
	end

	Loaded.Data = DataService:GetPlayerData(Player)

	return Loaded.Data
end

function PlayerLoader.LoadCharacter(Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	-- Safe Humanoid lookup — Humanoid may not be ready yet on some respawns
	local Humanoid = Character:WaitForChild("Humanoid", 10)
	if not Humanoid then return end

	-- HumanoidRootPart with timeout instead of math.huge — never wait forever for a child
	local Root = Character:WaitForChild("HumanoidRootPart", 10)
	if not Root then return end

	Character.Archivable = true
	Character.PrimaryPart = Root

	Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local PlayerData = DataService:GetPlayerData(Player)
	if not PlayerData then return end

	local Head = Character:FindFirstChild("Head")
	if Head and not Head:FindFirstChild("PlayerTitle") then
		local PlayerTitle = RS_Assets.GUI.PlayerTitle:Clone()

		PlayerTitle.DisplayName.Text = Player.DisplayName
		PlayerTitle.PlayerName.Text = "@" .. Player.Name
		PlayerTitle.PlayerLevel.Text = ("Lvl. %d"):format(PlayerData.Level or 1)

		PlayerTitle.Parent = Head
	end

	TitlesService:UpdateOverhead(Player)

	for _, v in Character:GetDescendants() do
		if not v:IsA("BasePart") then
			continue
		end

		v.CollisionGroup = "Character"
	end
end

function PlayerLoader.Load(Player)
	if Player:GetAttribute("Loaded") then
		return
	end

	Player:SetAttribute("Loaded", true)

	States.new(Player)
	States.set(Player, "LogTime", os.time())

	PlayerLoader.LoadCharacter(Player)

	StarterService:Load(Player)

	task.spawn(function()
		LinkService:AttachUserID(Player)
		MeetDeveloper.register_join()
	end)

	local PlayerData = DataService:GetPlayerData(Player)
	if not PlayerData then return end

	task.delay(1, function()
		PetUtil.LoadPets(Player)
	end)

	if not PlayerData.Tasks then
		PlayerData.Tasks = DataService.Utility.ShallowCopy(TaskModule["Desert"])
		DataService:SendUpdateSignal(Player, "Tasks")
	end

	table.clear(PlayerData.AreasUnlockedOnJoin)

	for _, v in PlayerData.Areas do
		table.insert(PlayerData.AreasUnlockedOnJoin, v)
	end

	DataService:SendUpdateSignal(Player, "AreasUnlockedOnJoin")

	task.delay(1, function()
		table.clear(PlayerData.Gifts)
		DataService:SendUpdateSignal(Player, "Gifts")
	end)

	local Cache = PlayerLoader.InsertPlayerLoaded(Player)
	local Maid = Cache.Maid

	Maid:GiveTask(
		Player.CharacterAdded:Connect(function()
			PlayerLoader.LoadCharacter(Player)
		end)
	)

	-- Boost countdown / challenge tick. Maid-tracked so it stops on disconnect.
	Maid:GiveTask(task.spawn(function()
		while true do
			task.wait(1)

			if not Player.Parent then
				break
			end

			ChallengeService:Update(Player)

			for boost in pairs(PlayerData.Boosts) do
				if PlayerData.Boosts[boost] <= 0 then
					PlayerData.Boosts[boost] = nil
				else
					PlayerData.Boosts[boost] -= 1
				end

				DataService:SendUpdateSignal(Player, "Boosts")
			end
		end
	end))
end

function PlayerLoader.Disconnect(Player)
	local Cache = PlayerLoader.cache[Player.UserId]

	if not Cache then
		return
	end

	Cache.Maid:Clean()

	PlayerLoader.cache[Player.UserId] = nil

	DataService:SavePlayerData(Player)
end

Network:Bind("InvokePlayerData", function(...)
	return PlayerLoader.LoadPlayerData(...)
end)

Network:Bind("LoadPlayer", function(...)
	return PlayerLoader.Load(...)
end)

return PlayerLoader
