return {
	["Eggs Hatched"] = 0,
	["Pickups Broken"] = 0,
	["Bosses Killed"] = 0,

	Level = 1,
	Exp = 0,

	Pets = {},
	Eggs = {},
	Items = {},

	Prizes = {},

	AbilitiesOwned = {"Lightning", "Fireball", "Volcano", "Meteor", "Heal", "Bubble", "Ice Aura", "Storm"},
	TradeHistory = {},
	TradeDisabled = false,

	Boosts = {},
	Codes = {},

	AutoDelete = {},

	Index = {},
	Badges = {},

	Gifts = {},

	Quests = {},

	IndexClaimed = {},

	Worlds = {"Overworld"},
	World = "Overworld",

	Areas = {"Spawn"},
	Area = "",
	AreasUnlockedOnJoin = {},

	BossesDefeated = {},

	Tasks = {
		[1] = {
			Description = "Break 25 Pickups",

			Type = "Pickups",
			Amount = 25,

			PickupsBroken = 0,

			Area = "Desert"
		},

		[2] = {
			Description = "Defeat King Doggy",

			Type = "Boss",
			Amount = 1,

			Area = "Desert"
		}
	},

	Abilities = {"Heal", "Storm", "Ice Aura"},

	Settings = {
		["All Pets"] = true,
		["Other Pets"] = true,
		["Music"] = true
	},

	Titles = {"Beginner"},
	Title = "Beginner",

	Passes = {},
	RobuxSpent = 0,
	Tokens = 0
}