local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RS_Assets = ReplicatedStorage:WaitForChild("Assets")
local RS_Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(RS_Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local PetModule = Services.get("PetModule")
local RarityModule = Services.get("RarityModule")
local TiersModule = Services.get("TiersModule")
local PetBuffService = Services.get("PetBuffService")
local WorldService = Services.get("WorldService")

local DefaultStat = "Coins"

local SortMethods = {}
SortMethods.__index = SortMethods

function SortMethods:SortPets(Table)
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local World = PlayerData.World or "Overworld"
	
	local DefaultStat = WorldService:GetWorldData(World).Currency
	
	local StatToSort = self.Stat or DefaultStat
	local Whitelist = self.Whitelist or {}
	
	return table.sort(Table, function(a, b)
		
		local aID = a.ID
		local aName = a.Name
		local aTier = a.Tier
		local aExp = a.Exp
		local aLevel = a.Level
		local aEquipped = a.Equipped
		
		local bID = b.ID
		local bName = b.Name
		local bTier = b.Tier
		local bExp = b.Exp
		local bLevel = b.Level
		local bEquipped = b.Equipped
		
		local aEState = aEquipped and 1 or 0
		local bEState = bEquipped and 1 or 0
		
		--local aWState = table.find(Whitelist, aID) and 1 or 0
		--local bWState = table.find(Whitelist, bID) and 1 or 0
		
		--if aWState ~= bWState then
		--	return aWState > bWState
		--end

		if aEState ~= bEState then
			return aEState > bEState
		end
		
		local aData = PetModule[aName]
		local bData = PetModule[bName]
		
		local aRarity = aData.Rarity
		local bRarity = bData.Rarity
		
		local aRData = RarityModule[aRarity]
		local bRData = RarityModule[bRarity]
		
		local aTData = TiersModule[aTier]
		local bTData = TiersModule[bTier]
		
		if aTData.Buff ~= bTData.Buff then
			return aTData.Buff > bTData.Buff
		end
		
		if aRData.Index ~= bRData.Index then
			return aRData.Index > bRData.Index
		end
		
		local aBuff = PetBuffService:GetLocalBuff(a)
		local bBuff = PetBuffService:GetLocalBuff(b)

		local Stat1 = aBuff[StatToSort] or 0
		local Stat2 = bBuff[StatToSort] or 0

		if Stat1 ~= Stat2 then
			return Stat1 > Stat2
		end
		
		return aName:len() > bName:len()
	end)
end

function SortMethods:addWhitelist(...)
	self.Whitelist = (...)
end

function SortMethods:Sort(...)
	local Method = self.Method
	local Signal = self["Sort" .. Method]
	
	if not Signal then
		return
	end
	
	return Signal(self, ...)
end

function SortMethods:SubscribeStat(Stat)
	self.Stat = Stat or self.Stat or DefaultStat
end

function SortMethods.new(Method)
	return setmetatable({
		Method = Method or "Pets",
		Stat = DefaultStat
	}, SortMethods)
end

return SortMethods