local Debris = game:GetService("Debris")

local Images = {}

for _, Image in script:GetChildren() do
	local imgData = require(Image)
	
	for a, id in imgData do
		local imgLabel = Instance.new("ImageLabel")
		imgLabel.Parent = script
		imgLabel.Image = id
		
		Debris:AddItem(imgLabel, .1)
		
		Images[a] = id
	end
end

return function(Image)
	return Images[Image] or Images["null"]
end