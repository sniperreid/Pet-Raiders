local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Custom_Pets = Assets:WaitForChild("Custom_Pets")

local PetColorService = { }

function CompareLocalColors(a, b, c)
	return c > math.abs(a - b)
end

function PetColorService:IdentifiedShade(Color)
	local ColorProperties = { r = true, g = true, b = true }
	
	local notShade = false
	
	for a in ColorProperties do
		for b in ColorProperties do
			if a == b then
				continue
			end
			
			local White = 255
			local R, G, B = Color[a] * White, Color[b] * White, 10
			
			if not CompareLocalColors(R, G, B) then
				notShade = true

				break
			end
		end
		
		if notShade then
			break
		end
	end
	
	return not notShade
end

function PetColorService:Invert(Color)
	
	Color = Color3.new(
		math.clamp(Color.r, 0, 1),
		math.clamp(Color.g, 0, 1),
		math.clamp(Color.b, 0, 1)
	)
	
	local H,S,V = Color:ToHSV()
	
	if not self:IdentifiedShade(Color) then
		return Color3.fromHSV((H + .5) % 1, S, V)
	end
	
	return Color3.fromHSV(0, 0, 1 - V)
end

function PetColorService:UpdatePart(Part)
	local Inverted = self:Invert(Part.Color)
	
	Part.Color = Inverted
end

function PetColorService:UpdateParticles(Particle, isShiny)
	local Keypoints, NewKeypoints = Particle.Color.Keypoints, { }
	
	for i, v in Keypoints do
		NewKeypoints[i] = isShiny and self:Invert(v.Value) or Color3.fromRGB(1, 255, 255)
	end
	
	Particle.Color = ColorSequence.new(unpack(NewKeypoints))
end

function PetColorService:OverwritePetModel(Pet, Tier)
	local PetName = Pet.Name
	local PetModel = Custom_Pets:FindFirstChild(Tier .. " " .. PetName)
	
	if not PetModel then
		return
	end
	
	Pet:Destroy()
	
	return PetModel:Clone()
end

function PetColorService:Update(Pet, Tier)
	local newWrap = script:FindFirstChild(Tier)
	
	if not newWrap then
		return
	end
	
	local PetModel = self:OverwritePetModel(Pet, Tier)
	
	if PetModel then
		return PetModel
	end
	
	coroutine.wrap(require(newWrap))(self, Pet)
end

return PetColorService