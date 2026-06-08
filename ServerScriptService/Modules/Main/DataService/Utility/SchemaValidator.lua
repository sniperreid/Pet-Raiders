--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules:WaitForChild("Services"))

local UnicodeLib = Services.get("UnicodeLib")

local function SchemaValidator(data: { [string]: any })
	for key, value in data do
		local valueType = typeof(value)
		
		if valueType == "string" and not UnicodeLib.valid_utf8(value) then
			error(`Invalid utf8 found in key '{key}'`)
		end
		
		assert(valueType ~= "Instance", `Invalid type 'Instance' found in key '{key}'`)
	end
end

return SchemaValidator