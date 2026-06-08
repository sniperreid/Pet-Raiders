local TaskModule = {
	["Desert"] = {
		[1] = {
			Description = "Break 25 Pickups",

			Type = "Pickups",
			Amount = 25,
			
			PickupsBroken = 0
		},

		[2] = {
			Description = "Defeat King Doggy",

			Type = "Boss",
			Amount = 1
		}
	},
	
	["Snow"] = {
		[1] = {
			Description = "Break 40 Pickups",

			Type = "Pickups",
			Amount = 40,

			PickupsBroken = 0
		},

		[2] = {
			Description = "Defeat ???",

			Type = "Boss",
			Amount = 1
		}
	},
	
	["Jungle"] = {
		[1] = {
			Description = "Defeat ???",

			Type = "Boss",
			Amount = 1
		}
	},
	
	["Ocean"] = {
		[1] = {
			Description = "Defeat ???",

			Type = "Boss",
			Amount = 1
		}
	},
	
	["Space"] = {
		[1] = {
			Description = "Defeat ???",

			Type = "Boss",
			Amount = 1
		}
	}
}

for a, b in TaskModule do
	for c, d in b do
		d.Area = a
	end
end

return TaskModule