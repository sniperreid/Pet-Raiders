local Players = game:GetService("Players")

export type PartyMeta = {
	Dead: {[number]: Player} | {};
	Party: {[number]: Player} | {};
	DamageDealt: {[Player]: number} | {}
}

export type PartyClass = {
	__index: PartyClass;
	Destroy: (PartyClass) -> ();
	PlayerInParty: (PartyClass, Player) -> (number | nil);
	DeadInParty: (PartyClass, Player) -> (number | nil);
	Exit: (PartyClass, Player) -> ();
	Join: (PartyClass, Player) -> ();
	new: () -> (any)
}

local Party = {}
Party.__index = Party

function Party:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

function Party:PlayerInParty(Player)
	return table.find(self.Party, Player)
end

function Party:DeadInParty(Player)
	return table.find(self.Dead, Player)
end

function Party:Exit(Player)
	local idx = self:PlayerInParty(Player)
	if not idx then return end
	table.remove(self.Party, idx)
end

function Party:Join(Player)
	if self:PlayerInParty(Player) then return end
	table.insert(self.Party, Player)
end

function Party.new()
	local self = setmetatable({
		Party = {},
		Dead = {},
		DamageDealt = {}
	} :: PartyMeta, Party)
	
	return self
end

return Party :: PartyClass