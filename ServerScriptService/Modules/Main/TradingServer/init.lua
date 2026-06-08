local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local DataService = Services.get("DataService")

local TradeClass = require(script.ActiveTrade)

local TradeServer = {}
TradeServer.RequestQueues = {}
TradeServer.ActiveTrades = {}

TradeServer.ActiveDisableRequests = {}

TradeServer.RequestDecayTime = 15
TradeServer.EggsHatchedRequired = 0

function TradeServer:GetActiveTrade(from)
	for i, Trade in self.ActiveTrades do
		local Users = Trade.Users
		
		local u1 = Users.User1
		local u2 = Users.User2
		
		if u1.UserId == from.UserId or u2.UserId == from.UserId then
			return Trade
		end
	end
end

function TradeServer:GetTradeWhitelist(Player)
	local Whitelist = {}
	
	for i, v in Players:GetPlayers() do
		if v == Player and not RunService:IsStudio() then continue end
		if not self:PlayerCanTrade(v) then continue end

		local PlayerData = DataService:GetPlayerData(v)

		-- Disabled players are still shown in the list so the UI can render a "trades disabled" badge.
		
		-- sent_request being a ternary is purely for readability;
		-- has the same action as being true or nil
		local sent_request = self.RequestQueues[Player.UserId .. "-" .. v.UserId] and true or false
		local is_trading = self:GetActiveTrade(v) and true or false
		
		table.insert(Whitelist, {
			UserId = v.UserId,
			DisplayName = v.DisplayName,
			Name = v.Name,
			SentRequest = sent_request,
			IsTrading = is_trading,
			Disabled = PlayerData.TradeDisabled
		})
	end
	
	return Whitelist
end

function TradeServer:PlayerCanTrade(Player)
	local PlayerData = DataService:GetPlayerData(Player)
	
	return PlayerData["Eggs Hatched"] >= self.EggsHatchedRequired
end

function TradeServer:AcceptTradeRequest(Player, OriginalRequester)
	if typeof(OriginalRequester) ~= "number" then return end

	local O_R = Players:GetPlayerByUserId(OriginalRequester)

	-- Original requester left the server before this player could accept.
	-- Clear the stale request and bail without creating a half-built trade (which would error on nil:UserId).
	if not O_R then
		self.RequestQueues[OriginalRequester .. "-" .. Player.UserId] = nil
		Network:PostAll("UpdateTradeList")
		return
	end

	if self:GetActiveTrade(O_R) or self:GetActiveTrade(Player) then return end
	if not self.RequestQueues[OriginalRequester .. "-" .. Player.UserId] then return end
	
	self.RequestQueues[OriginalRequester .. "-" .. Player.UserId] = nil
	
	table.insert(
		self.ActiveTrades,
		TradeClass.new(O_R, Player)
	)
	
	local idx = #self.ActiveTrades
	
	self.ActiveTrades[idx]:onDestroy(function(state)
		local wasDeclined = state == "Declined"
		local wentThrough = state == "Confirmed"
		
		if wasDeclined then
			self.ActiveTrades[idx]:Post("DeclineTrade")
		elseif wentThrough then
			self.ActiveTrades[idx]:Post("ConfirmedTrade")
		else
			self.ActiveTrades[idx]:Post("CancelTrade")
		end
		
		self.ActiveTrades[idx] = nil
		
		Network:PostAll("UpdateTradeList")
	end)
	
	Network:PostAll("UpdateTradeList")
end

function TradeServer:SendTradeRequest(Requester, Player)
	if typeof(Player) ~= "Instance" or not Player:IsA("Player") then return end
	if Player == Requester then return end
	if self:GetActiveTrade(Requester) or self:GetActiveTrade(Player) then return end
	if not self:PlayerCanTrade(Requester) or not self:PlayerCanTrade(Player) then return end

	-- Enforce the target's "trades disabled" setting (the whitelist still shows them, but requests are blocked).
	local TargetData = DataService:GetPlayerData(Player)
	if TargetData and TargetData.TradeDisabled then return end

	if self.RequestQueues[Requester.UserId .. "-" .. Player.UserId] then return end
	
	self.RequestQueues[Requester.UserId .. "-" .. Player.UserId] = true
	
	Network:PostAll("UpdateTradeList")
	
	Network:Post(Player, "TradeRequestFrom", Requester.UserId, self.RequestDecayTime)
	
	task.delay(self.RequestDecayTime, function()
		self.RequestQueues[Requester.UserId .. "-" .. Player.UserId] = nil
		
		Network:PostAll("UpdateTradeList")
	end)
end

Network:Bind("SendTradeRequest", function(...)
	return TradeServer:SendTradeRequest(...)
end)

Network:Bind("AcceptTradeRequest", function(...)
	return TradeServer:AcceptTradeRequest(...)
end)

Network:Bind("GetTradeList", function(...)
	return TradeServer:GetTradeWhitelist(...)
end)

Network:Bind("CanTrade", function(...)
	return TradeServer:PlayerCanTrade(...)
end)

Network:Bind("DeclineTrade", function(Player)
	local ActiveTrade = TradeServer:GetActiveTrade(Player)
	
	if not ActiveTrade then return end
	
	ActiveTrade:Decline(Player)
end)

Network:Bind("AcceptTrade", function(Player)
	local ActiveTrade = TradeServer:GetActiveTrade(Player)

	if not ActiveTrade then return end

	ActiveTrade:Accept(Player)
end)

Network:Bind("AddItemToTrade", function(Player, PetId)
	local ActiveTrade = TradeServer:GetActiveTrade(Player)
	
	if not ActiveTrade then
		return
	end
	
	local id, User = ActiveTrade:GetLocalUser(Player)
	local oid, OtherUser = ActiveTrade:GetOtherUser(Player)
	
	local oPlayer = Players:GetPlayerByUserId(OtherUser.UserId)
	
	if not User or not OtherUser then
		return Player:Kick("We've decided that this trade is invalid, please contact support if this is not the case.")
	end
	
	local isPet = ActiveTrade:UserOwnsPet(Player, PetId)
	
	if not isPet then
		return -- warn("Player does not own p/e-id",PetId)
	end
	
	local Offers = User.Offers
	local HasOffer = table.find(Offers, PetId)
	
	if not HasOffer and #Offers >= 8 then return end
	
	if User.Confirmed.status then
		if User.Confirmed.status and OtherUser.Confirmed.status then return end
		
		ActiveTrade:StopConfirming(Player)
	else
		if User.Accepted.status then
			ActiveTrade:StopAccepting(Player)
		end
	end
	
	if OtherUser.Confirmed.status then
		if User.Confirmed.status and OtherUser.Confirmed.status then return end

		ActiveTrade:StopConfirming(oPlayer)
	else
		if OtherUser.Accepted.status then
			ActiveTrade:StopAccepting(oPlayer)
		end
	end
	
	if HasOffer then
		table.remove(Offers, HasOffer)

		return Network:Post(
			Players:GetPlayerByUserId(OtherUser.UserId),
			"ItemRemovedFromTrade",
			User.UserId,
			PetId
		)
	end
	
	-- on the client whenever we add/remove a pet to the trade, we should add/remove it from the Gui & List from the client to make it smoother.
	-- but on the other players side, we add from the server because how else would we do that??
	table.insert(Offers, PetId)
		
	Network:Post(
		Players:GetPlayerByUserId(OtherUser.UserId),
		"ItemAddedToTrade",
		User.UserId,
		PetId
	)
end)

Network:Bind("SendTradeMessage", function(Player, Message)
	local ActiveTrade = TradeServer:GetActiveTrade(Player)
	
	if not ActiveTrade then return end
	
	local id, u = ActiveTrade:GetLocalUser(Player)
	local oid, ou = ActiveTrade:GetOtherUser(Player)
	
	if not id or not oid then return end
	
	local FilteredMessage = TextService:FilterStringAsync(Message, u.UserId, Enum.TextFilterContext.PublicChat)
	local Filtered = FilteredMessage:GetNonChatStringForUserAsync(ou.UserId)
	
	return ActiveTrade:Post(
		"SendTradeMessage",
		u.UserId,
		Filtered
	)
end)

Network:Bind("DisableTrade", function(Player)
	local UserId = Player.UserId
	
	if table.find(TradeServer.ActiveDisableRequests, UserId) then return end
	
	table.insert(TradeServer.ActiveDisableRequests, UserId)
	
	local PlayerData = DataService:GetPlayerData(Player)
	PlayerData.TradeDisabled = not PlayerData.TradeDisabled
	
	DataService:SendUpdateSignal(Player, "TradeDisabled")
	
	Network:PostAll("UpdateTradeList")
	
	task.delay(.1, function()
		table.remove(TradeServer.ActiveDisableRequests, table.find(TradeServer.ActiveDisableRequests, UserId))
	end)
end)

Players.PlayerRemoving:Connect(function(Player)
	local Trade = TradeServer:GetActiveTrade(Player)
	local CanTrade = TradeServer:PlayerCanTrade(Player)

	-- Clean up any pending request queues that reference this player to prevent stale-key buildup
	local Prefix = tostring(Player.UserId) .. "-"
	local Suffix = "-" .. tostring(Player.UserId)
	for Key in pairs(TradeServer.RequestQueues) do
		if string.sub(Key, 1, #Prefix) == Prefix or string.sub(Key, -#Suffix) == Suffix then
			TradeServer.RequestQueues[Key] = nil
		end
	end

	if CanTrade and not Trade then
		Network:PostAll("UpdateTradeList")
	end

	if Trade then
		Trade:Decline(Player)
	end
end)

return TradeServer