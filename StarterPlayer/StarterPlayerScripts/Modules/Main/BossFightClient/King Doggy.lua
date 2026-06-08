local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local Assets = ReplicatedStorage.Assets
local Modules = ReplicatedStorage.Modules

local Services = require(Modules.Services)

local Network = Services.get "Network"
local MathUtility = Services.get "MathUtility"

local Animations = {}
Animations.__index = Animations

function Animations:Attack1(model: Model, phase: number)
	assert(model, ("Could not retrieve boss model for %s"):format(script.Name))

	local height = phase == 1 and 30 or 45

	local start: Vector3 = model:GetPivot().Position
	local finish: Vector3 = start
	local control: Vector3 = start + Vector3.new(0, height, 0)

	local bezier = MathUtility.StrictBezier(start, control, finish)

	local duration: number = phase == 1 and .6 or .5
	local start_time: number = tick()

	self.connection = RunService.Heartbeat:Connect(function()
		local elapsed: number = tick() - start_time
		local alpha: number = math.clamp(elapsed / duration, 0, 1)

		local position: Vector3 = bezier(alpha)
		local cf: CFrame = CFrame.new(position)

		model:PivotTo(cf)

		if alpha >= 1 then
			self.connection:Disconnect()
			self.connection = nil
		end
	end)
end

function Animations:Init()
	Network:Bind(script.Name .. "Attack1", function(...)
		return self:Attack1(...)
	end)
end

return setmetatable(Animations, {
	__call = function(self)
		self:Init()
		
		return self
	end,
})