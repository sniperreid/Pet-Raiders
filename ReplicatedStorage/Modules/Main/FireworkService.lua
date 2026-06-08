local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local Roblox = Services.get("Roblox")
local SoundService = Services.get("SoundService")

local Firework = {}
Firework.__index = Firework

function Firework:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

function Firework.Pattern()
	return {
		Size = math.random(1, 3),
		Color = Color3.new(
			math.random(),
			math.random(),
			math.random()
		),
		EmitCount = math.random(5, 15)
	}
end

function Firework.newPlaceholder()
	return Roblox.Create "Part" {
		Size = Vector3.new(.1, .1, .1),
		Anchored = true,
		CanCollide = false
	}
end

function Firework:newFirework()
	local Particle = self.Particle:Clone()
	local Placeholder = self.newPlaceholder()
	
	Placeholder.CFrame = self.Origin or CFrame.new()
	
	Particle.Enabled = false
	Particle.Parent = Placeholder
	Particle.LockedToPart = true
	
	return {
		Particle = Particle,
		Pattern = self.Pattern(),
		Placeholder = Placeholder
	}
end

function Firework:Explode(Count)
	local Particles = {}
	
	for i = 1, Count do
		local NewFirework = self:newFirework()

		local Particle = NewFirework.Particle
		local Pattern = NewFirework.Pattern
		local Placeholder = NewFirework.Placeholder

		Placeholder.Parent = workspace
		Particle.Color = ColorSequence.new(Pattern.Color)
		-- Particle.Size = NumberSequence.new(Pattern.Size)
		
		Particle.Enabled = true
		
		task.delay(math.random(1, 2), function()
			SoundService:PlaySound("Firework", {
				Volume = 2,
				Parent = Placeholder
			})
		end)
		
		task.delay(math.ceil(Particle.Lifetime.Max / Pattern.EmitCount), function()
			Particle.Enabled = false
			
			Debris:AddItem(Placeholder, 5)
		end)
		
		Particles[i] = NewFirework
	end
	
	return Particles
end

function Firework:Launch()
	-- no need for this function right now ..
end

function Firework.new(Origin)
	return setmetatable({
		Particle = script.Particle,
		Origin = Origin
	}, Firework)
end

return Firework