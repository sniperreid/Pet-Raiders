local function toMinutes(...)
	return 60 * (...)
end

local function toHour(...)
	return 60 * toMinutes(...)
end

local Gifts = {}

-- 1 --

local num = 1

Gifts[num] = {}
Gifts[num].TimeRequired = toMinutes(5)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 50,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 1 --

-- 2 --

num = 2

Gifts[num] = {}
Gifts[num].TimeRequired = toMinutes(15)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 120,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 2 --

-- 3 --

num = 3

Gifts[num] = {}
Gifts[num].TimeRequired = toMinutes(30)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 20
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 275,
	Chance = 70
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 3 --

-- 4 --

num = 4

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(1)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 45
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 1_250,
	Chance = 45
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 4 --

-- 5 --

num = 5

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(1.25)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 5 --

-- 6 --

num = 6

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(1.5)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 6 --

-- 7 --

num = 7

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(1.75)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 7 --

-- 8 --

num = 8

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(2)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 8 --

-- 9 --

num = 9

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(2.25)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 9 --

-- 10 --

num = 10

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(2.5)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 10 --

-- 11 --

num = 11

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(2.75)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 11 --

-- 12 --

num = 12

Gifts[num] = {}
Gifts[num].TimeRequired = toHour(3)
Gifts[num].Rewards = {}
table.insert(Gifts[num].Rewards, {
	Type = "Pet",
	Name = "Bear",
	Amount = 1,
	Tier = "Normal",
	Chance = 25
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Gems",
	Amount = 2_000,
	Chance = 65
})
table.insert(Gifts[num].Rewards, {
	Type = "Currency",
	Name = "Tickets",
	Amount = 1,
	Chance = 10
})

-- 12 --

return Gifts