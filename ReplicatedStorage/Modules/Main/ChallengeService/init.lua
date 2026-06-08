local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get "Network"
local DataService = Services.get "DataService"
local PlayerLevelService = Services.get "PlayerLevelService"

local ChallengeService = {}

ChallengeService.TimeScales = {
	Daily = 60 * 60 * 24,
	Hourly = 60 * 60
}

ChallengeService.FillAmounts = 3
ChallengeService.Challenges = require(script.Challenges)

function ChallengeService:HasChallenge(p, t, c)
	local PlayerData = DataService:GetPlayerData(p)
	local ch_s = PlayerData[t .. "Challenge"].Challenges
	
	for i, v in ch_s do
		local matched_challenge = true

		if c.Get == v.Get and c.Amount == v.Amount and c.Difficulty == v.Difficulty then
			return matched_challenge
		end
	end

	return false
end

function ChallengeService:Generate(Player, _t)
	local PlayerData = DataService:GetPlayerData(Player)
	local PChallenge = PlayerData[_t .. "Challenge"]
	
	if not PChallenge then
		PlayerData[_t .. "Challenge"] = {
			LastUpdated = 0,
			Challenges = {}
		}
		
		PChallenge = PlayerData[_t .. "Challenge"]
	end
	
	local t = os.time()
	local r = self.TimeScales[_t]
	
	if t - PChallenge.LastUpdated < r then return end
	
	PlayerData[_t .. "Challenge"].LastUpdated = t
	
	local Challenges = self.Challenges[_t] or {}
	local fa = math.clamp(self.FillAmounts, 0, #Challenges)
	
	assert(fa > 0, _t .. " Challenges have less than (1) Challenges Cached, please add more under this category.")
	
	PlayerData[_t .. "Challenge"].Challenges = {}
	
	for i = 1, fa do
		local c
		
		repeat task.wait()
			c = Challenges[math.random(#Challenges)]
			c = {
				Name = c[1],
				Get = c[2],
				Amount = c[3],
				Difficulty = c[4],
				Exp = c[5],
				Progress = 0
			}
			
		until not self:HasChallenge(Player, _t, c)
		
		PlayerData[_t .. "Challenge"].Challenges[i] = c
	end
	
	DataService:SendUpdateSignal(Player, _t .. "Challenge")
end

function ChallengeService:Update(Player)
	self:Generate(Player, "Daily")
	self:Generate(Player, "Hourly")
end

ChallengeService.FilterChallenges = {
	onPetHatched = function(self, Challenges, PetData)
		local ChallengeIDs = {}
		
		for i, v in Challenges do
			if v.Name ~= "onPetHatched" then continue end
			if v.Get ~= PetData.Name then continue end
			if v.Progress >= v.Amount then continue end

			table.insert(ChallengeIDs, i)
		end
		
		return ChallengeIDs
	end,
	
	onCurrencyGained = function(self, Challenges, Currency)
		local ChallengeIDs = {}

		for i, v in Challenges do
			if v.Name ~= "onCurrencyGained" then continue end
			if v.Get ~= Currency then continue end
			if v.Progress >= v.Amount then continue end

			table.insert(ChallengeIDs, i)
		end

		return ChallengeIDs
	end,
}

function ChallengeService:Validate(Player, _t, ...)
	local PlayerData = DataService:GetPlayerData(Player)

	for Challenge in self.Challenges do
		local uChallenge = PlayerData[Challenge .. "Challenge"]

		if not uChallenge then continue end

		local ChallengeIDs = self.FilterChallenges[_t](self, uChallenge.Challenges, ...)

		if #ChallengeIDs == 0 then continue end

		for i, id in ChallengeIDs do
			local challenge = uChallenge.Challenges[id]
			
			local p = 1
			
			if _t == "onCurrencyGained" then
				p = ({...})[2]
			end

			challenge.Progress += p
			
			-- challenge id's will be filtered out if the progress is already more than the amount.
			if challenge.Progress >= challenge.Amount then
				PlayerLevelService:GrantExp(Player, challenge.Exp)
			end
		end

		DataService:SendUpdateSignal(Player, Challenge .. "Challenge")
	end
end

for i, v in ChallengeService.FilterChallenges do
	ChallengeService[i] = function(self, p, ...)
		return self:Validate(p, i, ...)
	end
end

return ChallengeService