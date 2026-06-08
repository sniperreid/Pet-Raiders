local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local BossClass = Services.get("BossClass")
local WorldService = Services.get("WorldService")
local TaskService = Services.get("TaskService")
local math = Services.get("MathUtility")
local QuestService = Services.get("QuestService")

local PartyClass = require(script.Party)
local BattleEngine = require(script.BattleEngine)

local BossesFolder = workspace.Bosses
local PlayerRegions = BossesFolder.PlayerRegions

local WAssets = workspace.Assets
local WMap = WAssets.Map

local WLobby = WMap.Lobby

local qBosses = BossClass.BossData
local vBosses = {}

for i, v in qBosses do
	vBosses[v.world] = v
end

qBosses = vBosses

local ServerBossQueue = {}
ServerBossQueue.BossData = qBosses
ServerBossQueue.Boss_Fights = {}

function ServerBossQueue:CancelBattle(Area)
	local Fight = self.Boss_Fights[Area]
	
	if not Fight then return end
	
	local _party = table.clone(Fight.Party or {})
	
	-- clearing every-player in the party
	-- will ultimately cancel the battle
	-- due to no players
	for i, v in _party do
		self:ExitBossFight(v, Area)
	end
	
	-- clear _party for mem usage
	table.clear(_party)
	
	if not self.Boss_Fights[Area] then return end
	
	pcall(function()
		self.Boss_Fights[Area]:Destroy()
	end)
	
	self.Boss_Fights[Area] = nil
end

function ServerBossQueue:GetPlayersInThisBattle(Area)
	return self.Boss_Fights[Area] and self.Boss_Fights[Area].Party or {}
end

function ServerBossQueue:GetPlayersInAnyBattle()
	local PlayerList = {}
	
	for i, Fight in self.Boss_Fights do
		for i, v in Fight.Party do
			table.insert(PlayerList, v)
		end
	end
	
	return PlayerList
end

function ServerBossQueue:FlagPlayersWithoutBattles(inArea)
	local Flags = {}
	local InBattle = self:GetPlayersInAnyBattle()
	
	for i, PlayerWOBattle in Players:GetPlayers() do
		-- Player shouldn't have battle.
		if table.find(InBattle, PlayerWOBattle) then continue end
		local PlayerData = DataService:GetPlayerData(PlayerWOBattle)
		if inArea and not table.find(PlayerData.Areas, inArea) then continue end
		table.insert(Flags, PlayerWOBattle)
	end
	
	return Flags
end

function ServerBossQueue:PlayerIsInBattle(Player, Area)
	local BossFight = self.Boss_Fights[Area]
	
	-- will return false? if no bossfight
	-- will then return index of bossfight
	-- works the same way as table.find <- no idx = nil
	
	-- returning false to be safe ig
	-- and for readability
	-- in ternaries; false/nil doesn't matter
	-- and I lovveeee ternaries!!!
	return BossFight and BossFight:PlayerInParty(Player) or false
end

function ServerBossQueue:TeleportPlayer(Player, SpawnFolder)
	if SpawnFolder == "Lobby" then
		return self:TeleportPlayer(Player, WLobby.Spawns)
	end
	
	if typeof(SpawnFolder) ~= "Instance" then return end
	
	local _Spawns = SpawnFolder:GetChildren()
	local NSpawn = _Spawns[math.random(#_Spawns)]
	
	return Player.Character and Player.Character:PivotTo(NSpawn.CFrame * CFrame.new(0, 1, 0))
end

function ServerBossQueue:PlayerDiedInBattle(Player, Area)
	local BossFight = self.Boss_Fights[Area]
	
	-- we'll just replicate PlayerIsInBattle()
	-- but use it for finding the players in the "Died" table.
	return BossFight and BossFight:DeadInParty(Player) or false
end

function ServerBossQueue:GetReward(forPlayer, Area)
	local PlayerData = DataService:GetPlayerData(forPlayer)
	local Abilities = PlayerData.AbilitiesOwned
	
	local BossData = qBosses[Area]
	local rewards = BossData.rewards
	
	local TotalWeight = 0
	
	for i, v in rewards do
		if v.Type == "Ability" and table.find(Abilities, v.Name) then continue end
		
		TotalWeight += v.Chance or 0
	end
	
	local CurrentWeight = 0
	local RandomWeight = math.random() * TotalWeight
	
	for i, v in rewards do
		if v.Type == "Ability" and table.find(Abilities, v.Name) then continue end
		
		CurrentWeight += v.Chance or 0
		
		if CurrentWeight >= RandomWeight then
			return v
		end
	end
	
end

-- plug-in player arguments to assume the players
-- damage dealt and decide how much rewards they
-- should get.
function ServerBossQueue:GenerateRewards(Player, Area)
	local BossFight = self.Boss_Fights[Area]
	
	if not BossFight then return {} end
	
	local BossData = qBosses[Area]

	if not BossData then return end
	
	local Engine = BossFight.Engine
	local BossPhys = Engine.BossPhys
	
	local DamageTable = BossPhys.damage_dealt or {}
	local UserDamage = DamageTable[Player] or 0
	
	local MinRewards = 1
	local MaxRewards = 7
	
	local t = (UserDamage / BossPhys.max_health)
	
	local RewardCount = math.floor(
		math.clamp(
			math.Lerp(
				MinRewards,
				MaxRewards,
				t
			),
			MinRewards,
			MaxRewards
		)
	)
	
	local Rewards = {}
	
	for i = 1, RewardCount do table.insert(Rewards, self:GetReward(Player, Area)) end
	
	return Rewards
end

function ServerBossQueue:DefeatedBoss(Area)
	local BossFight = self.Boss_Fights[Area]
	
	if not BossFight then return end
	if not BossFight.Engine.battle_started then return end
	
	local BossData = qBosses[Area]
	
	if not BossData then return end
	
	local BossName = BossData.name
	
	for _, Player in BossFight.Party do
		
		-- Tasks
		
		local PlayerData = DataService:GetPlayerData(Player)
		
		if not PlayerData then
			continue
		end
		
		TaskService:UpdateProgress(Player, "Boss", 1, {Area=Area})
		QuestService:UpdateType(Player, "Boss", 1)
		
		-- Rewards
		
		local Rewards = self:GenerateRewards(Player, Area)
		
		DataService:ClaimRewards(Player, Rewards)
	end
	
	Network:PostAll("DisplayNewItem", {
		Type = "Message",
		Message = ("%s has been defeated!"):format(BossName)
	})
	
	-- Do rewards & stuff before clearing
	-- that will validate damage identifiers
	-- and more.
	self:CancelBattle(Area)
end

-- to be called in combat systems
-- registers damage for reward systems & more.
function ServerBossQueue:DealDamage(Player, Area, Damage)
	local BossFight = self.Boss_Fights[Area]
	
	if not BossFight or not BossFight.Engine or not BossFight.Engine.BossPhys then return end
	if not BossFight.Engine.BossPhys.TakeDamage then return end
	
	return BossFight.Engine.BossPhys:TakeDamage(Damage, Player)
end

function ServerBossQueue:StartBossFight(Area)
	local BossFight = self.Boss_Fights[Area]

	if BossFight then return BossFight end
	
	self.Boss_Fights[Area] = PartyClass.new()
	self.Boss_Fights[Area].Engine = BattleEngine.new(self, Area)
	
	return self.Boss_Fights[Area]
end

function ServerBossQueue:ExitBossFight(Player, Area)
	local BossFight = self.Boss_Fights[Area]
	if not BossFight then return end
	if not self:PlayerIsInBattle(Player, Area) then return end
	BossFight:Exit(Player)
	Network:Post(Player, "LeaveBattleClient", Area)
	self:TeleportPlayer(Player, "Lobby")
	if BossFight.Engine and BossFight.Engine.UpdateBossLevel then BossFight.Engine:UpdateBossLevel() end
	Network:Post(Player, "RegisterLoadingScreen", true, .5, Area)
	task.delay(1.5, function() Network:Post(Player, "RegisterLoadingScreen", false) end)
	if #BossFight.Party > 0 then return end
	if BossFight.Engine and BossFight.Engine.Destroy then BossFight.Engine:Destroy() end
	BossFight:Destroy()
	self.Boss_Fights[Area] = nil
end

function ServerBossQueue:JoinBossFight(Player, Area)
	local PlayersWOBattle = self:FlagPlayersWithoutBattles()
	
	-- player is already in a battle, this shouldn't happen yet it did?
	if not table.find(PlayersWOBattle, Player) then return end
	
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Health = Humanoid and Humanoid.Health or 0
	
	if Health <= 0 then return end
	
	local PlayerData = DataService:GetPlayerData(Player)
	local Areas = PlayerData.Areas
	
	local WorldAreaData = WorldService:GetUserWorld(Player).Areas
	
	-- find boss from area.
	local Boss = qBosses[Area]

	-- area exists in users world?
	local AreaExist
	
	-- {[number]: {Name: string}}
	for i, v in WorldAreaData do
		if v.Name == Area then
			AreaExist = v; break
		end
	end

	-- server errors should only occur;
	-- if the player sent an invalid request,
	-- shouldn't happen with lag, rather exploits.
	assert(AreaExist, ("'%s' is not a valid area."):format(Area))
	assert(table.find(PlayerData.Areas, Area), ("You don't own area '%s'"):format(Area))
	assert(Boss, ("there is no boss for area '%s'"):format(Area))
	
	local BossName = Boss.name
	local BossRewards = Boss.rewards

	-- no action should be taken against these players
	-- incase of very bad lag which could possibly result
	-- in bad requests of this case.
	assert(BossName, "boss has no name assigned to it.")
	assert(BossRewards, "boss has no rewards assigned to it.")
	
	local Boss_Folder = PlayerRegions:FindFirstChild(BossName)
	
	assert(Boss_Folder, ("no player region for boss '%s'"):format(BossName))
	
	-- this should insert into self.Boss_Fight if nil;
	-- other wise insert & new PartyClass
	local BossFight = self:StartBossFight(Area)
	
	-- this should probably be a guard clause
	-- but I don't think it's even possible
	-- for this to be nil lmao.
	assert(BossFight, "could not create valid bossfight.")
	
	-- if the engine is not active
	-- or boss is destroyed
	
	-- players should be able to join a fight
	-- even if boss is active.
	
	-- no assert
	-- simple guard clause to check if
	-- player is in the battle.
	if self:PlayerIsInBattle(Player, Area) then
		return
	end
	
	if self:PlayerDiedInBattle(Player, Area) then
		return
	end
	
	Network:Post(
		Player,
		"RegisterLoadingScreen",
		true,
		.5,
		"Boss Fight"
	)
	
	-- insert player into boss fight & make died connection.
	BossFight:Join(Player)
	BossFight.Engine.Maid:add(Humanoid.Died:Connect(function()
		self:ExitBossFight(Player, Area)
	end))
	
	Network:Post(Player, "StartedBattleClient", Area)
	
	-- update the level due to new players stat change.
	BossFight.Engine:UpdateBossLevel()
	
	-- party being 1 player means it's newly created (duhh)
	if #BossFight.Party <= 1 then
		for i, v in self:FlagPlayersWithoutBattles(Area) do
			Network:Post(v, "SendBattleInvites", Area)
		end
	end
	
	-- table.find(Party, Player) -> (number?)
	-- should return number due to Join(Player) 1 line down.
	-- and prior joins.
	local JoinID = BossFight:PlayerInParty(Player)
	
	-- we use SpawnsFolder to get the exact spawn id.
	local SpawnsFolder = Boss_Folder.Spawns
	local Spawns = SpawnsFolder:GetChildren()
	
	-- this is presumably why most languages
	-- use 0 as a base t index.
	-- luau uses 1 ofc
	
	-- use JoinID - 1 to normalize
	-- +1
	-- and retrieve base spawn index evenly.
	local NextSpawn = 1 + ((JoinID - 1) % #Spawns)
	
	-- this shouldn't happen considering we're using a modulator
	-- but just incase because coding is stupid.
	local Spawn = SpawnsFolder:FindFirstChild(NextSpawn) or SpawnsFolder[1]
	
	-- make it so players teleport into boss fight area soon.
	Character:PivotTo(Spawn.CFrame * CFrame.new(0, 1.5, 0))
	
	task.delay(1.5, function()
		if not Player.Parent then return end
		if not self:PlayerIsInBattle(Player, Area) then return end
		
		Network:Post(Player, "RegisterLoadingScreen", false)
		
		if not BossFight.Engine.BossPhys then return end
		
		-- this isn't exactly needed considering
		-- the update of the boss's level
		-- will update the health
		-- I think it's still necessary
		-- incase level doesn't change.
		if BossFight.Engine.BossPhys.onHealthChange then
			BossFight.Engine.BossPhys:onHealthChange()
		end
	end)
end

Network:Bind("JoinBossFight", function(...)
	ServerBossQueue:JoinBossFight(...)
end)

Network:Bind("ExitBossFight", function(...)
	ServerBossQueue:ExitBossFight(...)
end)

Players.PlayerRemoving:Connect(function(Player)
	for Area, Party in ServerBossQueue.Boss_Fights do
		ServerBossQueue:ExitBossFight(Player, Area)
	end
end)

return ServerBossQueue