--!strict

local function SanitizeData(data: { [string]: any }, maxLength: number): { [string]: any }
	local function sanitize(value: any): any
		local valueType = typeof(value)
		
		if valueType == "Instance" then
			return nil
			
		elseif valueType == "string" then
			return string.sub(value, 1, maxLength)
			
		elseif valueType == "table" then
			local newTable = {}
			
			for k, v in value do
				local result = sanitize(v)
				
				if result ~= nil then
					newTable[k] = result
				end
			end
			
			return newTable
		else
			return value
		end
	end
	
	return sanitize(data)
end

return SanitizeData