local RunService = game:GetService("RunService")
local is_server = RunService:IsServer()

local tag = is_server and "Server" or "Client"

return require(script[tag])