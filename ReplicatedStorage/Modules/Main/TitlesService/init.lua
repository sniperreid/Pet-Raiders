local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local DataService = Services.get("DataService")
local States = Services.get("States")

local TitlesService = {}
TitlesService.Titles = require(script.Titles)
TitlesService.Requirements = require(script.Requirements)
TitlesService.Gradients = require(script.Gradients)

local ComputeNameColor = require(script.ComputeNameColor)

function TitlesService:TitleExists(Title)
	for _, _Title in self.Titles do
		if _Title.Title == Title then
			return _Title
		end
	end
end

function TitlesService:EquipTitle(Player, Title)
	if typeof(Player) ~= "Instance" then
		return
	end
	
	if typeof(Title) ~= "string" then
		return
	end
	
	local PlayerData = DataService:GetPlayerData(Player)

	local PlayerTitles = PlayerData.Titles
	
	if not self:TitleExists(Title) then
		return
	end
	
	if not table.find(PlayerTitles, Title) then
		return
	end
	
	PlayerData.Title = Title
	DataService:SendUpdateSignal(Player, "Title")
	
	return Title
end

function TitlesService:AddTitle(Player, Title)
	local PlayerData = DataService:GetPlayerData(Player)

	if not self:TitleExists(Title) then
		return
	end
	
	table.insert(PlayerData.Titles, Title)
	DataService:SendUpdateSignal(Player, "Titles")
	
	return Title
end

function TitlesService:UpdateProgress(Player, Amount, Currency, ...)
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	for Title, Data in self.Requirements do
		if table.find(PlayerData.Titles, Title) then
			continue
		end
		
		local Currency = Data.Currency
		local Amount = Data.Amount

		if not Currency then
			continue
		end
		
		local uAmount = PlayerData[Currency] or 0
		
		if uAmount < Amount then
			continue
		end
		
		self:AddTitle(Player, Title)
	end
end

function TitlesService:UpdateOverhead(Player)
	local TextAnimationService = Services.get("TextAnimationService")
	
	local PlayerData = DataService:GetPlayerData(Player)
	
	if not PlayerData then
		return
	end
	
	local Title = PlayerData.Title
	
	States.add(Player, "Title", Title)
	
	local TitleData = self:TitleExists(Title)
	
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local PlayerTitle = Character:FindFirstChild("PlayerTitle")
	
	if not PlayerTitle then
		return
	end
	
	local _PlayerTitle = PlayerTitle.PlayerTitle
	
	_PlayerTitle.Text = Title
	
	if TitleData.Color then
		TextAnimationService:RequestCleanup(_PlayerTitle)
		_PlayerTitle.TextColor3 = TitleData.Color
	else
		TextAnimationService:AnimateText(_PlayerTitle, Title)
	end
end

if RunService:IsServer() then
	Network:Bind("EquipTitle", function(...)
		return TitlesService:EquipTitle(...)
	end)
end

if RunService:IsClient() then
	local ChatWindowConfiguration = TextChatService.ChatWindowConfiguration
	
	TextChatService.OnChatWindowAdded = function(message: TextChatMessage)
		local TextAnimationService = Services.get("TextAnimationService")
		
		local Properties = ChatWindowConfiguration:DeriveNewMessageProperties()

		local TextSource = message.TextSource
		
		if not TextSource then
			return Properties
		end
		
		local Title = States.has(TextSource.UserId, "Title")
		local TitleData = TitlesService:TitleExists(Title)
		
		if not TitleData.ChatTag then
			return
		end
		
		local UIGradient = Instance.new("UIGradient")
		
		if TitleData.Color then
			UIGradient.Color = ColorSequence.new(TitleData.Color)
		else
			local Sequence = {}

			for i = 0, 15 do
				table.insert(Sequence, ColorSequenceKeypoint.new(
					i / 15,
					TextAnimationService.Special[Title](
						(tick() + (i / 4)) / 2
					)
				))
			end
			
			UIGradient.Color = ColorSequence.new(Sequence)
			table.clear(Sequence)
		end
		
		local PlayerColor = ComputeNameColor(TextSource.Name)

		Properties.PrefixText = ("[%s]"):format(Title)
		Properties.Text = string.format(
			"<font color='rgb(%d, %d, %d)'>%s</font> %s",
			math.floor(PlayerColor.R * 255),
			math.floor(PlayerColor.G * 255),
			math.floor(PlayerColor.B * 255),
			message.PrefixText,
			message.Text
		)
		Properties.PrefixTextProperties = ChatWindowConfiguration:DeriveNewMessageProperties()
		UIGradient.Parent = Properties.PrefixTextProperties
		
		warn(Properties)

		return Properties
	end
end

return TitlesService