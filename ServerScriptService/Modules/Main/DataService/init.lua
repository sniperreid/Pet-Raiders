--[[

██████╗  █████╗ ████████╗ █████╗ ███████╗███████╗██████╗ ██╗   ██╗██╗ ██████╗███████╗
██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║██║██╔════╝██╔════╝
██║  ██║███████║   ██║   ███████║███████╗█████╗  ██████╔╝██║   ██║██║██║     █████╗  
██║  ██║██╔══██║   ██║   ██╔══██║╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██║     ██╔══╝  
██████╔╝██║  ██║   ██║   ██║  ██║███████║███████╗██║  ██║ ╚████╔╝ ██║╚██████╗███████╗
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝╚══════╝

VERSION: 1.0.2
AUTHOR: spideyvhs

Changes vs 1.0.1:
  - SetAsync holds the session lock for the entire session; only released by SavePlayerData on disconnect
  - GetAsync kicks the player after all load attempts fail (no more silent default-data overwrite)
  - SetAsync returns false (not silent true) when the lock has been lost
]]

--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = require(Modules.Services)
local Encryption = Services.get("Encryption")

local Utility = require(script.Utility)
local Cases = require(script.Cases)
local DefaultData = require(script.DefaultData)

local MAX_SAVE_ATTEMPTS: number = 15
local LOCK_TIMEOUT: number = 5 * 60
local AUTOSAVE_INTERVAL: number = 60
local MAX_STRING_LENGTH: number = 100_000

local IS_DEV_ENV: boolean = RunService:IsStudio()

local JobId: string = game.JobId
local DataKey = require(script.DataKey) :: string
local DataStore = DataStoreService:GetDataStore(DataKey) :: DataStore

export type DataTable = { [string]: any }

local cachedData: { [number]: DataTable } = {}
local lastSaveTime: { [number]: number } = {}

export type DataService = {
	DataKey: string,
	DefaultData: DataTable,
	Utility: DataTable,

	ShallowCopy: (self: DataService, Data: DataTable) -> DataTable,
	GetCache: (self: DataService, Player: Player) -> DataTable?,
	ClearCache: (self: DataService, Player: Player) -> nil,
	ValidateAndMerge: (self: DataService, Data: DataTable) -> DataTable,
	Sanitize: (self: DataService, Data: DataTable) -> DataTable,
	Encrypt: (self: DataService, Player: Player, Data: DataTable) -> string,
	Decrypt: (self: DataService, Player: Player, str: string) -> DataTable,

	GetAsync: (self: DataService, Player: Player) -> DataTable?,
	SetAsync: (self: DataService, Player: Player, ReleaseLock: boolean?) -> boolean,

	GetPlayerData: (self: DataService, Player: Player) -> DataTable?,
	SavePlayerData: (self: DataService, Player: Player) -> boolean,
	AutoSaveLoop: (self: DataService) -> nil,
}

local DataService = {} :: DataService

DataService.DataKey = DataKey
DataService.DefaultData = DefaultData
DataService.Utility = Utility

function DataService:ShallowCopy(Data: DataTable): DataTable
	return Utility.ShallowCopy(Data)
end

function DataService:GetCache(Player: Player): DataTable?
	return cachedData[Player.UserId]
end

function DataService:ClearCache(Player: Player): nil
	cachedData[Player.UserId] = nil
	lastSaveTime[Player.UserId] = nil

	return
end

function DataService:ValidateAndMerge(Data: DataTable): DataTable
	local clean = Utility.ShallowCopy(Data)
	local dd = Utility.ShallowCopy(self.DefaultData)

	for k, v in dd do
		if clean[k] == nil then
			clean[k] = v
		end
	end

	Utility.SchemaValidator(clean)

	return clean
end

function DataService:Sanitize(Data: DataTable): DataTable
	return Utility.SanitizeData(Data, MAX_STRING_LENGTH) :: DataTable
end

function DataService:Encrypt(Player: Player, Data: DataTable): string
	local json: string = HttpService:JSONEncode(Data)
	local encrypted: string = Encryption.EncryptForUser(Player.UserId, json)

	return Utility.Base64.Encode(encrypted)
end

function DataService:Decrypt(Player: Player, str: string): DataTable
	local success, result = pcall(function()
		local decoded = Utility.Base64.Decode(str)
		local decrypted = Encryption.DecryptForUser(Player.UserId, decoded)

		return HttpService:JSONDecode(decrypted)
	end)

	if not success then
		warn("[DataService] Decryption failed!", result)
	end

	return if success and typeof(result) == "table" then result else {}
end

-- // Core

function DataService:GetAsync(Player: Player): DataTable?
	local UserId = Player.UserId

	if cachedData[UserId] then
		return cachedData[UserId]
	end

	for attempt = 1, MAX_SAVE_ATTEMPTS do
		if not Player.Parent then
			-- Player left while we were loading; abort cleanly
			return nil
		end

		while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 do
			task.wait(1)
		end

		local success, result = pcall(function()
			return DataStore:UpdateAsync(tostring(UserId), function(Old: any)
				local Now = os.time()

				if not Old then
					Old = {}
				end

				if Old.SessionJobId and Old.SessionJobId ~= JobId then
					if Now - (Old.LockTime or 0) < LOCK_TIMEOUT then
						-- Another server holds the lock; back off
						return nil
					end
				end

				Old.SessionJobId = JobId
				Old.LockTime = Now

				return Old
			end)
		end)

		if success and result then
			local decrypted: DataTable

			if result.Data then
				decrypted = self:Decrypt(Player, result.Data)
			else
				decrypted = {}
			end

			local validated = self:ValidateAndMerge(decrypted)

			cachedData[UserId] = validated
			lastSaveTime[UserId] = os.time() + math.random(0, AUTOSAVE_INTERVAL)

			if IS_DEV_ENV then
				Utility.Log("GetAsyncSuccess", Player.Name)
			end

			return cachedData[UserId]
		end

		task.wait(0.2 * attempt)
	end

	-- IMPORTANT: do NOT hand the player DefaultData here.
	-- If we cached defaults, a subsequent autosave would overwrite the player's real save.
	-- ProfileService-style: refuse to load and kick the player so they can rejoin to a healthy server.
	Utility.Log("GetAsyncFallback", Player.Name)

	if Player.Parent then
		Player:Kick("Sorry — your data couldn't be loaded right now. Please rejoin in a moment.")
	end

	return nil
end

-- // Core Save Method

-- ReleaseLock: when true, the save also clears SessionJobId so the next server can pick the slot up.
-- Background autosaves MUST pass false (or omit) so the lock stays held for the whole session.
function DataService:SetAsync(Player: Player, ReleaseLock: boolean?): boolean
	local UserId = Player.UserId
	local PlayerData = self:GetCache(Player)

	if not PlayerData then
		return false
	end

	local sanitized: DataTable = self:Sanitize(PlayerData)
	local encoded: string = self:Encrypt(Player, sanitized)

	for attempt = 1, MAX_SAVE_ATTEMPTS do
		while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 do
			task.wait(1)
		end

		local lockLost = false
		local success, result = pcall(function()
			return DataStore:UpdateAsync(tostring(UserId), function(Old: any)
				Old = Old or {}

				if Old.SessionJobId and Old.SessionJobId ~= JobId then
					-- The lock was lost (e.g. takeover after timeout). Do not overwrite.
					lockLost = true
					return nil
				end

				return {
					Data = encoded,
					-- Hold the lock for the rest of the session unless we are explicitly releasing it.
					SessionJobId = if ReleaseLock then nil else JobId,
					LockTime = os.time(),
				}
			end)
		end)

		if success and not lockLost then
			if IS_DEV_ENV then
				Utility.Log("SetAsyncSuccess", Player.Name)
			end

			return true
		end

		if lockLost then
			Utility.Log("SetAsyncLockLost", Player.Name)
			return false
		end

		task.wait(0.2 * attempt)
	end

	Utility.Log("SetAsyncFailure", Player.Name)

	return false
end

-- // Public Entry Points

function DataService:GetPlayerData(Player: Player): DataTable?
	return self:GetCache(Player) or self:GetAsync(Player)
end

function DataService:SavePlayerData(Player: Player): boolean
	-- This entry point is called on disconnect / BindToClose, so release the lock.
	local success = self:SetAsync(Player, true)

	if success then
		lastSaveTime[Player.UserId] = os.time() + AUTOSAVE_INTERVAL
	end

	-- Clear the cache after the final save so nothing else can mutate it post-disconnect.
	self:ClearCache(Player)

	return success
end

-- // Background Saving

function DataService:AutoSaveLoop(): nil
	while true do
		for _, player in Players:GetPlayers() do
			local uid = player.UserId

			if cachedData[uid] and os.time() >= (lastSaveTime[uid] or 0) then
				-- Autosave: keep the session lock held.
				self:SetAsync(player, false)

				lastSaveTime[uid] = os.time() + AUTOSAVE_INTERVAL

				task.wait(0.5)
			end
		end

		task.wait(5)
	end

	return
end

-- // Bindings

task.spawn(function()
	DataService:AutoSaveLoop()
end)

-- // Test Harness

Cases(DataService)

return DataService
