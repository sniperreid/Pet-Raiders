local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules.Services)

local Network = Services.get("Network")
local BossClass = Services.get("BossClass")
local PetBuffService = Services.get("PetBuffService")
local DataService = Services.get("DataService")
local PlayerLevelService = Services.get("PlayerLevelService")
local RBXCleanUp = Services.get("RBXCleanUp")

local BattleEngine = {}
BattleEngine.IntermissionTime = 1
BattleEngine.BattleTime = 5 * 60 -- 5 minutes
BattleEngine.__index = BattleEngine

function BattleEngine:Destroy()
	if self.BossPhys and self.BossPhys.Destroy then
		self.BossPhys:Destroy()
	end
	
	if self.Maid then
		self.Maid:Clean()
		self.Maid = nil
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

function BattleEngine:SendUpdateSignal(...)
	for i, v in self.Queue:GetPlayersInThisBattle(self.Area) do
		Network:Post(v, ...)
	end
end

function BattleEngine:CreateTimer(t, except)
	local Start = tick()
	local was_excepted = false
	
	local e = function()
		if not except then
			return
		end
		
		if not except() then
			return
		end
		
		was_excepted = true
		
		return true
	end
	
	repeat
		if not self.Class or not self.Class.Party then
			was_excepted = true
			
			break
		end
		
		local dt = tick() - Start
		-- due to random floats like 29.999999 smh
		-- I should prob just use os.time
		-- but this is on the server, so tick is same (server CPU)
		local tr = math.ceil(t - dt)
		
		self:SendUpdateSignal("UpdateBattleTimer", tr)
		
		if e() then break end
		
		task.wait(1)
		
		if e() then break end	
	until tr <= 0
	
	if not self.SendUpdateSignal then return was_excepted end
	
	self:SendUpdateSignal("UpdateBattleTimer")
	
	return was_excepted
end

function BattleEngine:init()
	self.BossPhys = BossClass.new(self.Queue.BossData[self.Area].name)
	self.BossPhys.onHealthChange = function(_self)
		local phase = _self.phase
		local level = _self.level

		if phase > 1 then
			-- who is this blud?
			-- ts is a cloned variable blud
			level *= 1.5
		end

		local area = _self.area
		local health = _self.health
		local max_health = _self.max_health

		-- we post into all local networks
		-- for people who can join through portals.
		Network:PostAll("UpdateBossLevel", area, level, phase)

		for i, v in Players:GetPlayers() do
			-- we do the same here, but send it in for people who
			-- are in the battle.
			local PlayerState = self.battle_started and self.Queue:PlayerIsInBattle(v, area)
			
			Network:Post(
				v,
				"UpdateBossHealth",
				PlayerState,
				area,
				health,
				max_health
			)
		end
	end
	
	task.spawn(function()
		while task.wait(1) do
			if not self.UpdateBossLevel then break end
			
			self:UpdateBossLevel()
		end
	end)
	
	local was_excepted = self:CreateTimer(self.IntermissionTime)
	
	-- was excepted should be rendered when there is no queue
	-- or when there is an exception made through ?function?
	if was_excepted then return end
	
	for i, v in self.Queue:FlagPlayersWithoutBattles(self.Area) do
		Network:Post(v, "StartedBattleClient", self.Area)
	end
	
	self.battle_started = true
	self.BossPhys.engine:Init()
	
	self.BossPhys:onHealthChange()
	
	self:CreateTimer(self.BattleTime, function()
		-- check for if the boss has no health,
		-- or if boss model is nil?
		
		local Phys = self.BossPhys
		
		if not Phys then
			return true
		end
		
		if not Phys.model then
			return true
		end
		
		return Phys.health <= 0
	end)
	
	if not self.BossPhys then return end
	
	-- boss should be destroyed upon death
	-- clear health var from BossPhys
	-- ternary statement can return health or 0
	-- 0 being checked means you defeated the boss
	-- this should not happen when the timer is applied.
	local health = self.BossPhys.health or 0
	
	if health <= 0 then
		self.Queue:DefeatedBoss(self.Area)
	else
		self.Queue:CancelBattle(self.Area)
	end
	
	-- setting the queue's boss state as "Defeated"
	-- might manually destroy the engine
	if self.Destroy then self:Destroy() end
end

function BattleEngine:UpdateBossLevel()
	local Class = self.Class
	local Party = Class.Party
	
	-- Speed is a universal stat among all pets
	-- this should make an appropriate stage
	-- for all pets and players equally
	
	-- expect max speed to be 100 - 200?
	-- can be higher but should properly be divised by this.
	local TotalLevel = 0
	local MaxLevel = PlayerLevelService.MaxLevel
	
	for i, Player in Party do
		local PlayerData = DataService:GetPlayerData(Player)
		
		TotalLevel += (PlayerData.Level or 1)
	end
	
	if TotalLevel == 0 then return 1 end
	
	-- get the average of all pets from that party
	TotalLevel /= #Party
	
	-- clamp 1 - 300 to fix lvl 100 bug.
	TotalLevel = math.clamp(
		TotalLevel,
		1,
		MaxLevel
	)
	
	-- the boss level should scale up to the pets speed.
	-- don't scale based on area because
	-- max_health (hp_scale) should do this already
	-- *manually*
	
	if not self.BossPhys then return end
	if not self.BossPhys.onLevelChange then return end
	
	self.BossPhys:onLevelChange(TotalLevel)
end

function BattleEngine:new(Area)
	local Battle = setmetatable({
		Maid = RBXCleanUp.new(),
		Queue = self,
		Area = Area,
		Class = self.Boss_Fights[Area],
		Boss = self.BossData[Area]
	}, BattleEngine)
	
	task.spawn(function()
		Battle:init()
	end)
	
	return Battle
end

return BattleEngine