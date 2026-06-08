local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Services = require(Modules:WaitForChild("Services"))

local math = Services.get("MathUtility")
local RunService = Services.get("RunService")

local Number = {}
Number.__index = Number

function Number:Disconnect()
	self:Stop()

	table.clear(self)
end

function Number:ReplaceDecimals(x, DecimalCount)
	local n = 10 ^ DecimalCount
	
	return math.floor(x * n) / n
end

function Number.new(Settings, Callback)
	local self = setmetatable({
		_Callback = Callback,
		
		Min = Settings.Min or 0,
		Max = Settings.Max or 1,
		UpdateSpeed = Settings.UpdateSpeed or 1,
		
		_Render = nil
	}, Number)
	
	self:Start()
	
	return self
end

function Number:Start()
	if self._Render then
		return
	end
	
	self._Render = RunService:Render(self.UpdateSpeed, function(RunTime)
		local newNum = math.Lerp(
			self.Min,
			self.Max,
			RunTime
		)

		local m = self.Max

		if self.Max < self.Min then
			m = self.Min
		end

		self.Number = math.clamp(newNum, 0, m)

		coroutine.wrap(
			self._Callback
		)(
			self.Number
		)
		
		if not self.Number then
			return self.Stop and self:Stop()
		end
		
		if self.Number >= m then
			return self:Stop()
		end
	end)
end

function Number:Stop()
	if self._Render then
		self._Render:Disconnect()
		self._Render = nil
	end
end

return Number