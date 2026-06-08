local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local Short = Services.get("Short")
local States = Services.get("States")
local Roblox = Services.get("Roblox")
local GiftsModule = Services.get("GiftsModule")
local TextAnimationService = Services.get("TextAnimationService")
local AnimationService = Services.get("AnimationService")

local Player = Players.LocalPlayer

local GuiService
local GuiUtil
local Interface
local GuiFrames
local GiftsFrame
local Content
local Grid
local StatsFrame
local Buttons
local GiftsButton

local Gifts = {}

function Gifts:Update()
	local PlayerData = Network:Fetch("GetClientData")
	
	if not PlayerData then return end
	
	local StartTime = States.has(Player, "LogTime")
	
	local Unclaimed = 0

	for Index, Gift in GiftsModule do
		local Needle = "Gift" .. Index
		
		local Template = Grid:FindFirstChild(Needle)
		
		if not Template then
			Template = GuiUtil:CreateGift(Grid)
			Template.Name = Needle
			
			TextAnimationService:AnimateImage(Template.Glow, "Legendary")
			
			AnimationService:CreateButton(Template, function()
				if PlayerData.Gifts[Needle] then
					return
				end
				
				Network:Post("ClaimGift", Index)
			end)
		end
		
		local Content = Template.Content
		local Glow = Template.Glow
		
		local _Time = Content.Time
		local _Claimed = Content.Claimed
		
		_Claimed.Visible = PlayerData.Gifts[Needle]
		
		if PlayerData.Gifts[Needle] then
			_Time.Text = "Claimed!"
			
			continue
		end

		local Elapsed = os.time() - StartTime
		local TimeRemaining = Gift.TimeRequired - Elapsed
		
		if TimeRemaining <= 0 then
			Unclaimed += 1
		end

		_Time.Text = TimeRemaining > 0 and ("%s"):format(Short:FormatBoost(TimeRemaining)) or "Ready!"
	end
	
	GiftsButton.Content.Notification.Visible = Unclaimed >= 1 and true or false
	GiftsButton.Content.Notification.TextLabel.Text = tostring(Unclaimed)
end

function Gifts:Initialize()
	task.spawn(function()
		while task.wait() do
			self:Update()
		end
	end)
end

return setmetatable(Gifts, {
	__call = function(self, GS)
		GuiService = GS
		GuiUtil = GS.GuiUtil
		Interface = GS.Interface
		GuiFrames = Interface.Frames
		GiftsFrame = GuiFrames.GiftsFrame
		Content = GiftsFrame.Content
		Grid = Content.Grid
		
		StatsFrame = GuiFrames.StatsFrame
		Buttons = StatsFrame.Buttons
		GiftsButton = Buttons.Gifts
		
		self:Initialize()
		
		return self
	end,
})