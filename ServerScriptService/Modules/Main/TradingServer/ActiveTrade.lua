local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local PetUtil = Services.get("PetUtil")

local function NewTrader(User)
	local PlayerData = DataService:GetPlayerData(User)
	
	return {
		UserId = User.UserId,
		Inventory = PlayerData.Pets,
		Eggs = PlayerData.Eggs,
		Offers = {},
		Accepted = {status = false, t = 0},
		Confirmed = {status = false, t = 0}
	}
end

local ActiveTrade = {}
ActiveTrade.__index = ActiveTrade

function ActiveTrade:Destroy(state)
	for i, v in self.DestroyCallbacks do
		v(state)
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

function ActiveTrade:onDestroy(Callback)
	table.insert(self.DestroyCallbacks, Callback)
end

function ActiveTrade:GetLocalUser(User)
	for i, v in self.Users do
		if v.UserId == (User and User.UserId) then
			return tostring(i), v
		end
	end
	
	return "User1", self.Users.User1
end

function ActiveTrade:GetOtherUser(User)
	if not User then
		return self:GetLocalUser(User)
	end
	
	for i, v in self.Users do
		if v.UserId ~= (User and User.UserId) then
			return tostring(i), v
		end
	end
	
	return self:GetLocalUser(User)
end

function ActiveTrade:UserOwnsPet(User, pid)
	local id, u = self:GetLocalUser(User)
	
	if not id then return end
	
	for i, v in u.Inventory do
		if v.ID == pid then
			return v
		end
	end
end

function ActiveTrade:UserOwnsEgg(User, eid)
	local id, u = self:GetLocalUser(User)

	if not id then return end

	for i, v in u.Eggs do
		if v.ID == eid then
			return v
		end
	end
end

function ActiveTrade:Accept(User)
	local id, u = self:GetLocalUser(User)
	local oid, ou = self:GetOtherUser(User)
	
	if not id or not oid then return end
	if u.Accepted.status and ou.Accepted.status then return self:Confirm(User) end
	if u.Accepted.status then return self:Confirm(User) end
	if u.Confirmed.status then return end
	
	local st = workspace:GetServerTimeNow()
	
	if ou.Accepted.status and (st - ou.Accepted.t) < 3 then
		--return
	end
	
	u.Accepted.status = true
	u.Accepted.t = workspace:GetServerTimeNow()
	
	self:Post("UserAcceptedOffer", u.UserId)
end

function ActiveTrade:Confirm(User)
	local id, u = self:GetLocalUser(User)
	local oid, ou = self:GetOtherUser(User)
	
	if not id or not oid then return end
	if not u.Accepted.status then return end
	if not ou.Accepted.status and not ou.Confirmed.status then return end
	
	if u.Confirmed.status then return end
	
	local st = workspace:GetServerTimeNow()
	
	if st - u.Accepted.t < 3 then return end
	if st - ou.Accepted.t < 3 then return end
	
	if ou.Confirmed.status and (st - ou.Confirmed.t) < 5 then
		--return warn("ou-C&st-ou-t<5")
	end
	
	u.Accepted.status = false
	
	u.Confirmed.status = true
	u.Confirmed.t = st
	
	self:Post("UserConfirmedOffer", u.UserId)
	
	task.delay(5, function()
		if not self.Complete then return end
		
		self:Complete(User)
	end)
end

function ActiveTrade:StopAccepting(User)
	local id, u = self:GetLocalUser(User)
	
	if not id then return end
	if not u.Accepted.status then return end
	
	u.Accepted.status = false
	u.Accepted.t = 0
	
	self:Post("UserStoppedAccept", u.UserId)
end

function ActiveTrade:StopConfirming(User)
	local id, u = self:GetLocalUser(User)
	local oid, ou = self:GetOtherUser(User)

	if not id then return end
	if not u.Confirmed.status then return end
	if u.Confirmed.status and ou.Confirmed.status then return end
	
	u.Accepted.status = false
	u.Accepted.t = 0
	
	u.Confirmed.status = false
	u.Confirmed.t = 0

	self:Post("UserStoppedConfirm", u.UserId)
end

function ActiveTrade:Complete(User)
	local id, u = self:GetLocalUser(User)
	local oid, ou = self:GetOtherUser(User)
	
	if not u.Confirmed.status or not ou.Confirmed.status then return end
	
	local st = workspace:GetServerTimeNow()
	
	if st - u.Confirmed.t < 5 then return end
	if st - ou.Confirmed.t < 5 then return end
	
	local pu = Players:GetPlayerByUserId(u.UserId)
	local pou = Players:GetPlayerByUserId(ou.UserId)
	
	local U_Data = DataService:GetPlayerData(pu)
	local OU_Data = DataService:GetPlayerData(pou)
	
	if #U_Data.TradeHistory >= 15 then
		table.remove(U_Data.TradeHistory, 1)
	end
	
	if #OU_Data.TradeHistory >= 15 then
		table.remove(OU_Data.TradeHistory, 1)
	end
	
	table.insert(U_Data.TradeHistory, {
		User1 = pu.Name,
		User2 = pou.Name,
		
		Date = os.date("%b %d, %Y"),
		
		Offer1 = u.Offers,
		Offer2 = ou.Offers
	})
	
	table.insert(OU_Data.TradeHistory, {
		User1 = pou.Name,
		User2 = pu.Name,
		
		Date = os.date("%b %d, %Y"),

		Offer1 = ou.Offers,
		Offer2 = u.Offers
	})
	
	DataService:SendUpdateSignal(pu, "TradeHistory")
	DataService:SendUpdateSignal(pou, "TradeHistory")
	
	warn(u.Offers, ou.Offers)
	
	for i, pid in u.Offers do
		local Pet = PetUtil.GetPet(pu, pid)
		
		if not Pet then continue end
		
		DataService:GivePet(pou, DataService.Utility.ShallowCopy(Pet))
		
		PetUtil.DeletePets(pu, {pid})
	end
	
	for i, pid in ou.Offers do
		local Pet = PetUtil.GetPet(pou, pid)

		if not Pet then continue end

		DataService:GivePet(pu, DataService.Utility.ShallowCopy(Pet))
		
		PetUtil.DeletePets(pou, {pid})
	end
	
	self:Destroy("Confirmed")
end

function ActiveTrade:Decline(User)
	local id, u = self:GetLocalUser(User)
	local oid, ou = self:GetOtherUser(User)
	
	if u.Confirmed.status and ou.Confirmed.status then return end
	
	self:Destroy("Declined")
end

function ActiveTrade:Post(...)
	for i, v in self.Users do
		local Player = Players:GetPlayerByUserId(v.UserId)
		
		if not Player then continue end
		
		Network:Post(Player, ...)
	end
end

function ActiveTrade.new(User1, User2)
	local self = setmetatable({
		Users = {
			User1 = NewTrader(User1),
			User2 = NewTrader(User2)
		},
		
		DestroyCallbacks = {}
	}, ActiveTrade)
	
	self:Post("CreatedNewTrade", self.Users)
	
	return self
end

return ActiveTrade