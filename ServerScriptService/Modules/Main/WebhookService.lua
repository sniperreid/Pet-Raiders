local HttpService = game:GetService("HttpService")

local WebhookService = {}
WebhookService.__index = WebhookService

function WebhookService:Destroy()
	table.clear(self)
end

function WebhookService:Reset()
	self.URL = nil
	self.RequestData = {}
end

function WebhookService:GetTrustedProxy()
	return self.TrustedProxy or "https://webhook.lewisakura.moe/"
end

function WebhookService:SwapProxy()
	local URL = self.URL
	
	if not URL then
		return
	end
	
	local CurrentProxy = string.find(URL, "/api/webhooks")
	
	if not CurrentProxy then
		return
	end
	
	local Proxy = string.sub(URL, 1, CurrentProxy)
	local NewProxy = self:GetTrustedProxy()
	
	self.URL = URL:gsub(Proxy, NewProxy)
end

function WebhookService:Completed(requestType)
	if requestType == "Reset" then
		return self:Reset()
	end

	if requestType then
		return
	end

	self:Destroy()
end

function WebhookService:PreformPostAsync()
	local URL = self.URL
	local RequestData = self.RequestData
	local ContentType = self.ContentType

	return pcall(function()
		local encoded = HttpService:JSONEncode(RequestData)

		return HttpService:PostAsync(URL, encoded, ContentType)
	end)
end

function WebhookService:Post(requestType)
	local URL = self.URL
	local RequestData = self.RequestData
	local ContentType = self.ContentType
	
	local Success, ErrorMessage = self:PreformPostAsync()
	
	if Success then
		return self:Completed(requestType)
	end
	
	local MaxAttempts = self.MaxAttempts or 15
	local PostDelay = self.PostDelay or .5
	local Attempts = 0

	coroutine.wrap(function()
		repeat task.wait(PostDelay)
			Attempts += 1

			Success, ErrorMessage = self:PreformPostAsync()
		until Success or Attempts >= MaxAttempts

		if Success or Attempts >= MaxAttempts then
			self:Completed(requestType)
		end
		
		if Success then
			return
		end

		warn("Error posting webhook async ::", ErrorMessage)
	end)()
end

function WebhookService:Submit(...)
	local URL = self.URL
	local RequestData = self.RequestData
	local ApplicationType = self.ApplicationType
	
	assert(URL ~= nil, "invalid url")
	assert(RequestData ~= {}, "invalid webhook data")
	
	self:Post(...)
end

function WebhookService:ConstructFooter(Footer)
	local RequestData = self.RequestData
	local RequestType = RequestData["embeds"][1]["footer"]

	if not RequestType then
		RequestData["embeds"][1]["footer"] = {}
		RequestType = RequestData["embeds"][1]["footer"]
	end

	for Type, Footer in Footer do
		local Type = string.lower(Type)

		RequestType[Type] = Footer
	end
end

function WebhookService:ConstructFields(Fields)
	local RequestData = self.RequestData
	
	RequestData["embeds"][1]["fields"] = Fields
end

function WebhookService:ConstructWebhook(Data)
	for Type, Data in Data do
		local Type = string.lower(Type)

		local RequestData = self.RequestData
		local RequestType = RequestData["embeds"][1]

		if not RequestType then
			RequestData["embeds"][1][Type] = {}
			RequestType = RequestData["embeds"][1]
		end

		RequestType[Type] = Data
	end
end

function WebhookService:ConstructEmbed(Type, Data, Post)
	if not Data then
		return
	end
	
	local Type = string.lower(Type)

	local RequestData = self.RequestData
	
	if Post == "Ping" then
		RequestData[Type] = ("<@%s>"):format(Data)
		
		return
	end
	
	RequestData[Type] = Data
end

function WebhookService:AttachContentType(ContentType)
	if typeof(ContentType) ~= "string" then
		self.ContentType = ContentType
		
		return
	end

	self.ContentType = Enum.HttpContentType[ContentType]
end

function WebhookService:AttachURL(URL)
	if not string.match(URL, "api") then
		return
	end
	
	self.URL = URL
	self:SwapProxy()
end

function WebhookService.new()
	local self = setmetatable({}, WebhookService)
	
	self.MaxAttempts = 15
	self.PostDelay = .5
	self.RequestData = {}
	
	return self
end

return WebhookService