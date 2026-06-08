local Tiers = {}

for _, Tier in script:GetChildren() do
	Tiers[Tier.Name] = require(Tier)
end

return Tiers