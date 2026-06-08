local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RS_Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(RS_Modules:WaitForChild("Services"))

local DataService = Services.get("DataService")
local GiftsModule = Services.get("GiftsModule")
local States = Services.get("States")
local RNGService = Services.get("RNGService")
local Network = Services.get("Network")

local module = {}

function module:PickRandomReward(Rewards)
	local TotalWeight = 0

	for _, Reward in Rewards do
		TotalWeight += Reward.Chance or 100
	end

	local RandomWeight = math.random() * TotalWeight
	local CurrentWeight = 0

	for _, Reward in Rewards do
		CurrentWeight += Reward.Chance or 100

		if CurrentWeight < RandomWeight then
			continue
		end

		return Reward
	end
end

function module:ClaimGift(Player, GiftIndex)
	if typeof(GiftIndex) ~= "number" then return end

	local StartTime = States.has(Player, "LogTime")

	if not StartTime then return end

	local PlayerData = DataService:GetPlayerData(Player)

	if not PlayerData then return end

	local Gifts = PlayerData.Gifts
	local Needle = "Gift" .. GiftIndex

	if Gifts[Needle] then return end

	local Gift = GiftsModule[GiftIndex]

	if not Gift then return end

	local Elapsed = os.time() - StartTime
	local TimeRemaining = (Gift.TimeRequired or 0) - Elapsed

	if TimeRemaining > 0 then
		Network:Post(Player, "DisplayNewItem", {
			Type = "Message",
			Message = "You cannot claim this gift yet!"
		})

		return
	end

	local Reward = self:PickRandomReward(Gift.Rewards or {})

	if RNGService:Wager(500 / GiftIndex) then
		-- Lucky drop: King Doggy. Use canonical field names.
		DataService:GivePet(Player, {
			Name = "King Doggy",
			Tier = "Normal",
			Hatched = true,
			Chance = 500 / GiftIndex,
			Egg = "Gift Box",
			CantAutoDelete = true,
		}, true)
	elseif Reward then
		if Reward.Type == "Pet" then
			for _ = 1, (Reward.Amount or 1) do
				DataService:GivePet(Player, {
					Name = Reward.Name,
					Tier = Reward.Tier,
					Hatched = true,
					Egg = "Gift Box",
				}, true)
			end
		elseif Reward.Type == "Currency" then
			DataService:GiveCurrency(Player, Reward.Name, Reward.Amount, true)
		end
	end

	PlayerData.Gifts[Needle] = true
	DataService:SendUpdateSignal(Player, "Gifts")
end

Network:Bind("ClaimGift", function(...)
	return module:ClaimGift(...)
end)

return module
