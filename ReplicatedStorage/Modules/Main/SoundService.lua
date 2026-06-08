-------------------------- Framework --------------------------

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundServices = game:GetService("SoundService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Sounds = Assets.Sounds

-------------------------- Framework --------------------------

---------------------- Services ----------------------

local TweenService = Services.get("TweenV2")
local Network = Services.get("Network")

---------------------- Services ----------------------

local SoundService = {}

function SoundService:GetTrack(Sound)
	for _, Track in Sounds:GetDescendants() do
		if Track.Name == Sound and Track:IsA("Sound") then
			return Track
		end
	end
end

function SoundService:TweenSetting(Track, Time, Settings)
	if Time == 0 then
		return
	end
	
	return TweenService:Create(
		Track,
		TweenInfo.new(
			Time,
			Enum.EasingStyle.Sine
		),
		Settings
	):Play()
end

function SoundService:ApplySettings(Track: Sound, Settings)
	local isTable = typeof(Settings) == "table"
	
	local Vol = not isTable and Settings or Settings.Volume or Track.Volume
	local FadeTime = isTable and Settings.FadeTime or 0
	local PlaybackSpeed = isTable and Settings.PlaybackSpeed or 1
	local Looped = isTable and Settings.Looped or false
	
	Track.Volume = FadeTime == 0 and Vol or 0
	Track.Looped = Looped
	Track.PlaybackSpeed = PlaybackSpeed

	self:TweenSetting(Track, FadeTime, {
		Volume = Vol
	})
	
	Track.Parent = isTable and Settings.Parent or SoundServices
	Track:Play()
	
	if not Track.Looped then
		Track.Ended:Once(function()
			Track:Destroy()
		end)
	end
	
	return Track
end

function SoundService:PlaySound(Track, Settings)
	local Sound = self:GetTrack(Track)
	
	if not Sound then
		return
	end
	
	if Track == "Burn" and SoundServices:FindFirstChild(Track) then
		return
	end
	
	return self:ApplySettings(Sound:Clone(), Settings)
end

Network:Bind("PlaySound", function(...)
	return SoundService:PlaySound(...)
end)

return SoundService