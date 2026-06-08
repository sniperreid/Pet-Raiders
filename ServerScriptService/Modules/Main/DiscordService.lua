local Players = game:GetService("Players")
local DiscordService = {}

local WebhookURL = "https://aaa-peach-two.vercel.app/api/webhooks/1384980252517859459/u22f9mvw6jfOU_SFNnfR-u3DvfxqNUZkOcwmDuAckD_TWGXYuap2aVALc39EZb6unFB6"
local WebhookURL2 = "https://webhook.lewisakura.moe/api/webhooks/1355534692899885196/kmQ7o_mw9zmpULCGy8iLnDKECp2LQye8iKf4Mq0pWZXNCZNpHwjjEAyyF-t2-mVwt9kv"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Images = Services.get("ImageModule")
local Tiers = Services.get("TiersModule")
local Short = Services.get("Short")
local WebhookService = Services.get("WebhookService")

local Images_ = { }

local CreateImage = function(ImageID)
	if Images_[ImageID] then
		return Images_[ImageID]
	end

	local Width = 420
	local Height = 128

	if string.find(ImageID, 'http://www.roblox.com/Thumbs/Asset.ashx?width=110&height=110&assetId=',1,true) then
		Images_[ImageID] = HttpService:JSONDecode(
			HttpService:GetAsync(
				(
					"https://thumbnails.roproxy.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"):format(string.sub(ImageID, 70))
			)
		).data[1].imageUrl:gsub(("%s/%s"):format(Width, Width),("%s/%s"):format(Height, Height))
	else
		Images_[ImageID] = HttpService:JSONDecode(
			HttpService:GetAsync(
				(
					"https://thumbnails.roproxy.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"):format(
					ImageID:split("/")[#ImageID:split("/")]:gsub("?id=","")
				)
			)
		).data[1].imageUrl:gsub(("%s/%s"):format(Width, Width),("%s/%s"):format(Height, Height))
	end

	return Images_[ImageID]
end

function headshotToURL(id)
	local icon_url = "https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=" .. id .. "&size=420x420&format=Png&isCircular=false"
	local response = HttpService:GetAsync(icon_url)
	local data = HttpService:JSONDecode(response)
	
	return data["data"][1]["imageUrl"]
end

function DiscordService:PlayerReportSent(
	Player,
	Target,
	Reason,
	Info,
	TargetReports
)
	local ImageURL = headshotToURL(Target.UserId)
	
	local Author = "New Report!"
	local AuthorIconURL = "https://media.discordapp.net/attachments/1211531523287941133/1356293803236917258/Untitled.png"

	local Title = ("%s was Reported!"):format(Target.Name)

	local FieldName1 = "Total Reports"
	local FieldValue1 = tostring(TargetReports)

	local Date_Time = DateTime.now():ToLocalTime()

	local Footer = string.format("Reported by %s • %02d/%02d/%04d %d:%02d %s",
		Player.Name,
		Date_Time.Month, Date_Time.Day, Date_Time.Year, 
		(Date_Time.Hour % 12 == 0) and 12 or (Date_Time.Hour % 12), 
		Date_Time.Minute, 
		(Date_Time.Hour >= 12) and "PM" or "AM"
	)
	
	local Webhook = WebhookService.new()

	Webhook:AttachURL(WebhookURL2)
	Webhook:AttachContentType("ApplicationJson")
	
	Webhook:ConstructEmbed("Content", "")
	Webhook:ConstructEmbed("Embeds", {{}})
	Webhook:ConstructWebhook(
		{
			Type = "markdown",
			Title = Title,
			Description = Info,

			Thumbnail = {
				url = ImageURL,
				height = 128,
				width = 128
			},

			Author = {
				name = Author,
				icon_url = AuthorIconURL
			},
		}
	)

	Webhook:ConstructFields(
		{
			{
				name = FieldName1,
				value = FieldValue1,
				inline = true
			}
		}
	)

	Webhook:ConstructFooter(
		{
			Text = Footer
		}
	)

	Webhook:Submit()
end

function DiscordService:GameReportSent(
	Player,
	Info
)
	local ImageURL = headshotToURL(Player.UserId)

	local Author = "New Report!"
	local AuthorIconURL = "https://media.discordapp.net/attachments/1211531523287941133/1356293803236917258/Untitled.png"

	local Title = ("%s has reported!"):format(Player.Name)

	local Date_Time = DateTime.now():ToLocalTime()

	local Footer = string.format("%02d/%02d/%04d %d:%02d %s",
		Date_Time.Month, Date_Time.Day, Date_Time.Year, 
		(Date_Time.Hour % 12 == 0) and 12 or (Date_Time.Hour % 12), 
		Date_Time.Minute, 
		(Date_Time.Hour >= 12) and "PM" or "AM"
	)

	local Webhook = WebhookService.new()

	Webhook:AttachURL(WebhookURL2)
	Webhook:AttachContentType("ApplicationJson")

	Webhook:ConstructEmbed("Content", "")
	Webhook:ConstructEmbed("Embeds", {{}})
	Webhook:ConstructWebhook(
		{
			Type = "markdown",
			Title = Title,
			Description = Info,

			Thumbnail = {
				url = ImageURL,
				height = 128,
				width = 128
			},

			Author = {
				name = Author,
				icon_url = AuthorIconURL
			},
		}
	)

	Webhook:ConstructFooter(
		{
			Text = Footer
		}
	)

	Webhook:Submit()
end

function DiscordService:SecretHatched(
	PlayerName,
	PetTier,
	PetRarity,
	PetName,
	PetChance,
	EggName,
	PetSerial,
	DataService
)

	if RunService:IsStudio() then
		-- return
	end

	local PetImage = Images(PetName)
	local ImageURL = CreateImage(PetImage)

	local PetColor = (function()
		if PetTier ~= "Normal" then
			return Tiers[PetTier].Color
		end

		local RarityColors = {
			["Legendary"] = Color3.fromRGB(0, 255, 255),
			["Exclusive"] = Color3.fromRGB(100, 0, 255),
			["Secret"] = Color3.fromRGB(255, 0, 100)
		}

		if PetChance <= 0.001 and PetRarity ~= "Secret" then
			return Color3.fromRGB(68, 255, 0)
		end

		return RarityColors[PetRarity] or Color3.fromRGB(255, 255, 255)
	end)

	if PetTier ~= "Normal" then
		PetChance /= 100
	end

	local PlayerData = DataService and DataService:GetPlayerData(Players:FindFirstChild(PlayerName)) or {Settings={}}

	local Author = ("New %s Pet hatched!"):format(PetRarity)
	local AuthorIconURL = "https://images-ext-1.discordapp.net/external/uUqH-a9hBbDEW3q0QksdfYgXRK4JVwQq7BBtuzPlrgI/https/em-content.zobj.net/thumbs/160/twitter/53/party-popper_1f389.png"

	local Title = ("%s %s"):format((PetTier ~= "Normal" and (" " .. PetTier) or ""), PetName)

	local FieldName1 = "Pet Chance"
	local FieldValue1 = ("1 in %s"):format(Short:AddCommas(math.round(100 / PetChance)))

	local FieldName2 = "Pet Egg"
	local FieldValue2 = EggName
	
	local FieldName3 = "Pet Exist"
	local FieldValue3 = PetSerial

	local Date_Time = DateTime.now():ToLocalTime()

	local Footer = string.format("Hatched by %s • %02d/%02d/%04d %d:%02d %s",
		PlayerName,
		Date_Time.Month, Date_Time.Day, Date_Time.Year, 
		(Date_Time.Hour % 12 == 0) and 12 or (Date_Time.Hour % 12), 
		Date_Time.Minute, 
		(Date_Time.Hour >= 12) and "PM" or "AM"
	)

	local Link = PlayerData.Settings["Disable Ping"] and {} or (PlayerData.LinkedUserID or {})

	local Webhook = WebhookService.new()

	Webhook:AttachURL(WebhookURL)
	Webhook:AttachContentType("ApplicationJson")

	local LinkString = ""

	for _, Link in Link do
		LinkString = ("%s <@%s>"):format(LinkString, Link)
	end

	Webhook:ConstructEmbed("Content", LinkString)
	Webhook:ConstructEmbed("Embeds", {{}})
	Webhook:ConstructWebhook(
		{
			type = "rich",
			title = Title,
			color = tonumber("0x" .. PetColor():ToHex()),

			thumbnail = {
				url = ImageURL,
				height = 128,
				width = 128
			},

			author = {
				name = Author,
				icon_url = AuthorIconURL
			},
		}
	)
	
	Webhook:ConstructFields(
		{
			{
				name = FieldName1,
				value = FieldValue1,
				inline = true
			},
			{
				name = FieldName2,
				value = FieldValue2,
				inline = true
			},
			{
				name = FieldName3,
				value = FieldValue3,
				inline = true
			},
		}
	)

	Webhook:ConstructFooter(
		{
			Text = Footer
		}
	)

	Webhook:Submit()
end

return DiscordService