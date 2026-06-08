local Tasks = {}

local RNGService = {}
RNGService.__index = RNGService

function RNGService:GetLuckCalculator(Player)
	return 1
end

function RNGService:NewRarityCalculator(Player, ItemName)
	return self.Items[ItemName]
end

function RNGService.Clamp(v)
	return math.clamp((v or 0), 0, 100)
end

function RNGService:Wager(Chance)
	return (Random.new():NextInteger(1, Chance) == 1)
end

function RNGService:GetRandomItem(Player, ItemName)
	local ItemDict = self:NewRarityCalculator(Player, ItemName)
	
	local Weight = 0
	local NewDict = {}
	
	for i, v in ItemDict do
		local NewItem = v[1] or v.name
		local NewWeight = self.Clamp(v[2] or v.chance)

		Weight += NewWeight
		
		if NewDict[NewWeight] then
			table.insert(
				NewDict[NewWeight],
				NewItem
			)
		else
			NewDict[NewWeight] = {
				NewItem
			}
		end
	end
	
	local CurrentWeight = self.RNG:NextNumber(0, Weight)
	
	for i, v in ItemDict do
		local NewItem = v[1] or v.name
		local NewWeight = self.Clamp(v[2] or v.chance)

		Weight -= NewWeight
		
		if CurrentWeight < Weight then
			continue
		end
		
		local CurrentDict = NewDict[NewWeight]
		
		return CurrentDict[math.random(1, #CurrentDict)]
	end
end

function RNGService:Sort(Item)
	table.sort(Item, function(a, b)
		return (a[2] or a.chance) > (b[2] or b.chance)
	end)
end

function RNGService:AttachItem(ItemName, ItemDict)
	self:Sort(ItemDict)
	
	self.Items[ItemName] = ItemDict
end

function RNGService.new(Title)
	local self = Tasks[Title]
	
	if self then
		return self
	end
	
	self = setmetatable({
		Title = Title,
		Items = {},
		RNG = Random.new()
	}, RNGService)
	
	Tasks[Title] = self
	
	return self
end

return RNGService