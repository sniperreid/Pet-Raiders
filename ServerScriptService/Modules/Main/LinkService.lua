local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local DataService = Services.get "DataService"

local LinkService = {}

LinkService.GuildId = ""
LinkService.AuthKey = ""
LinkService.URL = ""

function LinkService:GetUserBody(Player)
	local UserID = Player.UserId
	local Url = self.URL:format(self.GuildId, UserID)

	local API = HttpService:RequestAsync({
		Url = Url,
		Method = "GET",
		Headers = {Authorization = self.AuthKey}
	})
	
	if not API.Success then
		return
	end

	local Body = API.Body

	if typeof(Body) ~= "string" then
		return
	end
	
	return HttpService:JSONDecode(Body)
end

function LinkService:AttachUserID(Player)
	local Body = self:GetUserBody(Player) or {}
	local IDs = Body.discordIDs or {}
	
	local PlayerData = DataService:GetPlayerData(Player)
	PlayerData.LinkedUserID = IDs
	
	DataService:SendUpdateSignal(Player, "LinkedUserID")
end

return LinkService
