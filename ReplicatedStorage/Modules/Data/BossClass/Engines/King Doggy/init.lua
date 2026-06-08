local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local Assets = ReplicatedStorage.Assets

local Services = require(Modules.Services)

local Network = Services.get "Network"

local Types = require(script.Parent.Parent.Types)

local Boss = {}
Boss.__index = Boss

function Boss:Destroy()
	
	if self.CleanCache then
		self:CleanCache()
	end
	
	table.clear(self)
	setmetatable(self, nil)
end

function Boss.new(owner)
	local SELF = setmetatable({
		owner = owner
	}, Boss)
	
	for i, v in script:GetChildren() do
		if v:IsA("ModuleScript") then
			SELF[v.name] = require(v)
		end
	end
	
	return SELF
end

function Boss:CleanCache(cache)
	if not cache then
		return
	end
	
	if typeof(cache) ~= "table" then
		return
	end
	
	for i, v in cache do
		if typeof(v) ~= "Instance" then
			continue
		end
		
		v:Destroy()
		
		cache[v] = nil
	end
	
	table.clear(cache)
end

function Boss:Transform()
	
	local somgd = self.owner.model:GetDescendants()
	local color = self.owner.boss_data.transform_color
	
	for _, a in somgd do
		if a:IsA("BasePart") then
			a.Color = color
			
			if a:IsA("MeshPart") then
				a.TextureID = ""
			end
		elseif a:IsA("SpecialMesh") then
			a.TextureId = ""
		elseif a:IsA("ParticleEmitter") then
			local newKeypoints = {}

			for i, keypoint in a.Color.Keypoints do
				newKeypoints[i] = ColorSequenceKeypoint.new(
					keypoint.Time,
					color
				)
			end

			a.Color = ColorSequence.new(newKeypoints)
		elseif a:IsA("Decal") then
			a.Color3 = color
		end
	end
end

function Boss:Sequence()
	return pcall(function()
		for i = 1, 4 do
			self.owner:Wander()

			self["Slam"](self)
			
			self.owner:Wander()

			self["Lightning"](self)
		end

		self.owner:PhaseChange()
	end)
end

function Boss:Init()
	self.owner:Spawn()
	
	task.spawn(function()
		while true do
			local success, err = self:Sequence()

			if success then
				continue
			end

			if not self.Destroy then
				continue
			end
            
			self:Destroy()

			break
		end
	end)
end

return Boss