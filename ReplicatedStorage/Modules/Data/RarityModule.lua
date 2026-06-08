local Special = {
	Legendary = function(Offset)
		return Color3.fromHSV(
			Offset % 1,
			0.5,
			0.9
		)
	end,

	Secret = function(Offset)
		return Color3.fromHSV(
			0.85 + math.sin(Offset * math.pi) / 10, 
			0.85, 
			1
		)
	end,
	
	Mutation = function(Offset)
		local Colors = {
			Color3.fromRGB(52, 167, 255),
			Color3.fromRGB(114, 224, 255),
			Color3.fromRGB(53, 245, 255)
		}

		local Blend = (Offset * (#Colors - 1)) * 2
		local Index = math.floor(Blend) % #Colors + 1
		local NextIndex = (Index % #Colors) + 1
		local Alpha = Blend % 1

		return Colors[Index]:Lerp(Colors[NextIndex], Alpha)
	end,
	
	Exclusive = function(Offset)
		local Colors = {
			Color3.fromRGB(85, 85, 255),
			Color3.fromRGB(170, 85, 255),
			Color3.fromRGB(85, 85, 255)
		}
		
		local Blend = (Offset * (#Colors - 1)) * 2
		local Index = math.floor(Blend) % #Colors + 1
		local NextIndex = (Index % #Colors) + 1
		local Alpha = Blend % 1

		return Colors[Index]:Lerp(Colors[NextIndex], Alpha)
	end,
}

return {
	Common = {
		Color = Color3.fromRGB(255, 255, 255),
		Exp = 100,
		Index = 1
	},
	
	Unique = {
		Color = Color3.fromRGB(255, 170, 110),
		Exp = 240,
		Index = 2
	},
	
	Rare = {
		Color = Color3.fromRGB(255, 75, 75),
		Exp = 380,
		Index = 3
	},
	
	Epic = {
		Color = Color3.fromRGB(160, 110, 255),
		Exp = 620,
		Index = 4
	},
	
	Legendary = {
		Special = Special.Legendary,
		Exp = 1200,
		Index = 5
	},
	
	Mutation = {
		Special = Special.Mutation,
		Exp = 2600,
		Index = 8
	},
	
	Exclusive = {
		Special = Special.Exclusive,
		Exp = 1600,
		Index = 6
	},
	
	Secret = {
		Special = Special.Secret,
		Exp = 2200,
		Index = 7
	}
}