function GetBlend(Colors, Offset)
	local Blend = (Offset * (#Colors - 1)) * 2
	local Index = math.floor(Blend) % #Colors + 1
	local NextIndex = (Index % #Colors) + 1
	local Alpha = Blend % 1

	return Colors[Index]:Lerp(Colors[NextIndex], Alpha)
end

return {
	Godly = function(Offset)
		local Colors = {
			Color3.fromRGB(255, 52, 52),
			Color3.fromRGB(255, 67, 174)
		}

		return GetBlend(Colors, Offset)
	end,
	
	Developer = function(Offset)
		local Colors = {
			Color3.fromRGB(215, 50, 255),
			Color3.fromRGB(140, 35, 255)
		}

		return GetBlend(Colors, Offset)
	end,
}