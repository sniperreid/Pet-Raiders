local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Services = require(Modules.Services)

local Network = Services.get("Network")
local GuiService = Services.get("GuiService")
local AnimationService = Services.get("AnimationService")
local Roblox = Services.get("Roblox")
local EzRender = Services.get("RenderUtil").Number
local LoadAnimation = Services.get("LocalLoadingContext")
local PetModule = Services.get("PetModule")
local PetBuffService = Services.get("PetBuffService")
local RarityModule = Services.get("RarityModule")
local TiersModule = Services.get("TiersModule")

local Frames = GuiService.Frames
local StatsFrame = Frames.StatsFrame
local TradingFrame = Frames.TradingFrame
local TradingContext = Frames.TradingContext

local TradeTab = TradingFrame.Content.Tabs.Trades

local TradeListContainer = TradeTab.Container.Grid
local ActiveFrame = TradingContext.ActiveTrade

local RequestTemplate = script.RequestTemplate
local TraderTemplate = script.TraderTemplate

local CurrentTradeConnections = {}
local CurrentTradeChatHistory = {}
local CurrentTradeChatNotifs = 0

local TradingClient = {}
TradingClient.TradeData = nil
TradingClient.ActiveAvatars = {}

function TradingClient:GetAvatar(UserId)
	if self.ActiveAvatars[UserId] then
		return self.ActiveAvatars[UserId]
	end
	
	local Icon = Players:GetUserThumbnailAsync(UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	
	self.ActiveAvatars[UserId] = Icon
	
	return self.ActiveAvatars[UserId]
end

function TradingClient:GetLocalUser(Player)
	local Player = Player or Players.LocalPlayer
	local Trade = self.TradeData
	
	if typeof(Player) == "number" then
		Player = {UserId = Player}
	end
	
	if not Trade then return end
	
	for i, v in Trade do
		if v.UserId == Player.UserId then
			return i, v
		end
	end
end

function TradingClient:GetOtherUser(Player)
	local Player = Player or Players.LocalPlayer
	local Trade = self.TradeData

	if typeof(Player) == "number" then
		Player = {UserId = Player}
	end
	
	if not Trade then return end

	for i, v in Trade do
		if v.UserId ~= Player.UserId then
			return i, v
		end
	end
	
	return self:GetLocalUser(Player)
end

function TradingClient:GetTradeList()
	if not TradingFrame.Visible then return self.TradeList end
	
	local ValidPlayers = Players.NumPlayers >= 1
	
	self.TradeList = ValidPlayers and Network:Invoke("GetTradeList") or {}
	
	return self.TradeList
end

function TradingClient:UpdateTradeList()
	if not TradingFrame.Visible then
		-- blank 2nd arg returns "Frame"
		return Roblox:ClearChildrenOfClass(TradeListContainer)
	end
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local CanTrade = PlayerData["Eggs Hatched"] >= 0
	
	TradeListContainer.Parent.RequirementLabel.Visible = not CanTrade
	TradeListContainer.Parent.Blackout.Visible = not CanTrade
	
	if not CanTrade then
		return Roblox:ClearChildrenOfClass(TradeListContainer)
	end
	
	local TradeList = self:GetTradeList()
	local PlayersActive = TradeListContainer:GetChildren()
	
	for i = #PlayersActive, 1, -1 do
		local v = PlayersActive[i]
		
		if not v then continue end -- should never happen.
		if not v:IsA("Frame") then continue end
		
		local isValid = false
		
		for i, p in TradeList do
			if p.UserId ~= v.Name then continue end
			
			isValid = true
			
			break
		end
		
		if isValid then break end
		
		v:Destroy()
	end
	
	for i, Player in TradeList do
		task.spawn(function()
			local HasTrade = TradeListContainer:FindFirstChild(Player.UserId)
			
			local TraderFrame = HasTrade or TraderTemplate:Clone()
			TraderFrame.Parent = TradeListContainer
			TraderFrame.ZIndex = i
			TraderFrame.Name = Player.UserId

			local SendButton = TraderFrame.Send
			local AvatarIcon = TraderFrame.Avatar
			local TraderUser = TraderFrame.Username

			local TradeColor, TradeState

			if Player.SentRequest then
				TradeColor = Color3.fromRGB(131, 49, 245)
				TradeState = "Sent"
			elseif Player.IsTrading then
				TradeColor = Color3.fromRGB(255, 188, 55)
				TradeState = "Trading"
			elseif Player.Disabled then
				TradeColor = Color3.fromRGB(253, 89, 89)
				TradeState = "Disabled"
			else
				TradeColor = Color3.fromRGB(125, 245, 34)
				TradeState = "Send"
			end

			SendButton.Content.BackgroundColor3 = TradeColor
			SendButton.Content.Amount.Text = TradeState

			TraderUser.Display.Text = Player.DisplayName
			TraderUser.User.Text = ("@%s"):format(Player.Name)
			
			if HasTrade then return end

			AnimationService:CreateButton(SendButton, function()
				if TradeState ~= "Send" then return end

				local PlayerInstance = Players:GetPlayerByUserId(Player.UserId)

				if not PlayerInstance then
					return self:UpdateTradeList()
				end

				Network:Post("SendTradeRequest", PlayerInstance)
			end)

			AvatarIcon.Icon.Image = self:GetAvatar(Player.UserId)
		end)
	end
end

function TradingClient:AddItemToTrade(PetId)
	local id, u = self:GetLocalUser()
	local oid, ou = self:GetOtherUser()
	
	if not id or not oid then return end
	if ActiveFrame.Content.ChatFrame.Visible then return end
	
	for i, v in u.Inventory do
		if v.ID == PetId then
			Network:Post("AddItemToTrade", v.ID)
			
			local was_in_offer = table.find(u.Offers, v.ID)
			local state = was_in_offer and "RemovedFrom" or "AddedTo"
			
			Network:Fetch("Item" .. state .. "Trade", u.UserId, v.ID)
			
			return
		end
	end
end

Players.PlayerAdded:Connect(function()
	TradingClient:UpdateTradeList()
end)

Players.PlayerRemoving:Connect(function(Player)
	if TradingClient.ActiveAvatars[Player.UserId] then
		TradingClient.ActiveAvatars[Player.UserId] = nil
	end
end)

TradingFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	TradingClient:UpdateTradeList()
end)

Network:Bind("UpdateTradeList", function()
	TradingClient:UpdateTradeList()
end)

Network:Bind("ItemAddedToTrade", function(uId, PetId)
	local id, u = TradingClient:GetLocalUser({UserId = uId})
	
	if not id then return end
	if table.find(u.Offers, PetId) then return end
	if #u.Offers >= 8 then return end
	
	table.insert(u.Offers, PetId)
	
	TradingClient:LoadUserOffer(uId == Players.LocalPlayer.UserId)
	TradingClient:LoadUserPets(uId == Players.LocalPlayer.UserId, 1)
end)

Network:Bind("ItemRemovedFromTrade", function(uId, PetId)
	local id, u = TradingClient:GetLocalUser({UserId = uId})

	if not id then return end
	if not table.find(u.Offers, PetId) then return end

	table.remove(u.Offers, table.find(u.Offers, PetId))
	
	TradingClient:LoadUserOffer(uId == Players.LocalPlayer.UserId)
	TradingClient:LoadUserPets(uId == Players.LocalPlayer.UserId, 1)
end)

Network:Bind("TradeRequestFrom", function(UserId)
	local Requester = Players:GetPlayerByUserId(UserId)
	
	if not Requester then return end
	
	-- Create Gui and place inside of "RequestsContainer"
	-- Have a ProgressBar at the bottom showing the time remaining before it expires
	-- (15 seconds)
	local NewTemp = RequestTemplate:Clone()
	NewTemp.Parent = TradingContext.RequestsContainer
	
	local Content = NewTemp.Content
	
	Content.Position = UDim2.fromScale(2, .5)
	
	TweenService:Create(
		Content,
		TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{
			Position = UDim2.fromScale(.5, .5)
		}
	):Play()
	
	local ClearRequest = TweenService:Create(
		NewTemp,
		TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			GroupTransparency = 1
		}
	)
	
	Content.Username.Text = ("%s sent you a Trade Request"):format(Requester.DisplayName)
	Content.Avatar.Icon.Image = TradingClient:GetAvatar(UserId)
	
	Content.Progress.Bar.Size = UDim2.fromScale(0, 1)
	
	local WasDeclined = false
	
	local DeclineTween = TweenService:Create(
		Content.Progress.Bar,
		TweenInfo.new(15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromScale(1, 1)
		}
	)
	
	AnimationService:CreateButton(Content.Buttons.Accept, function()
		if WasDeclined then return end
		
		Network:Post("AcceptTradeRequest", UserId)
	end)
	
	AnimationService:CreateButton(Content.Buttons.Decline, function()
		if WasDeclined then return end

		DeclineTween:Cancel()
	end)
	
	DeclineTween:Play()
	
	DeclineTween.Completed:Once(function()
		if WasDeclined or not NewTemp.Parent then return end
		
		WasDeclined = true
		
		ClearRequest:Play()
		
		ClearRequest.Completed:Once(function()
			ClearRequest:Destroy()
			
			NewTemp:Destroy()
		end)
		
		DeclineTween:Destroy()
	end)
end)

Network:Bind("DeclineTrade", function()
	if not TradingClient.TradeData then return end
	
	Network:Fetch("CancelTrade")
	
	TradingContext.Message.Visible = true
	TradingContext.Message.Username.Text = "The trade was declined!"
	TradingContext.Message.Icon.Image = "rbxassetid://82853070590684"
	
	task.delay(2, function()
		TradingContext.Message.Visible = false
	end)
end)

Network:Bind("ConfirmedTrade", function()
	if not TradingClient.TradeData then return end

	Network:Fetch("CancelTrade")
	
	TradingContext.Message.Visible = true
	TradingContext.Message.Username.Text = "The trade was a success!"
	TradingContext.Message.Icon.Image = "rbxassetid://138182689282474"
	
	task.delay(2, function()
		TradingContext.Message.Visible = false
	end)
end)

local TradeTweens = {

}

Network:Bind("CancelTrade", function()
	if not TradingClient.TradeData then return end

	for i, v in CurrentTradeConnections do
		v:Disconnect()
	end
	
	table.clear(CurrentTradeConnections)

	TradingClient.TradeData = nil
	
	StatsFrame.Visible = true
	
	ActiveFrame.Visible = false
	TradingContext.RequestsContainer.Visible = true
	
	for i, v in TradeTweens do
		v:Disconnect()
	end
	
	table.clear(TradeTweens)
end)

Network:Bind("UserAcceptedOffer", function(UserId)
	if TradeTweens[UserId .. "Accept"] then
		TradeTweens[UserId .. "Accept"]:Disconnect()
		TradeTweens[UserId .. "Accept"] = nil
	end
	
	local id, User = TradingClient:GetLocalUser(UserId)
	local Side = UserId == Players.LocalPlayer.UserId and "Left" or "Right"
	
	ActiveFrame.Content[Side].TradeState.Text = "ACCEPTED"
	ActiveFrame.Content[Side].TradeState.TextColor3 = Color3.new(0, 1, 0)
	
	ActiveFrame.Content[Side].TradeState.Visible = true
	ActiveFrame.Content[Side].Cooldown.Visible = true
	
	ActiveFrame.Content[Side].Blackout.Visible = true
	
	-- 3 -> 0 in 3s
	TradeTweens[UserId .. "Accept"] = EzRender.new({
		Min = 3,
		Max = 0,
		UpdateSpeed = 3
	}, function(x)
		local n = math.floor(x * 10) / 10
		
		ActiveFrame.Content[Side].Cooldown.Text = n
		ActiveFrame.Content[Side].Cooldown.TextColor3 = Color3.new(0, 1, 0):Lerp(
			Color3.new(1, 0, 0),
			(3 - x) / 3
		)
		
		if (n <= 0) and TradeTweens[UserId .. "Accept"] then
			TradeTweens[UserId .. "Accept"]:Disconnect()
			TradeTweens[UserId .. "Accept"] = nil
			
			ActiveFrame.Content[Side].Cooldown.Visible = false
			ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text = UserId == Players.LocalPlayer.UserId and "Confirm" or ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text
		end
	end)
end)

Network:Bind("UserConfirmedOffer", function(UserId)
	if TradeTweens[UserId .. "Confirm"] then
		TradeTweens[UserId .. "Confirm"]:Disconnect()
		TradeTweens[UserId .. "Confirm"] = nil
	end

	local id, User = TradingClient:GetLocalUser(UserId)
	local Side = UserId == Players.LocalPlayer.UserId and "Left" or "Right"
	
	ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text = UserId == Players.LocalPlayer.UserId and "Confirming" or ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text

	ActiveFrame.Content[Side].TradeState.Text = "CONFIRMED"
	ActiveFrame.Content[Side].TradeState.TextColor3 = Color3.new(0, 1, 0)
	
	ActiveFrame.Content[Side].TradeState.Visible = true
	ActiveFrame.Content[Side].Cooldown.Visible = true

	ActiveFrame.Content[Side].Blackout.Visible = true

	-- 5 -> 0 in 5s
	TradeTweens[UserId .. "Confirm"] = EzRender.new({
		Min = 5,
		Max = 0,
		UpdateSpeed = 5
	}, function(x)
		local n = math.floor(x * 10) / 10

		ActiveFrame.Content[Side].Cooldown.Text = n
		ActiveFrame.Content[Side].Cooldown.TextColor3 = Color3.new(0, 1, 0):Lerp(
			Color3.new(1, 0, 0),
			(5 - x) / 5
		)
		
		if (n <= 0) and TradeTweens[UserId .. "Confirm"] then
			TradeTweens[UserId .. "Confirm"]:Disconnect()
			TradeTweens[UserId .. "Confirm"] = nil
			
			ActiveFrame.Content[Side].Cooldown.Visible = false
		end
	end)
end)

Network:Bind("UserStoppedAccept", function(UserId)
	if TradeTweens[UserId .. "Accept"] then
		TradeTweens[UserId .. "Accept"]:Disconnect()
		TradeTweens[UserId .. "Accept"] = nil
	end
	
	local id, User = TradingClient:GetLocalUser(UserId)
	local Side = UserId == Players.LocalPlayer.UserId and "Left" or "Right"
	
	ActiveFrame.Content[Side].TradeState.Visible = false
	ActiveFrame.Content[Side].Cooldown.Visible = false

	ActiveFrame.Content[Side].Blackout.Visible = false
	
	ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text = "Accept"
end)

Network:Bind("UserStoppedConfirm", function(UserId)
	if TradeTweens[UserId .. "Confirm"] then
		TradeTweens[UserId .. "Confirm"]:Disconnect()
		TradeTweens[UserId .. "Confirm"] = nil
	end

	local id, User = TradingClient:GetLocalUser(UserId)
	local Side = UserId == Players.LocalPlayer.UserId and "Left" or "Right"

	ActiveFrame.Content[Side].TradeState.Visible = false
	ActiveFrame.Content[Side].Cooldown.Visible = false

	ActiveFrame.Content[Side].Blackout.Visible = false
	
	ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text = "Accept"
end)

function TradingClient:GetUserInventory(UserId)
	local id, u = self:GetLocalUser(UserId)
	local Inventory = u.Inventory
	
	table.sort(u.Inventory, function(a, b)
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
		
		local aidx = table.find(u.Offers, aID) or 0
		local bidx = table.find(u.Offers, bID) or 0
		
		if aidx ~= bidx then
			return aidx > bidx
		end
		
		--local aWState = table.find(Whitelist, aID) and 1 or 0
		--local bWState = table.find(Whitelist, bID) and 1 or 0

		--if aWState ~= bWState then
		--	return aWState > bWState
		--end

		--if aEState ~= bEState then
		--	return aEState > bEState
		--end

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

		local Stat1 = aBuff["Speed"] or 0
		local Stat2 = bBuff["Speed"] or 0

		if Stat1 ~= Stat2 then
			return Stat1 > Stat2
		end

		return aName:len() > bName:len()
	end)
	
	return u.Inventory
end

function TradingClient:SendMessage(Sender, Message)
	if not self.TradeData then return end
	
	table.insert(CurrentTradeChatHistory, {
		Sender = Sender,
		Message = Message
	})
	
	if not ActiveFrame.Content.ChatFrame.Visible then
		CurrentTradeChatNotifs += 1
		
		local over9 = CurrentTradeChatNotifs > 9
		local t = over9 and "9+" or CurrentTradeChatNotifs

		ActiveFrame.Content.Center.Buttons.Chat.Content.Notification.TextLabel.Text = t
		ActiveFrame.Content.Center.Buttons.Chat.Content.Notification.Visible = true
	end
	
	local ChatTemplate = script.ChatTemplate:Clone()
	ChatTemplate.Name = "Chat-" .. #CurrentTradeChatHistory
	
	local Side = Sender ~= Players.LocalPlayer.UserId and "Left" or "Right"
	local oSide = Side == "Left" and "Right" or "Left"
	
	ChatTemplate[oSide].Visible = false
	ChatTemplate[Side].Visible = true
	
	local x = math.clamp(
		0.879 * (Message:len() / 25),
		0.28,
		0.879
	)
	
	ChatTemplate[Side].UserMessage.Size = UDim2.fromScale(
		x,
		.95
	)
	
	ChatTemplate[Side].UserMessage.Content.Message.Text = Message
	
	if Side == "Left" then
		ChatTemplate[Side].Avatar.Icon.Image = self:GetAvatar(Sender)
	end
	
	ChatTemplate.Parent = ActiveFrame.Content.ChatFrame.Container
end

function TradingClient:LoadUserOffer(Local)
	local id, u = self:GetLocalUser()
	local oid, ou = self:GetOtherUser()

	if not Local then
		id = oid;
		u = ou;
	end
	
	local Side = u.UserId == Players.LocalPlayer.UserId and "Your" or "Their"
	local Frame = ActiveFrame.Content.Center[Side .. "Offer"]
	
	Roblox:ClearChildrenOfClass(Frame.Grid, "ImageButton")
	
	local Offers = u.Offers or {}
	
	for i = 1, 8 do
		local PetId = Offers[i]
		local Pet
		
		for i, v in u.Inventory do
			if v.ID == PetId then
				Pet = v
				
				break
			end
		end
		
		if not Pet then
			Pet = {
				ID = "Blank-" .. i,
				Name = "Doggy",
				Tier = "Normal",
				Exp = 0,
				Level = 1,
				Equipped = false,
				Locked = false,
				Enchant = nil
			}
		end
		
		local Temp = GuiService.GuiUtil:CreatePet(Pet, Frame.Grid)
		Temp.LayoutOrder = i

		Temp.Content.Equipped.Visible = false
		Temp.Content.LockSelected.Visible = false
		Temp.Content.Locked.Visible = false
		Temp.Content.Selected.Visible = false
		
		if not PetId then
			
			Temp.Content.PetIcon.Image = ""
			Temp.Content.Info.Level.Text = ""
			
			continue
		end
		
		if not Local then
			continue
		end
		
		-- under context "AddItem"
		-- should regulate to "RemoveItem" see TradingClient:AddItemToTrade()
		AnimationService:CreateButton(Temp, function()
			self:AddItemToTrade(Pet.ID)
		end)
	end
end

function TradingClient:LoadUserPets(Local, Start, End)
	local id, u = self:GetLocalUser()
	local oid, ou = self:GetOtherUser()
	
	if not Local then
		id = oid;
		u = ou;
	end
	
	local Inventory = self:GetUserInventory(u.UserId)
	
	local Side = u.UserId == Players.LocalPlayer.UserId and "Left" or "Right"
	local End = End or #Inventory
	
	local Grid = ActiveFrame.Content[Side].Grid
	
	local nonyield = u.loaded_pets
	
	u.loaded_pets = true
	
	local st = tick()
	
	for i = Start, End do
		if i % 15 == 0 and not nonyield then -- i % (End / 40) == 0 and 
			task.wait()
		end
		
		local Pet = Inventory[i]

		if not Pet then break end
		
		if u.Search and not (Pet.Name:match(u.Search) or PetModule[Pet.Name].Rarity:match(u.Search)) then
			continue
		end
		
		local Temp = GuiService.GuiUtil:CreatePet(Pet, Grid)
		Temp.LayoutOrder = i
		
		Temp.Content.Equipped.Visible = false
		Temp.Content.LockSelected.Visible = false
		Temp.Content.Locked.Visible = false
		Temp.Content.Selected.Visible = false
		
		Temp.Content.UIStroke.Color = table.find(u.Offers or {}, Pet.ID) and Color3.fromRGB(79, 236, 76) or Color3.fromRGB(7, 43, 86)
		
		if not Local then
			continue
		end
		
		AnimationService:CreateButton(Temp, function()
			self:AddItemToTrade(Pet.ID)
		end)
	end
end

Network:Bind("CreatedNewTrade", function(TradeData)
	if TradingClient.TradeData then return end
	
	TradingClient.TradeData = TradeData

	AnimationService:CreateButton(ActiveFrame.Content.Center.Buttons.Cancel, function()
		Network:Post("DeclineTrade")
	end)
	
	AnimationService:CreateButton(ActiveFrame.Content.Center.Buttons.Accept, function()
		Network:Post("AcceptTrade")
	end)
	
	AnimationService:CreateButton(ActiveFrame.Content.Center.Buttons.Chat, function()
		ActiveFrame.Content.ChatFrame.Visible = true
	end)
	
	table.insert(
		CurrentTradeConnections,
		ActiveFrame.Content.Left.Box.TextBox.FocusLost:Connect(function()
			local id, u = TradingClient:GetLocalUser()
			
			if u.Search == ActiveFrame.Content.Left.Box.TextBox.Text then return end
			
			u.Search = ActiveFrame.Content.Left.Box.TextBox.Text
			
			if u.Search == "" then
				u.Search = nil
			end
			
			Roblox:ClearChildrenOfClass(ActiveFrame.Content.Left.Grid, "ImageButton")
			
			TradingClient:LoadUserPets(true, 1)
		end)
	)
	
	table.insert(
		CurrentTradeConnections,
		ActiveFrame.Content.Right.Box.TextBox.FocusLost:Connect(function()
			local id, u = TradingClient:GetOtherUser()
			
			if u.Search == ActiveFrame.Content.Right.Box.TextBox.Text then return end
			
			u.Search = ActiveFrame.Content.Right.Box.TextBox.Text
			
			if u.Search == "" then
				u.Search = nil
			end
			
			Roblox:ClearChildrenOfClass(ActiveFrame.Content.Right.Grid, "ImageButton")

			TradingClient:LoadUserPets(false, 1)
		end)
	)
	
	local CurrentMessageInput = ""
	
	Roblox:ClearChildrenOfClass(ActiveFrame.Content.ChatFrame.Container, "Frame")
	ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text = CurrentMessageInput
	
	table.clear(CurrentTradeChatHistory)
	CurrentTradeChatNotifs = 0
	
	table.insert(
		CurrentTradeConnections,
		ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input:GetPropertyChangedSignal("Text"):Connect(function()
			if ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text == CurrentMessageInput then return end
			
			local len = ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text:len()
			local max = 45
			
			if len > max then
				ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text = CurrentMessageInput
			else
				CurrentMessageInput = ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text
			end
			
			ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Length.Text = ("%d/%d"):format(len, max)
		end)
	)
	
	table.insert(
		CurrentTradeConnections,
		ActiveFrame.Content.ChatFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if ActiveFrame.Content.ChatFrame.Visible then
				CurrentTradeChatNotifs = 0
				
				ActiveFrame.Content.Center.Buttons.Chat.Content.Notification.Visible = false
			end
		end)
	)
	
	table.insert(
		CurrentTradeConnections,
		ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.FocusLost:Connect(function(enterPressed)
			if not enterPressed then return end
			if ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text == "" then
				return
			end

			Network:Post(
				"SendTradeMessage",
				ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text
			)

			ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text = ""
		end)
	)
	
	AnimationService:CreateButton(ActiveFrame.Content.ChatFrame.Inputs.Send, function()
		if ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text == "" then
			return
		end
		
		Network:Post(
			"SendTradeMessage",
			ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text
		)
		
		ActiveFrame.Content.ChatFrame.Inputs.MessageInput.Content.Input.Text = ""
	end)
	
	AnimationService:CreateButton(ActiveFrame.Content.ChatFrame.Close, function()
		ActiveFrame.Content.ChatFrame.Visible = false
	end)
	
	Roblox:ClearChildrenOfClass(ActiveFrame.Content.Left.Grid, "ImageButton")
	Roblox:ClearChildrenOfClass(ActiveFrame.Content.Right.Grid, "ImageButton")
	
	Roblox:ClearChildrenOfClass(ActiveFrame.Content.Center.YourOffer.Grid, "ImageButton")
	Roblox:ClearChildrenOfClass(ActiveFrame.Content.Center.TheirOffer.Grid, "ImageButton")
	
	-- load Inventory & Pet Frames prior to frame being turned visible
	
	StatsFrame.Visible = false
	
	GuiService:CloseFrame()
	
	LoadAnimation:Start("Loading your trade menu...")
	
	local Start = tick()
	
	TradingClient:LoadUserOffer(true)
	TradingClient:LoadUserOffer(false)
	
	TradingClient:LoadUserPets(true, 1)
	TradingClient:LoadUserPets(false, 1)
	
	-- basically if the trade loaded way too fast just wait for the animation to stop playing.
	repeat task.wait()
	until (tick() - Start) > LoadAnimation.AverageLoadTime
	
	LoadAnimation:Stop()
	
	ActiveFrame.Content.Left.TradeState.Visible = false
	ActiveFrame.Content.Left.Cooldown.Visible = false
	ActiveFrame.Content.Left.Blackout.Visible = false
	
	ActiveFrame.Content.Right.TradeState.Visible = false
	ActiveFrame.Content.Right.Cooldown.Visible = false
	ActiveFrame.Content.Right.Blackout.Visible = false
	
	ActiveFrame.Content.Center.Buttons.Accept.Content.Amount.Text = "Accept"
	
	local id, u = TradingClient:GetLocalUser()
	local oid, ou = TradingClient:GetOtherUser()
	
	local pu = Players:GetPlayerByUserId(u.UserId)
	local pou = Players:GetPlayerByUserId(ou.UserId)
	
	if not pu or not pou then return end
	
	ActiveFrame.Content.Left.Player.Username.Display.Text = pu.DisplayName
	ActiveFrame.Content.Left.Player.Username.User.Text = ("@%s"):format(pu.Name)
	ActiveFrame.Content.Left.Player.Avatar.Icon.Image = TradingClient:GetAvatar(u.UserId)
	
	ActiveFrame.Content.Right.Player.Username.Display.Text = pou.DisplayName
	ActiveFrame.Content.Right.Player.Username.User.Text = ("@%s"):format(pou.Name)
	ActiveFrame.Content.Right.Player.Avatar.Icon.Image = TradingClient:GetAvatar(ou.UserId)
	
	ActiveFrame.Visible = true
	TradingContext.RequestsContainer.Visible = false
	
	Roblox:ClearChildrenOfClass(TradingContext.RequestsContainer, "CanvasGroup")
	
	-- make ActiveTradeFrame visible
	-- make StatsFrame invisible
end)

Network:Bind("SendTradeMessage", function(...)
	return TradingClient:SendMessage(...)
end)

AnimationService:CreateButton(TradeTab.Disable, function()
	Network:Post("DisableTrade")
end)

function TradingClient:UpdateDisabledState()
	local PlayerData = Network:Fetch("GetClientData")
	local TradeDisabled = PlayerData.TradeDisabled
	
	local Color = not TradeDisabled and Color3.fromRGB(255, 61, 64) or Color3.fromRGB(115, 255, 39)
	local Text = TradeDisabled and "Enable" or "Disable"
	
	TradeTab.Disable.Content.BackgroundColor3 = Color
	TradeTab.Disable.Content.Amount.Text = Text
end

return TradingClient