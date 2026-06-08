local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Services = require(Modules:WaitForChild("Services"))

local CurrencyModule = Services.get("CurrencyModule")
local TextAnimationService = Services.get("TextAnimationService")
local ImageModule = Services.get("ImageModule")
local math = Services.get("MathUtility")
local Short = Services.get("Short")
local Network = Services.get("Network")
local SoundService = Services.get("SoundService")

local RunService = Services.get("RunService")
local EasyRender = Services.get("RenderUtil").Number

local GuiService
local Interface
local Frames
local StatsFrame

local StatCache = {}

local module = {}

module.UpdateSpeed = 0.5

function module:GetFrame(...)
	return StatsFrame.Stats:FindFirstChild(...)
end

function module:get_cache(Stat)
	local getCache = StatCache[Stat]

	if not getCache then
		StatCache[Stat] = {}

		getCache = StatCache[Stat]
	end

	return getCache
end

function module:get_recent(Stat)
	return self:get_cache(Stat).Amount
end

function module:RenderText(Stat, x)
	x = math.floor(x)

	local Frame = self:GetFrame(Stat)
	local Content = Frame.Content

	local Amount = Content.Amount

	local getCache = self:get_cache(Stat)

	getCache["Amount"] = x

	Amount.Text = Short:AddSuffix(x)
end

function module:GetUpdateTime(Stat)
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Amount = PlayerData[Stat] or 0

	local Recent = self:get_recent(Stat) or 0

	local Sub = math.abs(Amount - Recent)

	return math.clamp(
		math.log100(
			math.max(Sub, 1),
			4
		),
		0,
		1
	) / self.UpdateSpeed
end

function module:render(Stat)
	
	local PlayerData = Network:Fetch("GetClientData") or {}
	local Amount = PlayerData[Stat] or 0
	
	local getCache = self:get_cache(Stat)
	local Recent = self:get_recent(Stat)
	
	RunService:Disconnect(getCache["Render"])

	getCache["Render"] = nil
	getCache["Render"] = EasyRender.new(
		{
			Min = Recent,
			Max = Amount,
			UpdateSpeed = self:GetUpdateTime(Stat)
		},
		function(...)
			self:RenderText(Stat, ...)
		end
	)
end

function module:Update(Stat, adding_currency)
	local Frame = self:GetFrame(Stat)

	if not Frame then
		return
	end

	local PlayerData = Network:Fetch("GetClientData") or {}
	local Amount = PlayerData[Stat] or 0

	local getCache = self:get_cache(Stat)
	local Recent = self:get_recent(Stat)

	if Recent == Amount then
		return
	end
	
	if Amount > (Recent or 0) and adding_currency then
		Network:Fetch(
			"PlayEffectDisplayCurrency",
			Stat,
			adding_currency
		)
		
		SoundService:PlaySound("StatRise", {
			Volume = 1
		})
		
		return task.delay(1, function()
			self:render(Stat)
		end)
	end

	self:render(Stat)
end

function module:init()
	if not GuiService then
		return
	end

	for _, v in StatsFrame.Stats:GetChildren() do
		if not v:IsA("Frame") then
			continue
		end
		
		if not v:FindFirstChild("Content") then
			continue
		end

		local Currency = v.Name
		local CurrencyData = CurrencyModule[Currency]

		local Content = v.Content
		local Icon = Content.Icon
		local Amount = Content.Amount

		Icon.Image = ImageModule(Currency)
		Amount.Text = "???"
		
		Amount.TextColor3 = CurrencyData.Color
	end
end

return setmetatable(module, {
	__call = function(self, GS)
		GuiService = GS
		Interface = GS.Interface
		Frames = GS.Frames
		StatsFrame = Frames.StatsFrame
		
		self:init()
		
		return self
	end,
})