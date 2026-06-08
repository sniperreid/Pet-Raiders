--!strict

local Base64 = {}

function Base64.Encode(data: string): string
	return (data:gsub(".", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

function Base64.Decode(data: string): string
	return (data:gsub("%%(%x%x)", function(hex)
		local num = tonumber(hex, 16)
		
		if num == nil then
			return ""
		end
		
		return string.char(num)
	end))
end

return Base64