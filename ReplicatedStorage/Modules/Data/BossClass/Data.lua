return {
	["King Doggy"] = {
		name = "King Doggy",
		world = "Spawn",
		max_health = 600,
		speed = 11,
		
		transform_color = Color3.fromRGB(255, 0, 0),
		
		rewards = {
			{
				Item = "King Doggy",
				Type = "Pet",
				Chance = 30
			},
			
			{
				Item = "Coins",
				Type = "Currency",
				Chance = 10,
				Amount = 500
			},
			
			{
				Item = "Lightning",
				Type = "Ability",
				Chance = .1
			},
		}
	}
}