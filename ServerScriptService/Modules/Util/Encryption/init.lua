--!strict

local HttpService = game:GetService("HttpService")

local SEED_MULTIPLIER: number = 7919
local SALT: string = "jJavSuhRmEYrna6GdYfmABVmHZt2tMyX"

local SHA256 = require(script.SHA256)

local function getKeyForUser(userId: number): string
	local seed = tostring(userId * SEED_MULTIPLIER)
	
	local digest = SHA256.sha256(seed .. SALT)
	
	return digest:sub(1, 32)
end

local function xor(str: string, key: string): string
	local result = {}

	for i = 1, #str do
		local c = string.byte(str, i)
		local k = string.byte(key, ((i - 1) % #key) + 1)
		
		table.insert(result, string.char(bit32.bxor(c, k)))
	end

	return table.concat(result)
end

local Encryption = {}

function Encryption.EncryptForUser(userId: number, text: string): string
	local key = getKeyForUser(userId)
	
	return xor(text, key)
end

function Encryption.DecryptForUser(userId: number, text: string): string
	local key = getKeyForUser(userId)
	
	return xor(text, key)
end

return Encryption