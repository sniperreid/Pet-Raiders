local Colors = {
	Red = Color3.fromRGB(255, 0, 100),
	Orange = Color3.fromRGB(255, 85, 0),
	Yellow = Color3.fromRGB(255, 170, 0),
	Green = Color3.fromRGB(0, 255, 0),
	["Dark Green"] = Color3.fromRGB(0, 200, 0),
	Blue = Color3.fromRGB(0, 85, 255),
	White = Color3.fromRGB(255, 255, 255),
	["Light Gray"] = Color3.fromRGB(189, 189, 189),
	Gray = Color3.fromRGB(120, 120, 120),
	Black = Color3.fromRGB(31, 31, 31),
	Cyan = Color3.fromRGB(0, 255, 255),
	Pink = Color3.fromRGB(255, 85, 255),
	Purple = Color3.fromRGB(170, 0, 255),
	["Light Blue"] = Color3.fromRGB(0, 183, 255)
}

return function(Type, Request)
	local Color = typeof(Request) ~= "string" and Request or Colors[Request] or Colors["White"]
	
	local RichText = ("<font color=\"#%*\">%*</font>"):format(Color:ToHex(), Type)

	return not Color and Type or RichText
end