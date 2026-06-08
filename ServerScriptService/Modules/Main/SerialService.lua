local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local Network = Services.get("Network")
local PsuedoMeta = Services.get("PsuedoMeta")
local GlobalServices = Services.get("GlobalServices")

local Packets = {}
local Serials = {}

function Serials:AddToQueue(Data)
	if not self.Queue[Data] then
		self.Queue[Data] = 0
	end
	
	if not self.Exists[Data] then
		self.Exists[Data] = 0
	end
	
	self.Queue[Data] += 1
	self.Exists[Data] += 1
end

function Serials:Get()
	local DataStore = self.DataStore
	local DataKey = self.DataKey
	
	return DataStore:GetAsync(DataKey) or {}
end

function Serials:Fetch(v)
	local Exists = self.Exists
	
	return Exists[v]
end

function Serials:Set(i, v)
	self.Exists[i] = v
	
	if self.StoreType ~= "Dictionary" then
		return
	end
	
	self:Save()
end

function Serials:Update(PastData)
	local PastData = PastData or {}
	local _Data = {}
	local Queue = self.Queue
	local Exists = self.Exists
	
	if self.StoreType == "Dictionary" then
		for i, v in Exists do
			_Data[i] = v
		end
		
		for i, v in Queue do
			_Data[i] = v
		end
		
		self.Exists = _Data
		
		return _Data
	end

	for i, v in Queue do
		local pd = PastData[i] or 0

		_Data[i] = v + pd
	end

	for i, v in Exists do
		if not _Data[i] then
			_Data[i] = 0
		end

		if v <= _Data[i] then
			continue
		end

		_Data[i] = v
	end

	self.Exists = _Data

	return _Data
end

function Serials:Save()
	if RunService:IsStudio() then
		-- return
	end
	
	local PastQueue = table.clone(self.Queue)
	local PastExists = table.clone(self.Exists)
	
	local DataStore = self.DataStore
	local DataKey = self.DataKey
	
	local success, err = pcall(function()
		DataStore:UpdateAsync(DataKey, function(...)
			return self:Update(...)
		end)
	end)
	
	self.Queue = {}
	
	if success then
		return
	end
	
	for i, v in PastQueue do
		self.Queue[i] = v
	end
	
	for i, v in PastExists do
		self.Exists[i] = v
	end
end

function Serials:GetNetKey(net)
	local Packet = self.Packet
	
	return ("%s%s"):format(net, Packet)
end

function Serials:FireGlobal(...)
	local p = {...}
	local Packet = self.Packet
	
	local addS = self:GetNetKey("AddSerial")
	local setS = self:GetNetKey("SetSerial")
	
	local success, err = pcall(function()
		if self.StoreType == "Dictionary" then
			return GlobalServices:Fire(setS, unpack(p))
		end
		
		return GlobalServices:Fire(addS, unpack(p))
	end)
end

function Serials:SetupNetwork()
	local Packet = self.Packet
	
	local getS = self:GetNetKey("GetSerial")
	local addS = self:GetNetKey("AddSerial")
	local setS = self:GetNetKey("SetSerial")
	
	Network:Bind(getS, function(_, ...)
		return self:Fetch(...)
	end)
	
	GlobalServices:Bind(setS, function(Data)
		self:Set(unpack(Data.Data))
	end)
	
	GlobalServices:Bind(addS, function(Data)
		self:AddToQueue(Data.Data)
	end)
	
	coroutine.wrap(function()
		while task.wait(math.random(250, 300)) do
			self:Save()
		end
	end)()
end

function Serials.new(SerialPacket, DataKey, StoreType)
	if Packets[SerialPacket] then
		return Packets[SerialPacket]
	end
	
	local Key = DataKey or "0001"
	
	local newSerial = PsuedoMeta.set({
		StoreType = StoreType or "number",
		Packet = SerialPacket,
		DataStore = DataStoreService:GetDataStore(SerialPacket),
		DataKey = Key,
		Queue = {},
		Exists = {}
	}, Serials)
	
	newSerial:SetupNetwork()
	
	newSerial.Exists = newSerial:Get()
	Packets[SerialPacket] = newSerial
	
	return newSerial
end

game:BindToClose(coroutine.wrap(function()
	for i, Packet in Packets do
		Packet:Save()
	end
end))

return Serials