local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local MusicFolder = Assets:WaitForChild("Music")

local MaidClass = Services.get("MaidClass")
local TweenV2 = Services.get("TweenV2")

local MusicService = {
	Maid = MaidClass.new(),
	CurrentCategory = nil,
	CurrentTrack = nil,
	TrackQueue = {}
}

function MusicService:Clear()
	self.Maid:Clean()
	
	self.TrackQueue = {}
	self.CurrentCategory = nil
	
	if self.CurrentTrack then
		TweenV2:Create(self.CurrentTrack, TweenInfo.new(0.25), {Volume = 0}):Play()

		task.wait(0.25)
		
		self.CurrentTrack:Stop()
		self.CurrentTrack:Destroy()
		self.CurrentTrack = nil
	end
end

function MusicService:ShuffleTracks(Category)
	local Tracks = {}
	
	for _, v in ipairs(Category:GetChildren()) do
		if not v:IsA("Sound") then
			continue
		end
		
		table.insert(Tracks, v)
	end

	for i = #Tracks, 2, -1 do
		local j = math.random(i)
		
		Tracks[i], Tracks[j] = Tracks[j], Tracks[i]
	end
	
	return Tracks
end

function MusicService:Play(CategoryName)
	self:Clear()

	local Category = MusicFolder:FindFirstChild(CategoryName)
	
	if Category and Category:IsA("Folder") then
		self.CurrentCategory = Category
		self.TrackQueue = self:ShuffleTracks(Category)

		return self:PlayNextTrack()
	end
	
	for _, v in MusicFolder:GetChildren() do
		local Track = v:FindFirstChild(CategoryName)
			
		if not Track or not Track:IsA("Sound") then
			continue
		end
			
		return self:PlayTrack(Track)
	end
end

function MusicService:PlayNextTrack()
	if #self.TrackQueue == 0 then
		self.TrackQueue = self:ShuffleTracks(self.CurrentCategory)
	end
	
	if #self.TrackQueue <= 0 then
		return
	end

	local NextTrack = table.remove(self.TrackQueue, 1)
		
	self:PlayTrack(NextTrack, false)
end

function MusicService:PlayTrack(Track, Loop)
	if self.CurrentTrack then
		TweenV2:Create(self.CurrentTrack, TweenInfo.new(0.25), {Volume = 0}):Play()
		
		task.wait(0.25)
		
		self.CurrentTrack:Stop()
		self.CurrentTrack:Destroy()
	end

	local _Track = Track:Clone()
	_Track.Parent = SoundService
	_Track.Looped = Loop
	_Track:Play()
	
	self.CurrentTrack = _Track

	if not Loop then
		self.Maid:GiveTask(_Track.Ended:Connect(function()
			self:PlayNextTrack()
		end))
	end
end

return MusicService